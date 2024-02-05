import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrewMembersPage extends StatefulWidget {
  @override
  CrewMembersPageState createState() => CrewMembersPageState();
}

class CrewMembersPageState extends State<CrewMembersPage> {
  final TextEditingController crewmemberNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isEditing = false;
  String? editingCrewMemberDetailId;
  List<String> selectedRows = [];
  String? userRole; 
    String? organizationId;
  String? currentUserId;
  bool isHomeScreen = false;


  @override
  void initState() {
    super.initState();
    _fetchUserRole(); // Fetch user role when the widget initializes
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      await fetchOrganizationId();
      
    }
  }

  Future<void> _fetchUserRole() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        userRole = userSnapshot['role']; // Assign the user role to the variable
      });
    }
  }

  Future<void> fetchOrganizationId() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    setState(() {
      organizationId = userDoc['organizationId'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crew Member Details'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context,isHomeScreen),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (userRole == 'Headowner')
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildAddOrUpdateCrewMemberDialog(context);
                  },
                );
              },
              child: Text('Add Crew Member'),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildCrewMemberTable(),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar buildBottomNavigationBar(BuildContext context, bool isHomeScreen) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.grey ,  // Set color based on the boolean variable
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.grey), 
          label: "Home",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wrap_text),
          label: "Statements",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.exit_to_app),
          label: "Logout",
          backgroundColor: Color(0xFFF9D8C5),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Navigate to HomeScreen only if it's not the current screen
            if (!isHomeScreen) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(organizationId: organizationId),
                ),
              );
            }
            break;
          case 1:
            // Navigate to StatementScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatementScreen(),
              ),
            );
            break;
          case 2:
            // Logout
            FirebaseAuth.instance.signOut().then((value) {
              print("Signed Out");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen(userType: '')),
              );
            });
            break;
        }
      },
    );
  }

Widget _buildCrewMemberTable() {
  return StreamBuilder<QuerySnapshot>(
    stream: _getCrewMemberDetailsStream(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('Error: ${snapshot.error}'),
        );
      }

      if (snapshot.connectionState != ConnectionState.active) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      List<DocumentSnapshot> crewmemberDetails = snapshot.data?.docs ?? [];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black), // Add black border around the table
          ),
          child: DataTable(
            showCheckboxColumn: false,
            columns: _buildTableColumns(),
            columnSpacing: 16.0,
            headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFFF9D8C5)), // Set header row color
            dividerThickness: 1.0, // Add separator lines between columns
            rows: _buildTableRows(crewmemberDetails),
          ),
        ),
      );
    },
  );
}

List<DataColumn> _buildTableColumns() {
  return [
    DataColumn(label: Text('Name')),
    DataColumn(label: Text('Phone')),
    DataColumn(label: Text('Email')),
    DataColumn(label: Text('Type')),
    if (userRole == 'Headowner') DataColumn(label: Text('Actions')),
  ];
}

List<DataRow> _buildTableRows(List<DocumentSnapshot> crewmemberDetails) {
  return crewmemberDetails.map((crewmemberDetail) {
    return DataRow(
      selected: selectedRows.contains(crewmemberDetail.id),
      onSelectChanged: (selected) {
        if (selected != null) {
          setState(() {
            if (selected) {
              selectedRows.add(crewmemberDetail.id);
            } else {
              selectedRows.remove(crewmemberDetail.id);
            }
          });
        }
      },
      cells: [
        DataCell(Text(crewmemberDetail['name'].toString())),
        DataCell(Text(crewmemberDetail['phone'].toString())),
        DataCell(Text(crewmemberDetail['email'].toString())),
        DataCell(
          FutureBuilder<Widget>(
            future: _buildAddedByColumn(crewmemberDetail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return snapshot.data!;
                }
              }
            },
          ),
        ),
        if (userRole == 'Headowner')
          DataCell(
            Row(
              children: [
                if (userRole == 'Headowner')
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      if (await _isEditingAllowed(crewmemberDetail.id)) {
                        editCrewMemberDetail(crewmemberDetail);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You cannot edit this crewmember.'),
                          ),
                        );
                      }
                    },
                  ),
                if (userRole == 'Headowner')
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      if (await _isEditingAllowed(crewmemberDetail.id)) {
                        deleteCrewMemberDetail(crewmemberDetail);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You cannot delete this crewmember.'),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }).toList();
}



    Future<Widget> _buildAddedByColumn(DocumentSnapshot crewmemberDetail) async {
    if (await _isDocumentIdPresent(crewmemberDetail.id)) {
      return Text('Signed in user');
    } else {
      return Text('Written');
    }
  }

 Future<bool> _isDocumentIdPresent(String documentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final organizationSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final organizationId = organizationSnapshot.data()?['organizationId'];

      final crewMemberRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('crewmembers');
     
      final crewMemberQuery = await crewMemberRef.get();
      

      final List<String> crewMemberIds =
          crewMemberQuery.docs.map((doc) => doc.id).toList();
     

      return crewMemberIds.contains(documentId) ;
    }
    return false;
  }
 Future<bool> _isEditingAllowed(String documentId) async {
    return !(await _isDocumentIdPresent(documentId));
  }

  Widget _buildAddOrUpdateCrewMemberDialog(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Crew Member' : 'Add Crew Member'),
      content: Column(
        children: [
          TextField(
            controller: crewmemberNameController,
            decoration: InputDecoration(labelText: 'Crew Member Name'),
          ),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (isEditing) {
              updateCrewMemberDetail(editingCrewMemberDetailId);
            } else {
              addCrewMemberDetail();
            }
            Navigator.of(context).pop();
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getCrewMemberDetailsStream() async* {
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];

    yield* FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('crewmemberdetails')
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    }
    throw Exception('User not found');
  }

  void addCrewMemberDetail() async {
    final userSnapshot = await _getCurrentUser();
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final crewmemberDetailsRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('crewmemberdetails');

      await crewmemberDetailsRef.add({
        'name': crewmemberNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
      });

      setState(() {
        crewmemberNameController.clear();
        phoneController.clear();
        emailController.clear();
      });
    } else {
      // If the user's role is not 'Headowner', display a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to add crewmembers.'),
        ),
      );
    }
  }

  void updateCrewMemberDetail(String? crewmemberDetailId) async {
    final userSnapshot = await _getCurrentUser();
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final crewmemberDetailsRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('crewmemberdetails');

      await crewmemberDetailsRef.doc(crewmemberDetailId).update({
        'name': crewmemberNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
      });

      setState(() {
        isEditing = false;
        editingCrewMemberDetailId = null;
        crewmemberNameController.clear();
        phoneController.clear();
        emailController.clear();
        selectedRows.clear();
      });
    } else {
      // If the user's role is not 'Headowner', display a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to add crewmembers.'),
        ),
      );
    }
  }

  void editCrewMemberDetail(DocumentSnapshot crewmemberDetail) {
    setState(() {
      isEditing = true;
      editingCrewMemberDetailId = crewmemberDetail.id;
      crewmemberNameController.text = crewmemberDetail['name'].toString();
      phoneController.text = crewmemberDetail['phone'].toString();
      emailController.text = crewmemberDetail['email'].toString();
      selectedRows.clear();
      selectedRows.add(crewmemberDetail.id);

      // Open the edit dialog directly upon clicking the "Edit" action
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildAddOrUpdateCrewMemberDialog(context);
        },
      );
    });
  }

  void deleteCrewMemberDetail(DocumentSnapshot crewmemberDetail) async {
    final userSnapshot = await _getCurrentUser();
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final crewmemberDetailsRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('crewmemberdetails');

      await crewmemberDetailsRef.doc(crewmemberDetail.id).delete();

      setState(() {
        selectedRows.remove(crewmemberDetail.id);
      });
    } else {
      // If the user's role is not 'Headowner', display a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to delete.'),
        ),
      );
    }
  }
}
