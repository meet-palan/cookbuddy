import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId; // Recipe ID passed to this screen
  const RecipeDetailScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Database _db;
  Map<String, dynamic> _recipeDetails = {};
  List<Map<String, dynamic>> _topComments = [];
  bool _isFavorite = false;
  double _averageRating = 0.0;
  TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    _db = await openDatabase(join(databasePath, 'cookbuddy.db'));
    await _fetchRecipeDetails();
    await _fetchTopComments();
    await _calculateAverageRating();
  }

  Future<void> _fetchRecipeDetails() async {
    final recipe = await _db.query(
      'Recipes',
      where: 'id = ?',
      whereArgs: [widget.recipeId],
    );
    if (recipe.isNotEmpty) {
      setState(() {
        _recipeDetails = recipe.first;
      });
    }
  }

  Future<void> _fetchTopComments() async {
    final comments = await _db.rawQuery('''
      SELECT c.comment, c.rating, c.timestamp, u.username
      FROM CommentAndRating c
      JOIN Users u ON c.userId = u.id
      WHERE c.recipeId = ?
      ORDER BY c.timestamp DESC
      LIMIT 5
    ''', [widget.recipeId]);
    setState(() {
      _topComments = comments;
    });
  }

  Future<void> _calculateAverageRating() async {
    final result = await _db.rawQuery('''
      SELECT AVG(rating) as avgRating
      FROM CommentAndRating
      WHERE recipeId = ?
    ''', [widget.recipeId]);
    setState(() {
      _averageRating = result.isNotEmpty && result.first['avgRating'] != null
          ? (result.first['avgRating'] as num).toDouble()
          : 0.0;
    });
  }

  Future<void> _submitCommentAndRating() async {
    if (_commentController.text.isEmpty || _selectedRating == 0) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Please provide a comment and rating.")),
      );
      return;
    }

    await _db.insert('CommentAndRating', {
      'recipeId': widget.recipeId,
      'userId': 1, // Replace with the logged-in user's ID
      'comment': _commentController.text,
      'rating': _selectedRating,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _commentController.clear();
    _selectedRating = 0;
    await _fetchTopComments();
    await _calculateAverageRating();
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text("Comment and rating submitted!")),
    );
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    if (_isFavorite) {
      // Add to favorites table
      await _db.insert('Favorites', {
        'recipeId': widget.recipeId,
        'userId': 1, // Replace with the logged-in user's ID
      });
    } else {
      // Remove from favorites table
      await _db.delete(
        'Favorites',
        where: 'recipeId = ? AND userId = ?',
        whereArgs: [widget.recipeId, 1], // Replace with user ID
      );
    }
  }

  Future<void> _saveRecipeOffline() async {
    await _db.insert('SavedRecipes', {
      'recipeId': widget.recipeId,
      'userId': 1, // Replace with the logged-in user's ID
    });
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text("Recipe saved for offline access.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipeDetails['name'] ?? "Recipe Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                'Check out this recipe: ${_recipeDetails['name']}',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "${_averageRating.toStringAsFixed(1)} ⭐",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_recipeDetails['youtubeLink'] != null)
                Image.network(
                  _recipeDetails['youtubeLink'], // Replace with actual image URL if available
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                _recipeDetails['name'] ?? "",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Category: ${_recipeDetails['categoryId'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "Time to make: ${_recipeDetails['timing'] ?? 'N/A'} minutes",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                "Ingredients:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_recipeDetails['ingredients'] ?? ""),
              const SizedBox(height: 16),
              const Text(
                "Instructions:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_recipeDetails['instructions'] ?? ""),
              const SizedBox(height: 16),
              if (_recipeDetails['youtubeLink'] != null)
                GestureDetector(
                  onTap: () {
                    // Open YouTube link
                  },
                  child: Text(
                    "Watch on YouTube",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                "Comments:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Write a comment...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _submitCommentAndRating,
                    child: const Text("Submit"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Feedback:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ..._topComments.map((comment) {
                return ListTile(
                  title: Text(comment['comment']),
                  subtitle: Text(
                      "By ${comment['username']} on ${comment['timestamp']}"),
                );
              }).toList(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: _isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _saveRecipeOffline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
