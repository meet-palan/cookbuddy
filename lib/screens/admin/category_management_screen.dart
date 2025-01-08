import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  _CategoryManagementScreenState createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late Database _db;
  List<Map<String, dynamic>> categories = [];

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
    await _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final result = await _db.query('Categories');
    setState(() {
      categories = result;
    });
  }

  Future<void> _addCategory(String categoryName) async {
    final existing = await _db.query('Categories', where: 'name = ?', whereArgs: [categoryName]);
    if (existing.isNotEmpty) {
      _showMessage("This category is already present. Please give a different category.");
      return;
    }

    await _db.insert('Categories', {"name": categoryName});
    await _fetchCategories();
  }

  Future<void> _deleteCategory(int categoryId) async {
    // Delete category from the table
    await _db.delete('Categories', where: 'id = ?', whereArgs: [categoryId]);

    // Remove the category from Recipes
    await _db.update('Recipes', {"category": null}, where: 'categoryId = ?', whereArgs: [categoryId]);

    await _fetchCategories();
  }

  void _showMessage(String message) {
    showDialog(
      context: this.context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Notice"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryModal() {
    final TextEditingController categoryController = TextEditingController();
    showModalBottomSheet(
      context: this.context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category Name"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final categoryName = categoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  _addCategory(categoryName);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Category Management")),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            child: ListTile(
              title: Text(category['name']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCategory(category['id']),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
