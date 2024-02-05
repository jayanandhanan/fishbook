import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishbook/crewmemberhomepage.dart';
import 'package:flutter/material.dart';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  static String id = "login_screen";

  const LoginScreen({Key? key}) : super(key: key);

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
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: 50,
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
                  const SizedBox(height: 390), // Give space for the "Login Back" text
                  const Text(
                    'Login back..',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center, // Center the text
                  ),
                   const SizedBox(height: 05),
                  const Text(
                    'Yov\'ve been missed',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
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
                  const SizedBox(height: 10.0),
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
                      backgroundColor: Color(0xFF269493), // Set the button color
                      padding: EdgeInsets.symmetric(vertical: 12.0), // Set padding
                    ),
                    child: const Text('Log in', style: TextStyle(color: Colors.black, fontSize: 16)), // Reduce font size
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
                  const SizedBox(height: 12.0),
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
      ),
    );
  }
}
