import 'package:flutter/material.dart';
import 'package:fishbook/analyticsscreen.dart';
import 'package:fishbook/notificationsscreen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/login_screen.dart';
import 'crewmemberspage.dart';
import 'workmanagementpage.dart';
import 'profilescreen.dart';

class CrewmemberHomePage extends StatefulWidget {
  const CrewmemberHomePage({Key? key, required organizationId}) : super(key: key);

  @override
  _CrewmemberHomePageState createState() => _CrewmemberHomePageState();
}

class _CrewmemberHomePageState extends State<CrewmemberHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(),
      drawer: buildDrawer(),
      bottomNavigationBar: buildBottomNavigationBar(),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildWorkContainer(),
            ],
          ),
          SizedBox(height: 20),
          buildPendingContainer("Pending Works"),
          buildPendingContainer("Pending Income"),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(
        'FishBook',
        style: TextStyle(
          color: Color(0xFFF20485A),
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Color(0xFFF9D8C5),
      centerTitle: true,
      elevation: 0.5,
      leading: GestureDetector(
        onTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: Container(
          margin: EdgeInsets.all(10),
          child: Icon(Icons.menu, color: Colors.black),
          height: 36,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFFF9D8C5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: [buildDashboardIcon(context), buildLogoutButton()],
    );
  }

  Drawer buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFF9D8C5),
            ),
            child: Text(
              'Dashboard',
              style: TextStyle(
                color: Color(0xFFF20485A),
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        ],
      ),
    );
  }

  GestureDetector buildDashboardIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
      },
      child: Container(
        margin: EdgeInsets.all(10),
        child: Icon(Icons.person, color: Colors.black),
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFFF9D8C5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        FirebaseAuth.instance.signOut().then((value) {
          print("Signed Out");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen(userType: '')),
          );
        });
      },
      child: Container(
        margin: EdgeInsets.all(10),
        child: Icon(Icons.logout, color: Colors.black),
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFFF9D8C5),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  BottomNavigationBar buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Color(0x862195F3),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: "Home",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wrap_text),
          label: "Statements",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notification_important_rounded),
          label: "Notifications",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "Analytics",
          backgroundColor: Color(0xFFF9D8C5),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Navigate to CrewmemberHomePage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrewmemberHomePage(organizationId: null,),
              ),
            );
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
            // Navigate to NotificationsScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(),
              ),
            );
            break;
          case 3:
            // Navigate to AnalyticsScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyticsPage(),
              ),
            );
            break;
        }
      },
    );
  }

  Widget buildWorkContainer() {
    return GestureDetector(
      onTap: () {
        // Navigate to WorkManagementPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkManagementPage(),
          ),
        );
      },
      child: Container(
        width: 150,
        height: 80,
        color: Colors.green,
        child: Center(
          child: Text(
            'Work',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildPendingContainer(String title) {
    return Container(
      height: 80,
      color: Colors.white,
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
