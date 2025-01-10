import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';
import 'package:cookbuddy/screens/admin/recipe_management_screen.dart';
import 'package:cookbuddy/screens/admin/user_management_screen.dart';
import 'category_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int totalUsers = 0;
  int totalRecipes = 0;
  int totalComments = 0;
  int totalFeedback = 0;
  int totalCredits = 0;
  int totalPurchases = 0;
  Map<String, int> topCategories = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      // Fetch total users excluding admins
      final db = await _dbHelper.database;
      final userCountResult = await db.rawQuery('''
        SELECT COUNT(*) AS total FROM Users )
      ''');

      // Fetch other statistics
      final recipesCount = await db.rawQuery('SELECT COUNT(*) AS total FROM Recipes');
      final commentsCount = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM CommentAndRating WHERE comment IS NOT NULL',
      );
      final feedbackCount = await db.rawQuery('SELECT COUNT(*) AS total FROM CommentAndRating');
      final creditsSum = await db.rawQuery('SELECT SUM(credits) AS total FROM Transactions');
      final purchasesCount = await db.rawQuery('SELECT COUNT(*) AS total FROM Transactions');
      final categoriesResult = await db.rawQuery('''
        SELECT Categories.name, COUNT(Recipes.categoryId) AS count
        FROM Recipes
        JOIN Categories ON Recipes.categoryId = Categories.id
        GROUP BY Recipes.categoryId
        ORDER BY count DESC
        LIMIT 5
      ''');

      setState(() {
        totalUsers = userCountResult.first['total'] as int;
        totalRecipes = recipesCount.first['total'] as int;
        totalComments = commentsCount.first['total'] as int;
        totalFeedback = feedbackCount.first['total'] as int;
        totalCredits = (creditsSum.first['total'] ?? 0) as int;
        totalPurchases = purchasesCount.first['total'] as int;
        topCategories = {
          for (var row in categoriesResult) row['name'] as String: row['count'] as int,
        };
      });
    } catch (error) {
      print('Error fetching statistics: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                _buildStatCard("Total Users", totalUsers.toString(), Colors.blue),
                _buildStatCard("Total Recipes", totalRecipes.toString(), Colors.green),
                _buildStatCard("Total Comments", totalComments.toString(), Colors.orange),
                _buildStatCard("Total Feedback", totalFeedback.toString(), Colors.purple),
                _buildStatCard("Total Credits", totalCredits.toString(), Colors.teal),
                _buildStatCard("Total Purchases", totalPurchases.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Top Categories",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topCategories.entries.map((entry) => ListTile(
              title: Text(entry.key),
              trailing: Text("${entry.value} Recipes"),
            )),
          ],
        ),
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
              MaterialPageRoute(builder: (context) => RecipeManagementScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserManagementScreen()),
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
