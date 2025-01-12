import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final int userId; // Pass the user's ID to fetch their data

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String username = "";
  String email = "";
  String password = "";
  int totalCredits = 0;
  bool showPassword = false;
  bool showComments = true;
  List<Map<String, dynamic>> userComments = [];
  List<Map<String, dynamic>> userRatings = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    // Fetch user details
    final user = await _dbHelper.getUserByEmail("user@example.com"); // Use your email fetching logic
    final credits = await _dbHelper.getAllFavorites(); // Example to fetch credits

    setState(() {
      username = user?['username'] ?? "Unknown";
      email = user?['email'] ?? "Unknown";
      password = user?['password'] ?? "Unknown";
      totalCredits = credits.length; // Example logic for total credits
    });
  }

  Future<void> fetchCommentsAndRatings() async {
    final comments = await _dbHelper.getCommentsAndRatings(widget.userId);
    setState(() {
      userComments = comments;
      userRatings = comments.where((c) => c['rating'] != null).toList();
    });
  }

  void togglePasswordVisibility() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  Widget buildListItems() {
    if (showComments) {
      return ListView.builder(
        itemCount: userComments.length,
        itemBuilder: (context, index) {
          final comment = userComments[index];
          return ListTile(
            title: Text(comment['comment']),
            subtitle: Text("Recipe ID: ${comment['recipeId']}"),
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: userRatings.length,
        itemBuilder: (context, index) {
          final rating = userRatings[index];
          return ListTile(
            title: Text("Rating: ${rating['rating']}"),
            subtitle: Text("Recipe ID: ${rating['recipeId']}"),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                username.isNotEmpty ? username[0] : "",
                style: TextStyle(fontSize: 32),
              ),
            ),
            SizedBox(height: 10),
            Text(username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: password,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: togglePasswordVisibility,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.orange),
                SizedBox(width: 10),
                Text("Total Credits: $totalCredits"),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showComments = true;
                      });
                    },
                    child: Text("Comments"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showComments = false;
                      });
                    },
                    child: Text("Ratings"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(child: buildListItems()),
          ],
        ),
      ),
    );
  }
}
