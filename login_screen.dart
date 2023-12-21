import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fishbook/constants.dart';
import 'package:fishbook/signup_screen.dart';
import 'package:fishbook/forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  static String id = "login_screen";
  final String userType;

  const LoginScreen({Key? key, required this.userType}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool showSpinner = false;
  String email = '';
  String password = '';

  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/img5.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Login to Experience Fishbook',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Display email input
                TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    email = value;
                  },
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your email'),
                ),
                const SizedBox(height: 8.0),
                // Display password input
                TextField(
                  textAlign: TextAlign.center,
                  obscureText: true,
                  onChanged: (value) {
                    password = value;
                  },
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your password'),
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF269493), // Set the button color
                  ),
                  child: const Text('Log in', style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    setState(() {
                      showSpinner = true;
                    });

                    // Login to an existing account with email
                    try {
                      await _auth.signInWithEmailAndPassword(email: email, password: password);

                      setState(() {
                        showSpinner = false;
                      });

                      // Navigate to the ChatScreen after successful login
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );

                      // Show success dialog
                      _showDialog('Success', 'Successfully logged in!');
                    } catch (e) {
                      print(e);
                      setState(() {
                        showSpinner = false;
                      });

                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid email or password!'),
                          backgroundColor: Colors.red,
                        ),
                      );

                      // Show error dialog
                      _showDialog('Error', 'Invalid email or password. Please try again.');
                    }
                  },
                ),

                // Add Sign Up button inside a container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFF269493), // Box color
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: () {
                      // Navigate to the SignUpScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),

                // Add Forgot Password button
                TextButton(
                  onPressed: () {
                    // Navigate to the ResetPassword screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPassword()),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF269493)), // Set the link color
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
