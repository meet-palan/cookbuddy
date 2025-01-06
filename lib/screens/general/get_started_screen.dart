import 'package:flutter/material.dart';
//import '../user/login_screen.dart';
//import '../admin/login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/get_started_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'CookBuddy',
              style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '"Good food is good mood"',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: Text('User Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminLoginScreen()));
              },
              child: Text('Admin Login'),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
