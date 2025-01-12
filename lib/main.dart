import 'package:flutter/material.dart';
import 'screens/general/splash_screen.dart';

Future<void> main() async {
  runApp(CookBuddyApp());
}

class CookBuddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookBuddy',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
