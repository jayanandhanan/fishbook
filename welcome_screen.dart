import 'package:fishbook/selectuser_screen.dart';
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
                
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the SelectUserScreen when the button is pressed
                    navigateToSelectUserScreen();
                  },
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void navigateToSelectUserScreen() {
    // Navigate to the SelectUserScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectUserScreen()),
    );
  }
}
