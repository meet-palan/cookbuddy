import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Database _db;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    _db = await openDatabase(
      join(databasePath, 'cookbuddy.db'),
    );
    await _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final result = await _db.query('Users', where: 'role != ?', whereArgs: ['admin']);
    setState(() {
      users = result;
    });
  }

  Future<void> _deleteUser(int userId, String email) async {
    await _db.delete('Users', where: 'id = ?', whereArgs: [userId]);
    await _db.update('Recipes', {"insertedBy": null}, where: 'insertedBy = ?', whereArgs: [userId]);
    await _sendEmail(email);
    await _fetchUsers();
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Account Blocked&body=You\'re blocked by Admins and you can\'t log in again. '
          'If you want access to the application, contact the admin at info@gmail.com.',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: this.context,
      isScrollControlled: true,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserDetails(user['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final details = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Recipes by ${user['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ...details.map((detail) => ListTile(
                  title: Text(detail['recipeName']),
                  onTap: () => _showRecipeDetails(detail),
                )),
                const Divider(),
                Text("Comments by ${user['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ...details.map((detail) => ListTile(title: Text(detail['comment']))),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserDetails(int userId) async {
    return await _db.rawQuery('SELECT * FROM Recipes WHERE insertedBy = ?', [userId]);
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: this.context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Ingredients: ${recipe['ingredients']}"),
            Text("Instructions: ${recipe['instructions']}"),
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
              title: Text(user['name']),
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
