import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cookbuddy/database/database_helper.dart';

class MyRecipesScreen extends StatefulWidget {
  final String userEmail;

  const MyRecipesScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MyRecipesScreenState createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> myRecipes = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMyRecipes();
    _fetchCategories();
  }

  Future<void> _fetchMyRecipes() async {
    setState(() {
      isLoading = true;
    });

    myRecipes = await _databaseHelper.getRecipesByEmail(widget.userEmail);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchCategories() async {
    categories = await _databaseHelper.getAllCategories();
    setState(() {});
  }

  Future<void> _deleteRecipe(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('Recipes', where: 'id = ?', whereArgs: [id]);
    await _fetchMyRecipes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recipe deleted successfully")),
    );
  }

  void _showAddRecipeModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ingredientsController = TextEditingController();
    final TextEditingController instructionsController = TextEditingController();
    final TextEditingController youtubeController = TextEditingController();
    Uint8List? selectedImage;
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
                  final pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    selectedImage = await pickedFile.readAsBytes();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Image"),
              ),
              const SizedBox(height: 16),
              selectedImage != null
                  ? Image.memory(
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
                        ? "Selected Time: ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                        : "No time selected",
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
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
                      const SnackBar(
                          content: Text("Please fill all mandatory fields")),
                    );
                    return;
                  }
                  await _databaseHelper.addRecipeByUser(
                    {
                      "name": nameController.text,
                      "ingredients": ingredientsController.text,
                      "instructions": instructionsController.text,
                      "categoryId": selectedCategoryId,
                      "youtubeLink": youtubeController.text,
                      "time": selectedTime != null
                          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                          : null,
                      "image": selectedImage,
                    },
                    widget.userEmail,
                  );
                  Navigator.pop(context);
                  await _fetchMyRecipes();
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
        title: const Text("My Recipes"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: myRecipes.length,
        itemBuilder: (context, index) {
          final recipe = myRecipes[index];
          final imageBytes = recipe['image'] as Uint8List?;
          return Card(
            child: ListTile(
              leading: imageBytes != null
                  ? Image.memory(
                imageBytes,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image, size: 50),
              title: Text(recipe['name'] ?? "Unknown"),
              subtitle: Text(
                "Inserted by: ${recipe['uploaderName'] ?? 'Unknown'}\n"
                    "Time: ${recipe['time'] ?? 'N/A'}",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await _deleteRecipe(recipe['id']);
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
