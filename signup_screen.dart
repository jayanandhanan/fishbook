import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String phone = '';
  String password = '';
  String confirmPassword = '';
  String organizationId = '';
  String coownerId = '';
  String crewmemberId = '';
  String selectedRole = 'Headowner';
  String boatName = '';

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Function to generate a unique ID
  String generateUniqueId() {
    return _firestore.collection('organizations').doc().id;
  }

  // Function to conditionally render input fields based on the selected role
  Widget roleSpecificFields() {
    if (selectedRole == 'Headowner') {
      return Column(
        children: [
          const SizedBox(height: 8.0),
          TextField(
            textAlign: TextAlign.center,
            onChanged: (value) {
              boatName = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter boat name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
          ),
        ],
      );
    } else if (selectedRole == 'Co-owner') {
      return Column(
        children: [
          const SizedBox(height: 8.0),
          TextField(
            textAlign: TextAlign.center,
            onChanged: (value) {
              organizationId = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter organization ID shared by Headowner',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            textAlign: TextAlign.center,
            onChanged: (value) {
              coownerId = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter your Co-owner ID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
          ),
        ],
      );
    } else if (selectedRole == 'Crewmember') {
      return Column(
        children: [
          const SizedBox(height: 8.0),
          TextField(
            textAlign: TextAlign.center,
            onChanged: (value) {
              organizationId = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter organization ID shared by Headowner',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            textAlign: TextAlign.center,
            onChanged: (value) {
              crewmemberId = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter your Crewmember ID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
          ),
        ],
      );
    }

    return Container(); // Return an empty container if none of the conditions are met
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Sign Up and Enjoy the Experience',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                textAlign: TextAlign.center,
                onChanged: (value) {
                  name = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
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
              TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  phone = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
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
              const SizedBox(height: 8.0),
              TextField(
                textAlign: TextAlign.center,
                obscureText: true,
                onChanged: (value) {
                  confirmPassword = value;
                },
                decoration: InputDecoration(
                  hintText: 'Confirm your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              // DropdownButton for selecting the role
              DropdownButton<String>(
                value: selectedRole,
                hint: Text('Select Role'),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                items: ['Headowner', 'Co-owner', 'Crewmember']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8.0),
              // Call the roleSpecificFields method to conditionally render input fields
              roleSpecificFields(),
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      showSpinner = true;
                    });

                    try {
                      UserCredential? userCredential;

                      if (selectedRole == 'Headowner') {
                        userCredential = await _auth.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        organizationId = generateUniqueId();
                        coownerId = generateUniqueId();
                        crewmemberId = generateUniqueId();

                        await _firestore.collection('organizations').doc(organizationId).set({
                          'boatname': boatName,
                          'coownerId': coownerId,
                          'crewmemberId': crewmemberId,
                          'organizationId': organizationId,
                        });

                        await _firestore.collection('organizations').doc(organizationId).collection('headowners').doc(userCredential!.user!.uid).set({
                          'name': name,
                          'email': email,
                          'phone': phone,
                        });

                        await _firestore.collection('organizations').doc(organizationId).collection('ownerdetails').doc(userCredential!.user!.uid).set({
                          'name': name,
                          'email': email,
                          'phone': phone,
                        });

                        await _firestore.collection('users').doc(userCredential.user!.uid).set({
                          'name': name,
                          'email': email,
                          'phone': phone,
                          'boatname': boatName,
                          'organizationId': organizationId,
                          'role': selectedRole,
                        });

                      } else if (selectedRole == 'Co-owner' || selectedRole == 'Crewmember') {
                        userCredential = await _auth.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        // Fetch boat name from Headowner's organization
                        DocumentSnapshot orgSnapshot = await _firestore.collection('organizations').doc(organizationId).get();
                        String headownerBoatName = orgSnapshot.get('boatname');

                        String collectionName = selectedRole == 'Co-owner' ? 'co-owners' : 'crewmembers';
                        String subcollectionName = selectedRole == 'Co-owner' ? 'ownerdetails' : 'crewmemberdetails';

                        await _firestore.collection('organizations').doc(organizationId).collection(collectionName).doc(userCredential!.user!.uid).set({
                          'name': name,
                          'email': email,
                          'phone': phone,
                        });

                        await _firestore.collection('organizations').doc(organizationId).collection(subcollectionName).doc(userCredential!.user!.uid).set({
                          'name': name,
                          'email': email,
                          'phone': phone,
                        });

                        await _firestore.collection('users').doc(userCredential!.user!.uid).set({
                          'name': name,
                          'email': email,
                          'phone': phone,
                          'boatname': headownerBoatName,
                          'organizationId': organizationId,
                          'role': selectedRole,
                        });
                      }

                      setState(() {
                        showSpinner = false;
                      });

                      Navigator.pop(context);

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
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
