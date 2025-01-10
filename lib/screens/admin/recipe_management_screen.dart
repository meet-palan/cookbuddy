import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cookbuddy/database/database_helper.dart';

class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({Key? key}) : super(key: key);

  @override
  _RecipeManagementScreenState createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    await _fetchRecipes();
    await _fetchCategories();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchRecipes() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
        '''
      SELECT Recipes.*, 
             Users.username AS userName 
      FROM Recipes 
      LEFT JOIN Users ON Recipes.uploaderId = Users.id
      '''
    );
    recipes = result;
  }

  Future<void> _fetchCategories() async {
    final db = await _databaseHelper.database;
    final result = await db.query('Categories'); // Fetch all categories
    categories = result;
  }

  Future<void> _deleteRecipe(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('Recipes', where: 'id = ?', whereArgs: [id]);
    await _fetchRecipes();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recipe deleted successfully")),
    );
  }

  void _showAddRecipeModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ingredientsController = TextEditingController();
    final TextEditingController instructionsController = TextEditingController();
    final TextEditingController youtubeController = TextEditingController();
    File? selectedImage;
    int? selectedCategoryId;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Recipe",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      selectedImage = File(pickedFile.path);
                    });
                  }
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Image"),
              ),
              const SizedBox(height: 16),
              selectedImage != null
                  ? Image.file(
                selectedImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
                  : const Text("No image selected"),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Recipe Name"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ingredientsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Ingredients"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Instructions"),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                items: categories
                    .map((category) => DropdownMenuItem<int>(
                  value: category['id'],
                  child: Text(category['name']),
                ))
                    .toList(),
                onChanged: (value) {
                  selectedCategoryId = value;
                },
                decoration: const InputDecoration(labelText: "Select Category"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: youtubeController,
                decoration: const InputDecoration(labelText: "YouTube Link"),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedTime != null
                        ? "Selected Time: ${selectedTime!.hour}:${selectedTime!.minute}"
                        : "No time selected",
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      setState(() {
                        selectedTime = time;
                      });
                    },
                    child: const Text("Select Time"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      ingredientsController.text.isEmpty ||
                      instructionsController.text.isEmpty ||
                      selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all mandatory fields")),
                    );
                    return;
                  }
                  await _databaseHelper.addRecipe({
                    "name": nameController.text,
                    "ingredients": ingredientsController.text,
                    "instructions": instructionsController.text,
                    "categoryId": selectedCategoryId,
                    "youtubeLink": youtubeController.text,
                    "time": selectedTime != null
                        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : null,
                    "image": selectedImage?.path,
                    "insertedBy": "admin", // Admin role
                  });
                  Navigator.pop(context);
                  await _fetchRecipes();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Uploaded successfully")),
                  );
                },
                child: const Text("Upload"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Management"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Card(
            child: ListTile(
              leading: recipe['image'] != null && File(recipe['image']).existsSync()
                  ? Image.file(
                File(recipe['image']),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image, size: 50),
              title: Text(recipe['name'] ?? "Unknown"),
              subtitle: Text(
                "Inserted by: ${recipe['insertedBy'] == 'admin' ? 'Admin' : recipe['userName'] ?? 'Unknown'}\n"
                    "Preparation Time: ${recipe['time'] ?? 'N/A'}",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _deleteRecipe(recipe['id']);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
