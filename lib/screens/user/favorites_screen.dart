import 'dart:typed_data';
import 'package:cookbuddy/screens/user/recipe_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteRecipes();
  }

  Future<void> _loadFavoriteRecipes() async {
    final favorites = await _databaseHelper.getFavoriteRecipes();

    // Create a mutable copy of each recipe and fetch category names
    final List<Map<String, dynamic>> updatedFavorites = [];
    for (var recipe in favorites) {
      final mutableRecipe = Map<String, dynamic>.from(recipe); // Create a mutable copy
      if (mutableRecipe['categoryId'] != null) {
        final categoryName = await _databaseHelper.getCategoryName(mutableRecipe['categoryId']);
        mutableRecipe['categoryName'] = categoryName; // Add categoryName
      } else {
        mutableRecipe['categoryName'] = "Unknown";
      }
      updatedFavorites.add(mutableRecipe);
    }

    setState(() {
      _favoriteRecipes = updatedFavorites;
    });
  }

  Future<void> _removeFromFavorites(int recipeId) async {
    await _databaseHelper.toggleFavorite(recipeId, false);
    _loadFavoriteRecipes(); // Refresh the favorites list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Removed from favorites.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        centerTitle: true,
      ),
      body: _favoriteRecipes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              "No favorite recipes yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _favoriteRecipes[index];
          Uint8List? recipeImage = recipe['image'];

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: recipeImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.memory(
                  recipeImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
                  : const Icon(
                Icons.fastfood,
                size: 60,
                color: Colors.grey,
              ),
              title: Text(
                recipe['name'] ?? "Unnamed Recipe",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Category: ${recipe['categoryName'] ?? "N/A"}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _removeFromFavorites(recipe['id']),
              ),
              onTap: () {
                // Navigate to RecipeDetailScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecipeDetailScreen(recipeId: recipe['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
