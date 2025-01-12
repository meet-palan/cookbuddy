import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cookbuddy/database/database_helper.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  Map<String, dynamic> _recipeDetails = {};
  List<Map<String, dynamic>> _commentsAndRatings = [];
  double _averageRating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  String _categoryName = "N/A";
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
    _loadCommentsAndRatings();
    _checkFavoriteStatus();
  }

  Future<void> _loadRecipeDetails() async {
    final recipe = await _databaseHelper.getRecipeDetails(widget.recipeId);
    if (recipe != null) {
      String categoryName = "N/A";
      if (recipe['categoryId'] != null) {
        categoryName = await _databaseHelper.getCategoryName(recipe['categoryId']);
      }
      setState(() {
        _recipeDetails = recipe;
        _categoryName = categoryName;
      });
    }
  }

  Future<void> _loadCommentsAndRatings() async {
    final comments = await _databaseHelper.getCommentsAndRatings(widget.recipeId);
    double avgRating = 0.0;

    if (comments.isNotEmpty) {
      avgRating = comments.map((e) => e['rating'] as int).reduce((a, b) => a + b) / comments.length;
    }

    setState(() {
      _commentsAndRatings = comments;
      _averageRating = avgRating;
    });
  }

  Future<void> _checkFavoriteStatus() async {
    bool isFavorite = await _databaseHelper.isRecipeFavorite(widget.recipeId);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    await _databaseHelper.toggleFavorite(widget.recipeId, !_isFavorite);
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? "Recipe added to favorites!"
            : "Recipe removed from favorites!"),
      ),
    );
  }

  Future<void> _submitCommentAndRating() async {
    if (_commentController.text.isEmpty || _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide both a comment and a rating.")),
      );
      return;
    }

    final commentData = {
      'recipeId': widget.recipeId,
      'userId': 1, // Replace with the actual user ID in a real app
      'comment': _commentController.text,
      'rating': _selectedRating,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _databaseHelper.addCommentAndRating(commentData);

    _commentController.clear();
    _selectedRating = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Comment and rating submitted successfully.")),
    );

    _loadCommentsAndRatings();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? recipeImage = _recipeDetails['image'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipeDetails['name'] ?? "Recipe Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share('Check out this recipe: ${_recipeDetails['name']}');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipeImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.memory(
                    recipeImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _recipeDetails['name'] ?? "",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "${_averageRating.toStringAsFixed(1)} ⭐",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Category: $_categoryName",
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
              const Text(
                "Comments & Ratings:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: _commentsAndRatings.map((comment) {
                  String formattedTime = DateFormat('dd-MM-yyyy HH:mm').format(
                    DateTime.parse(comment['timestamp']),
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(comment['comment'] ?? ""),
                      subtitle: Text("Rating: ${comment['rating']}/5"),
                      trailing: Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                "Add Your Comment:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Enter your comment",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: _selectedRating > index ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitCommentAndRating,
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
