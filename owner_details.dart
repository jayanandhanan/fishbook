import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerDetailsPage extends StatefulWidget {
  @override
  _OwnerDetailsPageState createState() => _OwnerDetailsPageState();
}

class _OwnerDetailsPageState extends State<OwnerDetailsPage> {
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isEditing = false;
  String? editingOwnerDetailId;
  List<String> selectedRows = [];
  String? userRole; 


  @override
  void initState() {
    super.initState();
    _fetchUserRole(); // Fetch user role when the widget initializes
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (userRole == 'Headowner')
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildAddOrUpdateOwnerDialog(context);
                  },
                );
              },
              child: Text('Add Owner'),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildOwnerTable(),
            ),
          ],
        ),
      ),
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

        return DataTable(
          showCheckboxColumn: false,
          columns: _buildTableColumns(),
          columnSpacing: 16.0,
          rows: _buildTableRows(ownerDetails),
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
      if (userRole == 'Headowner')
      DataColumn(label: Text('Actions')),
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
          DataCell(
            Text(ownerDetail['name'].toString()),
          ),
          DataCell(
            Text(ownerDetail['phone'].toString()),
          ),
          DataCell(
            Text(ownerDetail['email'].toString()),
          ),
          DataCell(
            FutureBuilder<Widget>(
              future: _buildAddedByColumn(ownerDetail),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // or any other loading indicator
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
                    if (await _isEditingAllowed(ownerDetail.id)) {
                      editOwnerDetail(ownerDetail);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You cannot edit this owner.'),
                        ),
                      );
                    }
                  },
                ),
                if (userRole == 'Headowner')
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      if (await _isEditingAllowed(ownerDetail.id)) {
                        deleteOwnerDetail(ownerDetail);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You cannot delete this owner.'),
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

  Future<bool> _isEditingAllowed(String documentId) async {
    return !(await _isDocumentIdPresent(documentId));
  }

  Widget _buildAddOrUpdateOwnerDialog(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Owner' : 'Add Owner'),
      content: Column(
        children: [
          TextField(
            controller: ownerNameController,
            decoration: InputDecoration(labelText: 'Owner Name'),
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
              updateOwnerDetail(editingOwnerDetailId);
            } else {
              addOwnerDetail();
            }
            Navigator.of(context).pop();
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
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

      await ownerDetailsRef.add({
        'name': ownerNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
      });

      setState(() {
        ownerNameController.clear();
        phoneController.clear();
        emailController.clear();
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
      });

      setState(() {
        isEditing = false;
        editingOwnerDetailId = null;
        ownerNameController.clear();
        phoneController.clear();
        emailController.clear();
        selectedRows.clear();
      });
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
    final userRole = userSnapshot.data()?['role'];

    if (userRole == 'Headowner') {
      final organizationId = userSnapshot.data()?['organizationId'];
      final ownerDetailsRef =
          FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('ownerdetails');

      await ownerDetailsRef.doc(ownerDetail.id).delete();

      setState(() {
        selectedRows.remove(ownerDetail.id);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have permission to delete.'),
        ),
      );
    }
  }
}
