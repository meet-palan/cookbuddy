import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';
import 'package:cookbuddy/screens/admin/recipe_management_screen.dart';
import 'package:cookbuddy/screens/admin/user_management_screen.dart';
import 'package:cookbuddy/screens/admin/category_management_screen.dart';
import 'package:cookbuddy/screens/general/get_started_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _selectedIndex = 0;

  Future<Map<String, dynamic>> _fetchStatistics() async {
    try {
      final db = await _dbHelper.database;

      // Fetch statistics from the database
      final userCountResult = await db.rawQuery('SELECT COUNT(*) AS total FROM Users');
      final recipesCount = await db.rawQuery('SELECT COUNT(*) AS total FROM Recipes');
      final commentsCount = await db.rawQuery(
          'SELECT COUNT(*) AS total FROM CommentAndRating WHERE comment IS NOT NULL');
      final feedbackCount = await db.rawQuery('SELECT COUNT(*) AS total FROM CommentAndRating');
      final creditsSum = await db.rawQuery('SELECT SUM(credits) AS total FROM Transactions');
      final purchasesCount = await db.rawQuery('SELECT COUNT(*) AS total FROM Transactions');
      final categoriesResult = await db.rawQuery(
          'SELECT Categories.name, COUNT(Recipes.categoryId) AS count FROM Recipes '
              'JOIN Categories ON Recipes.categoryId = Categories.id '
              'GROUP BY Recipes.categoryId ORDER BY count DESC LIMIT 5');

      return {
        "totalUsers": userCountResult.first['total'] as int,
        "totalRecipes": recipesCount.first['total'] as int,
        "totalComments": commentsCount.first['total'] as int,
        "totalFeedback": feedbackCount.first['total'] as int,
        "totalCredits": (creditsSum.first['total'] ?? 0) as int,
        "totalPurchases": purchasesCount.first['total'] as int,
        "topCategories": {
          for (var row in categoriesResult)
            row['name'] as String: row['count'] as int,
        },
      };
    } catch (error) {
      print('Error fetching statistics: $error');
      return {};
    }
  }

  void _logOut(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GetStartedScreen()),
    );
  }

  // Future<void> _importDatabaseBackup() async {
  //   try {
  //     // Get the app's database directory
  //     final appDir = await getApplicationDocumentsDirectory();
  //     final dbPath = '${appDir.path}/cookbuddy.db';

  //     // Ensure the database file exists
  //     if (!await File(dbPath).exists()) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Database file does not exist.')),
  //       );
  //       return;
  //     }

  //     // Request storage permissions
  //     final status = await Permission.storage.request();
  //     if (!status.isGranted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Storage permission is required.')),
  //       );
  //       return;
  //     }

  //     // Prompt the user to select a directory to save the file
  //     final result = await FilePicker.platform.getDirectoryPath();
  //     if (result == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No directory selected.')),
  //       );
  //       return;
  //     }

  //     // Copy the database file to the selected directory
  //     final targetPath = '$result/database_backup.db';
  //     final file = File(dbPath);
  //     await file.copy(targetPath);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Database backup downloaded successfully!')),
  //     );
  //   } catch (error) {
  //     print('Error downloading database backup: $error');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error downloading database backup: $error')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                _logOut(context);
              } else if (value == 'import_db') {
                // await _importDatabaseBackup(); // Commented out the import backup code
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Log Out'),
                  ],
                ),
              ),
              // PopupMenuItem(
              //   value: 'import_db',
              //   child: Row(
              //     children: const [
              //       Icon(Icons.upload_file, color: Colors.blue),
              //       SizedBox(width: 8),
              //       Text('Import Backup'),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching statistics."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data available."));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Key Statistics",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard("Total Users", data["totalUsers"].toString(), Colors.blue),
                    _buildStatCard("Total Recipes", data["totalRecipes"].toString(), Colors.green),
                    _buildStatCard("Total Comments", data["totalComments"].toString(), Colors.orange),
                    _buildStatCard("Total Feedback", data["totalFeedback"].toString(), Colors.purple),
                    _buildStatCard("Total Credits", data["totalCredits"].toString(), Colors.teal),
                    _buildStatCard("Total Purchases", data["totalPurchases"].toString(), Colors.red),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  "Top Categories",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...data["topCategories"].entries.map(
                      (entry) => ListTile(
                    title: Text(entry.key),
                    trailing: Text("${entry.value} Recipes"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecipeManagementScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserManagementScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: "Recipes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Users",
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
