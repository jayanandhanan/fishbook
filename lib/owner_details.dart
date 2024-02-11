import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';


class OwnerDetailsPage extends StatefulWidget {
  @override
  _OwnerDetailsPageState createState() => _OwnerDetailsPageState();
}

class _OwnerDetailsPageState extends State<OwnerDetailsPage> {
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController investController = TextEditingController();

  bool isEditing = false;
  String? editingOwnerDetailId;
  List<String> selectedRows = [];
  String? userRole;
  String? organizationId;
  String? currentUserId;
  double totalInvest = 0.0; // Track total investment

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
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
        userRole = userSnapshot['role'];
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
        title: Text('Owner Details'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 5),
            if (userRole == 'Headowner')
              ElevatedButton(
  onPressed: () {
    setState(() {
      isEditing = false; // Set isEditing to false when adding a new owner
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAddOrUpdateOwnerDialog(context);
      },
    );
  },
  child: Text('Add Owner'),
),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildOwnerTable(),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.grey,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(organizationId: organizationId),
              ),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatementScreen(),
              ),
            );
            break;
          case 2:
            FirebaseAuth.instance.signOut().then((value) {
              print("Signed Out");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            });
            break;
        }
      },
    );
  }

  Widget _buildOwnerTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOwnerDetailsStream(),
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

        List<DocumentSnapshot> ownerDetails = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: DataTable(
              showCheckboxColumn: false,
              columns: _buildTableColumns(),
              columnSpacing: 16.0,
              dividerThickness: 1.0,
              headingRowColor: MaterialStateColor.resolveWith(
                (states) => const Color(0xFFF9D8C5),
              ),
              rows: _buildTableRows(ownerDetails),
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
      DataColumn(label: Text('Invest')),
      DataColumn(label: Text('Share')),
      DataColumn(label: Text('Type')),
      if (userRole == 'Headowner') DataColumn(label: Text('Actions')),
    ];
  }

  List<DataRow> _buildTableRows(List<DocumentSnapshot> ownerDetails) {
    return ownerDetails.map((ownerDetail) {
      return DataRow(
        selected: selectedRows.contains(ownerDetail.id),
        onSelectChanged: (selected) {
          if (selected != null) {
            setState(() {
              if (selected) {
                selectedRows.add(ownerDetail.id);
              } else {
                selectedRows.remove(ownerDetail.id);
              }
            });
          }
        },
        cells: [
          DataCell(Text(ownerDetail['name'].toString())),
          DataCell(Text(ownerDetail['phone'].toString())),
          DataCell(Text(ownerDetail['email'].toString())),
          DataCell(Text(ownerDetail['invest'].toString())),
          DataCell(Text(ownerDetail['share'].toString())),
          DataCell(
            FutureBuilder<Widget>(
              future: _buildAddedByColumn(ownerDetail),
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
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      editOwnerDetail(ownerDetail);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _showDeleteConfirmationDialog(ownerDetail);
                    },
                  ),
                ],
              ),
            ),
        ],
      );
    }).toList();
  }


Widget _buildAddOrUpdateOwnerDialog(BuildContext context) {
  return AlertDialog(
    title: Text(isEditing ? 'Edit Owner' : 'Add Owner'),
    content: Column(
      children: [
        TextField(
          controller: ownerNameController,
          decoration: InputDecoration(labelText: 'Owner Name'),
          enabled: !isEditing, // Disable editing if isEditing is true
        ),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(labelText: 'Phone'),
          enabled: !isEditing, // Disable editing if isEditing is true
          keyboardType: TextInputType.phone, // Set keyboard type to phone
        ),
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
          enabled: !isEditing, // Disable editing if isEditing is true
          keyboardType: TextInputType.emailAddress, // Set keyboard type to email address
        ),
        TextField(
          controller: investController,
          decoration: InputDecoration(labelText: 'Invest'),
          // Always allow editing for the invest field
          keyboardType: TextInputType.number, // Set keyboard type to number
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only digits
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
            updateOwnerDetail(editingOwnerDetailId);
          } else {
            if (_validateInputs()) {
              addOwnerDetail();
              Navigator.of(context).pop();
            }
          }
        },
        child: Text(isEditing ? 'Update' : 'Add'),
      ),
    ],
  );
}




// Function to validate investment amount
bool isValidInvest(String invest) {
  // Convert invest to a double and check if it's a valid number
  try {
    double investAmount = double.parse(invest);
    // You can add additional validation rules here, such as minimum investment amount
    return investAmount >= 0; // Example: Ensure invest is not negative
  } catch (e) {
    return false; // Parsing failed, not a valid investment amount
  }
}
  
bool _validateInputs() {
  if (ownerNameController.text.isEmpty ||
      phoneController.text.isEmpty ||
      emailController.text.isEmpty ||
      investController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please fill in all fields.'),
      ),
    );
    return false;
  }

  if (!isValidInvest(investController.text)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please enter a valid investment amount.'),
      ),
    );
    return false;
  }
  return true;
}




  void _showDeleteConfirmationDialog(DocumentSnapshot ownerDetail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this owner, it will remove them completely and the owners using the app won\'t be able to see their details. Are you really sure about deleting this?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteOwnerDetail(ownerDetail);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<Widget> _buildAddedByColumn(DocumentSnapshot ownerDetail) async {
    if (await _isDocumentIdPresent(ownerDetail.id)) {
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

      final headOwnersRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('headowners');
      final coOwnersRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('co-owners');

      final headOwnersQuery = await headOwnersRef.get();
      final coOwnersQuery = await coOwnersRef.get();

      final List<String> headOwnerIds =
          headOwnersQuery.docs.map((doc) => doc.id).toList();
      final List<String> coOwnerIds =
          coOwnersQuery.docs.map((doc) => doc.id).toList();

      return headOwnerIds.contains(documentId) || coOwnerIds.contains(documentId);
    }
    return false;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getOwnerDetailsStream() async* {
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];

    yield* FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('ownerdetails')
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    }
    throw Exception('User not found');
  }

  void addOwnerDetail() async {
    final userSnapshot = await _getCurrentUser();
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final ownerDetailsRef =
          FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('ownerdetails');

      double investValue = double.parse(investController.text);
      double totalInvest = await _calculateTotalInvest(ownerDetailsRef);
      double shareValue = _calculateShare(investValue, totalInvest);

      await ownerDetailsRef.add({
        'name': ownerNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'invest': investController.text,
        'share': shareValue.toStringAsFixed(2),
      });

      setState(() {
        ownerNameController.clear();
        phoneController.clear();
        emailController.clear();
        investController.clear();
        _calculateShareForOwners(ownerDetailsRef);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to add owners.'),
        ),
      );
    }
  }

  void updateOwnerDetail(String? ownerDetailId) async {
    final userSnapshot = await _getCurrentUser();
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final ownerDetailsRef =
          FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('ownerdetails');

      await ownerDetailsRef.doc(ownerDetailId).update({
        'name': ownerNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'invest': investController.text,
      });

      setState(() {
        isEditing = false;
        editingOwnerDetailId = null;
        ownerNameController.clear();
        phoneController.clear();
        emailController.clear();
        investController.clear();
        selectedRows.clear();
      });

      // Recalculate share and update Firestore for all owner details
      _calculateShareForOwners(ownerDetailsRef);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to add owners.'),
        ),
      );
    }
  }

  void editOwnerDetail(DocumentSnapshot ownerDetail) {
    setState(() {
      isEditing = true;
      editingOwnerDetailId = ownerDetail.id;
      ownerNameController.text = ownerDetail['name'].toString();
      phoneController.text = ownerDetail['phone'].toString();
      emailController.text = ownerDetail['email'].toString();
      investController.text = ownerDetail['invest'].toString();
      selectedRows.clear();
      selectedRows.add(ownerDetail.id);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildAddOrUpdateOwnerDialog(context);
        },
      );
    });
  }

 void deleteOwnerDetail(DocumentSnapshot ownerDetail) async {
  final userSnapshot = await _getCurrentUser();
  final String currentUserUid = userSnapshot.id; // Get current user ID

  final String ownerDetailUid = ownerDetail.id; // Get owner detail ID

  if (currentUserUid == ownerDetailUid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You cannot delete your own details.'),
      ),
    );
  } else {
    // Proceed with deletion
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final ownerDetailsRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('ownerdetails');

      await ownerDetailsRef.doc(ownerDetail.id).delete();

      setState(() {
        selectedRows.remove(ownerDetail.id);
      });

      // Recalculate share and update Firestore for all owner details
      _calculateShareForOwners(ownerDetailsRef);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to delete.'),
        ),
      );
    }
  }
}

  void _calculateShareForOwners(CollectionReference ownerDetailsRef) async {
    double totalInvest = await _calculateTotalInvest(ownerDetailsRef);
    QuerySnapshot querySnapshot = await ownerDetailsRef.get();
    List<DocumentSnapshot> ownerDetails = querySnapshot.docs;

    for (var ownerDetail in ownerDetails) {
      double ownerInvest = double.parse(ownerDetail['invest']);
      double share = _calculateShare(ownerInvest, totalInvest);

      await ownerDetail.reference.update({'share': share.toStringAsFixed(2)});
    }
  }

  double _calculateShare(double invest, double totalInvest) {
    return invest > 0 && totalInvest > 0 ? (invest / totalInvest) * 100 : 0;
  }

  Future<double> _calculateTotalInvest(CollectionReference ownerDetailsRef) async {
    double total = 0;
    QuerySnapshot querySnapshot = await ownerDetailsRef.get();
    List<DocumentSnapshot> ownerDetails = querySnapshot.docs;

    for (var ownerDetail in ownerDetails) {
      total += double.parse(ownerDetail['invest']);
    }

    return total;
  }
}
