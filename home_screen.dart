import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: ElevatedButton(
          child: Text("Logout"),
          onPressed: () {
            FirebaseAuth.instance.signOut().then((value) {
              print("Signed Out");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen(userType: '')),
              );
            });
          },
        ),
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
        onTap: () {},
        child: Container(
          margin: EdgeInsets.all(10),
          child: SvgPicture.asset(
            'assets/hamburger-menu.svg',
            color: Colors.black, 
          ),
          height: 28,
          width: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFFF9D8C5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: [dashboardIcon()],
    );
  }

  GestureDetector dashboardIcon() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.all(10),
        child: SvgPicture.asset('assets/user-profile.svg'),
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
}
