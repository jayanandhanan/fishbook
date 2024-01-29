import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishbook/crewmemberhomepage.dart';
import 'package:flutter/material.dart';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/signup_screen.dart';
import 'package:fishbook/forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  static String id = "login_screen";

  const LoginScreen({Key? key, required String userType}) : super(key: key);

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
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                // Display password input
                TextField(
                  textAlign: TextAlign.center,
                  obscureText: true,
                  onChanged: (value) {
                    password = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                  ),
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

                    try {
                      final userCredential = await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userCredential.user!.uid)
                          .get();

                      if (userDoc.exists) {
                        final organizationId = userDoc['organizationId'];
                        final role = userDoc['role'];

                        if (role == 'Crewmember') {
                          // Navigate to CrewmemberHomePage
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CrewmemberHomePage(organizationId: organizationId),
                            ),
                          );
                        } else {
                          // Navigate to HomeScreen (for Headowner and Co-owner)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(organizationId: organizationId),
                            ),
                          );
                        }
                      }

                      setState(() {
                        showSpinner = false;
                      });
                    } catch (e) {
                      print(e);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid email or password!'),
                          backgroundColor: Colors.red,
                        ),
                      );

                      setState(() {
                        showSpinner = false;
                      });
                    }
                  },
                ),
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
}
