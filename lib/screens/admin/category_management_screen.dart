import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart'; // Import the DatabaseHelper class

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  _CategoryManagementScreenState createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final result = await _dbHelper.getAllCategories();
    setState(() {
      categories = result;
    });
  }

  Future<void> _addCategory(String categoryName) async {
    // Check if the category already exists
    final existingCategories = categories
        .where((category) =>
    category['name'].toString().toLowerCase() ==
        categoryName.toLowerCase())
        .toList();

    if (existingCategories.isNotEmpty) {
      _showSnackBar("Try different category, this is already present.");
      return;
    }

    // Insert the category into the database
    await _dbHelper.addCategory({'name': categoryName});
    await _fetchCategories();
    _showSnackBar("Category added successfully.");
  }

  Future<void> _deleteCategory(int categoryId) async {
    bool? confirmDelete = await _showConfirmationDialog();
    if (confirmDelete ?? false) {
      await _dbHelper.deleteCategory(categoryId);
      await _fetchCategories();
      _showSnackBar("Category deleted successfully.");
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Category"),
          content: const Text("Are you sure you want to delete this category?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddCategoryModal() {
    final TextEditingController categoryController = TextEditingController();
    showModalBottomSheet(
      context: context,
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
      body: categories.isEmpty
          ? const Center(child: Text("No categories available."))
          : ListView.builder(
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
