import 'package:flutter/material.dart';
import 'package:fishbook/login_screen.dart';

class SelectUserScreen extends StatefulWidget {
  const SelectUserScreen({Key? key}) : super(key: key);

  @override
  _SelectUserScreenState createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'),
      ),
      body: Stack(
        children: [
          
          Image.asset(
            'assets/img1.jpg', 
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the existing LoginScreen with a user type of "Owner"
                    navigateToLoginScreen('Owner');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Owner',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the existing LoginScreen with a user type of "Crew Member"
                    navigateToLoginScreen('Crew Member');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Crew Member',
                      style: TextStyle(fontSize: 18),
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
    // Navigate to the existing LoginScreen and pass the selected user type
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(userType: userType),
      ),
    );
  }
}
