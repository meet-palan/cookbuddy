import 'package:flutter/material.dart';
import 'package:cookbuddy/database/database_helper.dart';

class RecipeListScreen extends StatefulWidget {
  final int userId;

  const RecipeListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<Map<String, dynamic>>> _recipeListFuture;
  late Future<List<Map<String, dynamic>>> _userCommentsFuture;

  @override
  void initState() {
    super.initState();
    _recipeListFuture = _fetchUserRecipes();
    _userCommentsFuture = _fetchUserCommentsAndRatings();
  }

  Future<List<Map<String, dynamic>>> _fetchUserRecipes() async {
    return await DatabaseHelper.instance.getRecipesByUser(widget.userId);
  }

  Future<List<Map<String, dynamic>>> _fetchUserCommentsAndRatings() async {
    return await DatabaseHelper.instance.getCommentsAndRatingsByUser(widget.userId);
  }

  Future<String> _getCategoryName(int categoryId) async {
    return await DatabaseHelper.instance.getCategoryName(categoryId);
  }

  Future<void> _deleteRecipe(BuildContext context, int recipeId) async {
    await DatabaseHelper.instance.deleteRecipe(recipeId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recipe deleted successfully.")),
    );
    setState(() {
      _recipeListFuture = _fetchUserRecipes();
    });
  }

  Future<void> _deleteComment(int commentId) async {
    await DatabaseHelper.instance.deleteComment(commentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Recipes and Feedback"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _recipeListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No recipes found for this user.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final recipeList = snapshot.data!;
                return ListView.builder(
                  itemCount: recipeList.length,
                  itemBuilder: (context, index) {
                    final recipe = recipeList[index];
                    return FutureBuilder<String>(
                      future: _getCategoryName(recipe['categoryId'] ?? 0),
                      builder: (context, categorySnapshot) {
                        final categoryName =
                            categorySnapshot.data ?? 'Unknown'; // Fallback to 'Unknown'

                        return ListTile(
                          leading: recipe['image'] != null
                              ? Image.memory(
                            recipe['image'], // Display image if available
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.restaurant_menu, size: 50),
                          title: Text(
                            recipe['name'] ?? 'Untitled Recipe', // Recipe name (null-safe)
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Category: $categoryName", // Use category name here
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Uploaded by: ${recipe['insertedBy'] ?? 'Unknown'}", // Inserted by (admin/user)
                                style: const TextStyle(
                                    fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteRecipe(context, recipe['id']);
                            },
                          ),
                          onTap: () {
                            // Navigate to recipe detail screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(
                                  recipe: recipe,
                                  categoryName: categoryName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(thickness: 2, height: 20),
          Expanded(
            flex: 1,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _userCommentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No comments or ratings found.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: const Icon(Icons.comment, color: Colors.blue),
                      title: Text(comment['comment'] ?? 'No Comment'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rating: ${comment['rating'] ?? 'No Rating'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _deleteComment(comment['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Comment deleted successfully.")),
                          );
                          setState(() {
                            _userCommentsFuture = _fetchUserCommentsAndRatings();
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final String categoryName;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name'] ?? 'Recipe Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe['name'] ?? 'Untitled Recipe',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Category: $categoryName",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Ingredients:\n${recipe['ingredients'] ?? 'No ingredients provided.'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Instructions:\n${recipe['instructions'] ?? 'No instructions provided.'}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
