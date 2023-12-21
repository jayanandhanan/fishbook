import 'package:firebase_core/firebase_core.dart';
import 'package:fishbook/splash_creen.dart';
import 'package:flutter/material.dart';

Future main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA7LUrJ0Yr2vHjjHQ0xUV3Cw7_QjHGj-Fw',
        appId: '1:243453214839:android:9f0f0226ec55f6e466c672',
        messagingSenderId: '243453214839',
        projectId: 'fishbook-1ac8c',
        storageBucket: 'fishbook-1ac8c.appspot.com',
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
