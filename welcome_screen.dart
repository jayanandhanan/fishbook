import 'package:fishbook/login_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  static String id = "welcome_screen";

  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/img2.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome To Fishbook',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 48.0,
                ),
                
                GestureDetector(
                  onTap: () {
                    // Navigate to the LoginScreen for Owner
                    navigateToLoginScreen('Owner');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.blue,
                    child: const Text(
                      'Owner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12.0,
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to the LoginScreen for Crew Member
                    navigateToLoginScreen('Crew Member');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.green,
                    child: const Text(
                      'Crew Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  

  void navigateToLoginScreen(String userType) {
    // Navigate to the LoginScreen with the specified user type
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(userType: userType)),
    );
  }
}
