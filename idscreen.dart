import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IDScreen extends StatefulWidget {
  @override
  _IDScreenState createState() => _IDScreenState();
}

class _IDScreenState extends State<IDScreen> {
  late String userId;
  String? organizationId;
  bool isHomeScreen=false;
  String? role ;

  @override
  void initState() {
    super.initState();
    _fetchOrganizationId();
    userId = FirebaseAuth.instance.currentUser!.uid;
    isHomeScreen = false;
  }

Future<String?> _fetchOrganizationId() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userSnapshot['organizationId'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization IDs'),
       backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context,false),
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
          // Fetch user's role
        String? role = userData['role'];

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

BottomNavigationBar buildBottomNavigationBar(BuildContext context, bool isHomeScreen) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.grey , 
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
        setState(() {
          switch (index) {
            case 0:
              // Navigate to HomeScreen only if it's not the current screen
              if (!isHomeScreen) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen(organizationId: organizationId)),
                );
              }
              break;
            case 1:
              // Navigate to StatementScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatementScreen()),
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
        });
      },
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
            if(role != 'Crewmember' )
            SizedBox(height: 10),
            _buildTextField(context, 'Co-Owner ID', orgData['coownerId']),
            if(role != 'Co-owner' )
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
