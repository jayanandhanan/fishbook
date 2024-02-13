// ignore_for_file: unused_field

import 'package:fishbook/assignaccesspage.dart';
import 'package:fishbook/boatmaintenanceamountpay.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishbook/login_screen.dart';
import 'owner_details.dart'; // Import the correct path
import 'crewmemberspage.dart'; // Import the correct path
import 'financepage.dart'; // Import the correct path
import 'workmanagementpage.dart'; // Import the correct path
import 'profilescreen.dart'; // Import the correct path
import 'databasescreen.dart'; // Import the correct path
import 'fishingsailpayment.dart'; // Import the correct path
import 'newentryscreen.dart'; // Import the correct path
import 'idscreen.dart'; // Import the correct path
import 'myworkscreen.dart'; // Import the correct path
import 'myfishingsailscreen.dart'; // Import the correct path

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.organizationId}) : super(key: key);

  final String? organizationId;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _userName = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Add this line
  bool isHomeScreen = true;
  
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

 Future<void> _fetchUserData() async {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _userName = snapshot.data()?['name'] ?? '';
        });
      }
    });
  }
}


 @override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey, // Add this line
    appBar: PreferredSize(
  preferredSize: Size.fromHeight(100),
  child: AppBar(
    title: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _userName.isNotEmpty ? Text('Hello $_userName ') : Text('Hello There', style: TextStyle(fontSize: 24)), // Larger font size
          Text('Welcome back!!', style: TextStyle(fontSize: 12, color: Colors.black)), // Smaller font size
        ],
      ),
    ),
        backgroundColor: Colors.blue,
        centerTitle: false, // Set to false to align the text to the left
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(50),
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer(); // Use the scaffold key here
          },
          child: Icon(
            CupertinoIcons.text_justifyleft,
            color: Colors.black,
            size: 30, // Increase the size of the icon
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Adjust padding for spacing
              child: Icon(
                CupertinoIcons.profile_circled,
                color: Colors.black,
                size: 35, // Increase the size of the icon
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: buildDrawer(context),
      bottomNavigationBar: buildBottomNavigationBar(context, isHomeScreen), // Pass the boolean variable
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 40,
                  mainAxisSpacing: 30,
                  children: [
                    itemDashboard('Finance', Icons.account_balance_wallet, Colors.deepOrange, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FinancePage()));
                    }),
                    itemDashboard('Work', Icons.work, Colors.green, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => WorkManagementPage()));
                    }),
                    itemDashboard('Database', Icons.storage, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DatabaseScreen()));
                    }),
                    itemDashboard('Fishing Payment', Icons.attach_money, Colors.indigo, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FishingSailPayment()));
                    }),
                    itemDashboard('New Entry', Icons.add, Colors.orange, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NewEntryScreen()));
                    }),
                    itemDashboard('Organization IDs', Icons.credit_card, Colors.yellow, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => IDScreen()));
                    }),
                    itemDashboard('My Work', Icons.work, Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MyWorkScreen()));
                    }),
                    itemDashboard('My Fishing Payment', Icons.monetization_on, Colors.teal, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MyFishingSailScreen()));
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

 Drawer buildDrawer(BuildContext context) {
  return Drawer(
    child: StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        String userRole = snapshot.data!['role'];

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'User Details',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: Text('Owner details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerDetailsPage(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Crew Member details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrewMembersPage(),
                  ),
                );
              },
            ),
            if (userRole == 'Headowner') // Show if the role is 'Headowner'
              ListTile(
                title: Text('Writing Access'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to the assign access page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignAccessPage(),
                    ),
                  );
                },
              ),
                    if (userRole == 'Headowner') // Show if the role is 'Headowner'
              ListTile(
                title: Text('Boat Maintenanceamounts '),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to the assign access page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BoatMaintenanceAmountPage(),
                    ),
                  );
                },
              ), 
          ],
        );
      },
    ),
  );
}

  BottomNavigationBar buildBottomNavigationBar(BuildContext context, bool isHomeScreen) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.blue, // Set color based on the boolean variable
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
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
                  builder: (context) => HomeScreen(organizationId: widget.organizationId),
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
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            });
            break;
        }
      },
    );
  }

  Widget itemDashboard(String title, IconData iconData, Color background, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 5),
              color: Colors.grey.withOpacity(.2),
              spreadRadius: 2,
              blurRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
