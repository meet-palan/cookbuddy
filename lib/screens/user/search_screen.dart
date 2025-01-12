import 'package:cookbuddy/screens/user/recipe_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search recipes based on query
  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'Recipes',
        columns: ['id', 'name'], // Ensure 'id' and 'name' exist in your table
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
      );

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching recipes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Recipes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _searchRecipes,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            // Search results
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                child: Text(
                  'No results found. Start searching!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final recipe = _searchResults[index];
                  final recipeId = recipe['id']; // Get recipe ID safely
                  final recipeName = recipe['name']; // Get recipe name

                  if (recipeId == null) {
                    return const SizedBox(); // Skip if ID is null
                  }

                  return GestureDetector(
                    onTap: () async {
                      try {
                        // Fetch recipe details from the database
                        final recipeDetails = await _dbHelper.getRecipeDetails(recipeId);
                        if (recipeDetails != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(
                                recipeId: recipe['recipeId'], // Pass the recipe details
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error fetching recipe details: $e')),
                        );
                      }
                    },
                    child: Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          recipeName ?? 'Unknown Recipe',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
