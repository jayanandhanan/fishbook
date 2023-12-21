import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishbook/constants.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  static String id = "SignUp_screen";

  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool showSpinner = false;
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(
              height: 48.0,
            ),
            TextField(
              textAlign: TextAlign.center,
              onChanged: (value) {
                name = value;
              },
              decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your name'),
            ),
            const SizedBox(
              height: 8.0,
            ),
            TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                email = value;
              },
              decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your email'),
            ),
            const SizedBox(
              height: 8.0,
            ),
            TextField(
              textAlign: TextAlign.center,
              obscureText: true,
              onChanged: (value) {
                password = value;
              },
              decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your password'),
            ),
            const SizedBox(
              height: 8.0,
            ),
            TextField(
              textAlign: TextAlign.center,
              obscureText: true,
              onChanged: (value) {
                confirmPassword = value;
              },
              decoration: kTextFieldDecoration.copyWith(hintText: 'Confirm your password'),
            ),
            const SizedBox(
              height: 24.0,
            ),
            ElevatedButton(
              child: const Text('Create Account'),
              onPressed: () async {
                setState(() {
                  showSpinner = true;
                });

                // Validate password confirmation
                if (password != confirmPassword) {
                  // Passwords don't match, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() {
                    showSpinner = false;
                  });
                  return;
                }

                // Validate password length
                if (password.length < 6) {
                  // Password is too short, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password should be at least 6 characters long!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() {
                    showSpinner = false;
                  });
                  return;
                }

                // Create new Account
                try {
                  // Create the user
                  UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  // Save additional user details in Firestore
                  await _firestore.collection('users').doc(userCredential.user!.uid).set({
                    'name': name,
                    'email': email,
                  });

                  setState(() {
                    showSpinner = false;
                  });

                  Navigator.pop(context); // Navigate back to LoginScreen
                  print('Successfully Created');
                } catch (e) {
                  print(e);

                  String errorMessage = 'An error occurred. Please try again.';

                  if (e is FirebaseAuthException) {
                    if (e.code == 'weak-password') {
                      errorMessage = 'The password provided is too weak.';
                    } else if (e.code == 'email-already-in-use') {
                      errorMessage = 'The account already exists for that email.';
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );

                  setState(() {
                    showSpinner = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
