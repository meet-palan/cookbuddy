import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cookbuddy/database/database_helper.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Management"),
      ),
      body: const Center(
        child: Text(
          "Coming Soon!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}



/*
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final result = await _dbHelper.queryUsersExcludingRole('admin');
    setState(() {
      users = result;
    });
  }

  Future<void> _deleteUser(int userId, String email) async {
    await _dbHelper.deleteUser(userId);
    await _dbHelper.updateRecipesOnUserDeletion(userId);
    await _sendEmail(email);
    await _fetchUsers();
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Account Blocked&body=You\'re blocked by Admins and can no longer log in. '
          'For access to the application, contact the admin at info@gmail.com.',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.fetchUserDetails(user['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final details = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recipes by ${user['username']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...details.map((detail) => ListTile(
                    title: Text(detail['name']),
                    onTap: () => _showRecipeDetails(detail),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Ingredients: ${recipe['ingredients']}"),
            Text("Instructions: ${recipe['instructions']}"),
            if (recipe['youtubeLink'] != null)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(recipe['youtubeLink'])),
                child: const Text("View on YouTube"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Management")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            child: ListTile(
              title: Text(user['username']),
              trailing: ElevatedButton(
                onPressed: () => _deleteUser(user['id'], user['email']),
                child: const Text("Delete"),
              ),
              onTap: () => _showUserDetails(user),
            ),
          );
        },
      ),
    );
  }
}

 */
