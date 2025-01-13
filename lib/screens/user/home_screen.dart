import 'dart:typed_data';
import 'package:cookbuddy/screens/user/meal_planner_screen.dart';
import 'package:cookbuddy/screens/user/my_recipes_screen.dart';
import 'package:cookbuddy/screens/user/recipe_selling_screen.dart';
import 'package:cookbuddy/screens/user/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'recipe_details_screen.dart';
import 'package:cookbuddy/database/database_helper.dart';
import 'package:cookbuddy/screens/user/favorites_screen.dart';
import 'package:cookbuddy/screens/user/profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final String userEmail;

  const UserHomeScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  String _username = "";
  int _credits = 0;
  TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  List<Map<String, dynamic>> _recipes = []; // For storing recipes

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _fetchRecipes();
    _assignCreditsToExistingUsers();
  }

  Future<void> _initializeUserData() async {
    final user = await _databaseHelper.getUserByEmail(widget.userEmail);
    if (user != null) {
      setState(() {
        _username = user['username'];
        _credits = user['credits'] ?? 0;
      });
    }
  }

  Future<void> _assignCreditsToExistingUsers() async {
    await _databaseHelper.assignInitialCredits();
    await _initializeUserData(); // Update AppBar credits after assigning
  }

  /// Periodically refresh credits every 2 seconds
  void _startCreditsRefresh() {
    Future.delayed(const Duration(seconds: 2), () async {
      final user = await _databaseHelper.getUserByEmail(widget.userEmail);
      if (user != null && user['credits'] != _credits) {
        setState(() {
          _credits = user['credits'] ?? 0;
        });
      }
      _startCreditsRefresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch recipes with BLOB image data from the database
  Future<void> _fetchRecipes() async {
    final db = await _databaseHelper.database;
    final recipes = await db.rawQuery('''
      SELECT r.id AS recipeId,
             r.name AS recipeName, 
             r.image AS recipeImage, 
             r.insertedBy AS insertedBy,
             r.ingredients AS ingredients,
             r.instructions AS instructions
      FROM Recipes r
    ''');
    setState(() {
      _recipes = recipes;
    });
  }

  /// Build image from Uint8List (BLOB)
  Widget _buildImage(Uint8List? imageBytes) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return Image.memory(
        imageBytes,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image_not_supported, size: 50);
        },
      );
    } else {
      return const Icon(Icons.image_not_supported, size: 50);
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyRecipesScreen(userEmail: widget.userEmail)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeSellingPage(currentUserEmail: widget.userEmail)),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealPlannerScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _startCreditsRefresh(); // Start the credits refresh process
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoriteScreen()),
              );
            },
          ),
          Row(
            children: [
              const Icon(Icons.credit_card),
              const SizedBox(width: 5),
              Text("$_credits"),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(userEmail: widget.userEmail),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hey $_username..!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search recipes...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Recipes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _recipes.isEmpty
                  ? const Center(
                child: Text("No recipes available."),
              )
                  : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  // Fetching the image as Uint8List
                  final imageBytes = recipe['recipeImage'] as Uint8List?;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: imageBytes != null && imageBytes.isNotEmpty
                          ? _buildImage(imageBytes)
                          : const Icon(Icons.image_not_supported,
                          size: 50),
                      title: Text(recipe['recipeName'] ?? 'Unknown'),
                      subtitle: Text("By: ${recipe['insertedBy']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(
                              recipeId: recipe['recipeId'], // Pass recipe ID
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Recipe Selling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Planner',
          ),
        ],
      ),
    );
  }
}


/*
class UserHomeScreen extends StatefulWidget {
  final String userEmail; // Pass the logged-in user's email to this screen
  const UserHomeScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late Database _db;
  String _username = "";
  int _credits = 0;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _categories = [];
  List<int> _selectedCategories = [];
  TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0; // For Bottom Navigation

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _scheduleCreditAddition();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    _db = await openDatabase(
      join(databasePath, 'cookbuddy.db'),
    );
    await _fetchUserData();
    await _fetchRecipes();
    await _fetchCategories();
  }

  Future<void> _fetchUserData() async {
    final user = await _db.query(
      'Users',
      where: 'email = ?',
      whereArgs: [widget.userEmail],
    );
    if (user.isNotEmpty) {
      setState(() {
        _username = user.first['username'] as String;
        _credits = user.first['credits'] != null
            ? user.first['credits'] as int
            : 0;
      });
    }
  }

  Future<void> _fetchRecipes() async {
    final recipes = await _db.rawQuery('''
      SELECT Recipes.id, Recipes.name, Recipes.uploaderId, Recipes.ingredients, Recipes.instructions, Recipes.youtubeLink,
             Users.username AS uploaderName
      FROM Recipes
      LEFT JOIN Users ON Recipes.uploaderId = Users.id
    ''');
    setState(() {
      _recipes = recipes.map((recipe) {
        return {
          'id': recipe['id'] as int,
          'name': recipe['name'] as String,
          'uploaderName': recipe['uploaderName'] as String?,
          'imageUrl': recipe['youtubeLink'] as String?, // Replace with actual image field if available
        };
      }).toList();
    });
  }

  Future<void> _fetchCategories() async {
    final categories = await _db.query('Categories');
    setState(() {
      _categories = categories.map((category) {
        return {
          'id': category['id'] as int,
          'name': category['name'] as String,
        };
      }).toList();
    });
  }

  Future<void> _applyFilter() async {
    if (_selectedCategories.isEmpty) {
      await _fetchRecipes(); // Show all recipes
    } else {
      final recipes = await _db.rawQuery('''
        SELECT Recipes.id, Recipes.name, Recipes.uploaderId, Recipes.ingredients, Recipes.instructions, Recipes.youtubeLink,
               Users.username AS uploaderName
        FROM Recipes
        LEFT JOIN Users ON Recipes.uploaderId = Users.id
        WHERE Recipes.categoryId IN (${_selectedCategories.join(',')})
      ''');
      setState(() {
        _recipes = recipes.map((recipe) {
          return {
            'id': recipe['id'] as int,
            'name': recipe['name'] as String,
            'uploaderName': recipe['uploaderName'] as String?,
            'imageUrl': recipe['youtubeLink'] as String?, // Replace with actual image field if available
          };
        }).toList();
      });
    }
    Navigator.pop(context as BuildContext); // Close the filter modal
  }

  Future<void> _addMorningCredits() async {
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastCreditDate = await _db.query(
      'Users',
      columns: ['lastCreditDate'],
      where: 'email = ?',
      whereArgs: [widget.userEmail],
    );

    if (lastCreditDate.isEmpty ||
        lastCreditDate.first['lastCreditDate'] != currentDate) {
      // Add credits and update last credit date
      setState(() {
        _credits += 100;
      });

      await _db.update(
        'Users',
        {'credits': _credits, 'lastCreditDate': currentDate},
        where: 'email = ?',
        whereArgs: [widget.userEmail],
      );
    }
  }

  void _scheduleCreditAddition() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 7, 0, 0);
    final duration = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1)).difference(now)
        : scheduledTime.difference(now);

    Future.delayed(duration, () async {
      await _addMorningCredits();
      _scheduleCreditAddition(); // Re-schedule for the next day
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
       Navigator.push(context as BuildContext, MaterialPageRoute(builder: (context) => SearchScreen()));
        break;
      case 1:
        Navigator.push(context as BuildContext, MaterialPageRoute(builder: (context) => SearchScreen()));
        break;
      case 2:
        Navigator.push(context as BuildContext, MaterialPageRoute(builder: (context) => SearchScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Spacer(),
            Text("Hey $_username!", style: const TextStyle(fontSize: 18)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              //Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
            },
          ),
          Row(
            children: [
              const Icon(Icons.credit_card),
              const SizedBox(width: 5),
              Text("$_credits"),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addMorningCredits,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search recipes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ..._categories.map((category) {
                                    return CheckboxListTile(
                                      title: Text(category['name']),
                                      value: _selectedCategories.contains(category['id']),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedCategories.add(category['id']);
                                          } else {
                                            _selectedCategories.remove(category['id']);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                  ElevatedButton(
                                    onPressed: _applyFilter,
                                    child: const Text("Apply Filter"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/recipeDetail',
                        arguments: recipe['id'],
                      );
                    },
                    child: Card(
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Image.network(
                            recipe['imageUrl'] ?? 'default_image_url',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                          ),
                          Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe['name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                Text(
                                  recipe['uploaderName'] ?? 'Admin',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Recipe Selling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Planner',
          ),
        ],
      ),
    );
  }
} */

