import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IDScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization IDs'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('User data not found'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String organizationId = userData['organizationId'];

          if (organizationId == null) {
            return Center(child: Text('Organization ID not found for the user'));
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('organizations').doc(organizationId).get(),
            builder: (context, orgSnapshot) {
              if (orgSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!orgSnapshot.hasData || orgSnapshot.data == null) {
                return Center(child: Text('Organization data not found'));
              }

              var orgData = orgSnapshot.data!.data() as Map<String, dynamic>;

              return displayOrganizationDetails(context, orgData);
            },
          );
        },
      ),
    );
  }

  Widget displayOrganizationDetails(BuildContext context, Map<String, dynamic> orgData) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildTextField(context, 'Organization ID', orgData['organizationId']),
            SizedBox(height: 10),
            _buildTextField(context, 'Co-Owner ID', orgData['coownerId']),
            SizedBox(height: 10),
            _buildTextField(context, 'Crew Member ID', orgData['crewmemberId']),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String? value) {
    return GestureDetector(
      onTap: () {
        _copyToClipboard(context, '$label: ${value ?? 'N/A'}');
      },
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Theme.of(context).primaryColor),
        ),
        child: Row(
          children: [
            Icon(Icons.copy, size: 18),
            SizedBox(width: 5),
            Text(
              '$label: ${value ?? 'N/A'}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied "$text" to clipboard'),
    ));
  }
}
