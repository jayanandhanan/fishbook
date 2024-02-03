import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  static String id = "Profile_screen";

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  User? loggedInUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: _boatNameController,
                  decoration: InputDecoration(labelText: 'Boat Name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateProfile();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

 void _updateProfile() async {
  try {
    final userDoc = _firestore.collection('users').doc(loggedInUser?.uid);

    // Retrieve updated values for all fields
    final name = _nameController.text.isNotEmpty ? _nameController.text : _nameController.text;
    final phone = _phoneController.text.isNotEmpty ? _phoneController.text : _phoneController.text;
    final boatName = _boatNameController.text.isNotEmpty ? _boatNameController.text : _boatNameController.text;

    final userData = await userDoc.get();
    final existingData = userData.data() as Map<String, dynamic>?;

    // Preserve existing values if fields are empty
    final updatedData = {
      'name': name.isNotEmpty ? name : existingData?['name'],
      'phone': phone.isNotEmpty ? phone : existingData?['phone'],
      'boatname': boatName.isNotEmpty ? boatName : existingData?['boatname'],
    };

    // Update user profile
    await userDoc.update(updatedData);

    // Update subcollection fields
    await _updateSubcollectionFields(loggedInUser!.uid, updatedData);

    await _updateWorkManagementSubcollectionFields(loggedInUser!.uid, updatedData);
    await _updateSalaryToCrewMembersSubcollection(loggedInUser!.uid,  updatedData);
    await _updateOwnerShareSubcollection(loggedInUser!.uid, updatedData);
    await _updatePaymentDetailsSubcollectionFields(loggedInUser!.uid, updatedData);

    // Update the profile screen UI
    if (mounted) { // Check if the widget is still mounted
        setState(() {});
      }
    // Close the dialog
    Navigator.pop(context);
  } catch (e) {
    print('Error updating profile: $e');
    // Handle error
  }
}

Future<void> _updateSubcollectionFields(String userId, Map<String, dynamic> updatedData) async {
  try {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final organizationId = userDoc.data()?['organizationId'];
   

    final subcollections = ['headowners', 'co-owners', 'crewmembers', 'ownerdetails', 'crewmemberdetails'];

    for (String subcollection in subcollections) {
      final querySnapshot = await _firestore.collection('organizations').doc(organizationId).collection(subcollection).get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        // Update only if the document belongs to the current user
        if (doc.id == userId) {
          await doc.reference.update({'name': updatedData['name'], 'phone': updatedData['phone']});
        }
      }
    }
  
  } catch (e) {
    print('Error updating subcollection fields: $e');
  }
}

Future<void> _updateWorkManagementSubcollectionFields(String userId, Map<String, dynamic> updatedData) async {
  try {
    // Fetch user document
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final organizationId = userDoc.data()?['organizationId'];

    // Query documents in the 'workmanagement' subcollection under the organizationId
    final querySnapshot = await _firestore.collection('organizations').doc(organizationId).collection('workmanagement').get();

    // Iterate over each document in the query result
    for (DocumentSnapshot doc in querySnapshot.docs) {
      // Access 'inchargeid' using bracket notation
      final inchargeId = doc['inchargeid'];
      if (inchargeId == userId) {
        // Update the 'incharge' field of the document with the value from the 'updatedData' map
        await doc.reference.update({'incharge': updatedData['name']});
      }
    }
  } catch (e) {
    // Catch and handle errors
    print('Error updating workmanagement subcollection: $e');
  }
}

Future<void> _updatePaymentDetailsSubcollectionFields(String userId, Map<String, dynamic> updatedData) async {
  try {
    // Fetch user document
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final organizationId = userDoc.data()?['organizationId'];

    // Query documents in the 'paymentdetails' subcollection under the organizationId
    final querySnapshot = await _firestore.collection('organizations').doc(organizationId).collection('paymentdetails').get();

    // Iterate over each document in the query result
    for (DocumentSnapshot doc in querySnapshot.docs) {
      // Access 'inchargeid' using bracket notation
      final inchargeId = doc['inchargeid'];
      if (inchargeId == userId) {
        // Update the 'name' and 'phone' fields of the document with the values from the 'updatedData' map
        await doc.reference.update({
          'name': updatedData['name'],
          'phone': updatedData['phone']
        });
      }
    }
  } catch (e) {
    // Catch and handle errors
    print('Error updating paymentdetails subcollection: $e');
  }
}


Future<void> _updateSalaryToCrewMembersSubcollection(String userId, Map<String, dynamic> updatedData) async {
  try {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final organizationId = userDoc.data()?['organizationId'];
     final subcollections = ['salarytocrewmwmbers'];

for (String subcollection in subcollections) {
    final querySnapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry') // Assuming 'newentry' is a collection under the organization document
        .get();

    for (DocumentSnapshot entryDoc in querySnapshot.docs) {
        final entryDocId = entryDoc.id; // Get the ID of each document in the 'newentry' collection

        final subcollectionQuery = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('newentry')
            .doc(entryDocId)
            .collection(subcollection)
            .get();
    
for (DocumentSnapshot doc in subcollectionQuery.docs) {
             // Update only if the document belongs to the current user
        if (doc.id == userId) {
          await doc.reference.update({'name': updatedData['name'], 'phone': updatedData['phone']});
        }
      }
    }}
  } catch (e) {
    print('Error updating salarytocrewmembers subcollection: $e');
  }
}


Future<void> _updateOwnerShareSubcollection(String userId,  Map<String, dynamic> updatedData) async {
 try {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final organizationId = userDoc.data()?['organizationId'];
     final subcollections = ['ownershare'];

for (String subcollection in subcollections) {
    final querySnapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry') // Assuming 'newentry' is a collection under the organization document
        .get();

    for (DocumentSnapshot entryDoc in querySnapshot.docs) {
        final entryDocId = entryDoc.id; // Get the ID of each document in the 'newentry' collection

        final subcollectionQuery = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('newentry')
            .doc(entryDocId)
            .collection(subcollection)
            .get();
    
for (DocumentSnapshot doc in subcollectionQuery.docs) {
             // Update only if the document belongs to the current user
        if (doc.id == userId) {
          await doc.reference.update({'name': updatedData['name'], 'phone': updatedData['phone']});
        }
      }
    }}
  } catch (e) {
    print('Error updating ownershare subcollection: $e');
  }
}

  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _boatNameController = TextEditingController();

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _editProfile();
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _firestore.collection('users').doc(loggedInUser?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No data found.'));
          }

          final userData = snapshot.data!.data()!;
          final boatName = userData['boatname'] ?? '';
          final phone = userData['phone'] ?? '';
          final name = userData['name'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  child: Icon(
                    Icons.person,
                    size: 60,
                  ),
                ),  SizedBox(height: 8),
                Text(
                  'Name: $name',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Phone Number: $phone',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Email: ${loggedInUser?.email ?? 'N/A'}',
                  style: TextStyle(fontSize: 18),
                ),
               SizedBox(height: 16),
                Text(
                  'Boat Name: $boatName',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
