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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crew Member Details'),
      ),
      body: Column(
        children: [
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
          _buildCrewMemberTable(),
        ],
      ),
    );
  }

  Widget _buildCrewMemberTable() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
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
            child: DataTable(
              showCheckboxColumn: false,
              columns: _buildTableColumns(),
              rows: _buildTableRows(crewmemberDetails),
            ),
          );
        },
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Phone')),
      DataColumn(label: Text('Email')),
      DataColumn(label: Text('Actions')),
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
          DataCell(
            Text(crewmemberDetail['name'].toString()), // Display 'name' field
          ),
          DataCell(
            Text(crewmemberDetail['phone'].toString()), // Display 'phone' field
          ),
          DataCell(
            Text(crewmemberDetail['email'].toString()), // Display 'email' field
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    editCrewMemberDetail(crewmemberDetail);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteCrewMemberDetail(crewmemberDetail);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildAddOrUpdateCrewMemberDialog(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Crew Member' : 'Add crew Member'),
      content: Column(
        children: [
          TextField(
            controller: crewmemberNameController,
            decoration: InputDecoration(labelText: 'CrewMember Name'),
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
              content: Text('You do not have permission to add owners.'),
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
              content: Text('You do not have permission to add owners.'),
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
