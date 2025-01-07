import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Database _db;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

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
  }

  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = await _db.rawQuery('''
      SELECT id, name, youtubeLink 
      FROM Recipes
      WHERE name LIKE ?
    ''', ['%$query%']);

    setState(() {
      _searchResults = results.map((recipe) {
        return {
          'id': recipe['id'] as int,
          'name': recipe['name'] as String,
          'imageUrl': recipe['youtubeLink'] as String?, // Replace with actual image field if available
        };
      }).toList();
    });
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
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/recipeDetail',
                        arguments: recipe['id'],
                      );
                    },
                    child: Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Display image or fallback image
                          recipe['imageUrl'] != null
                              ? Image.network(
                            recipe['imageUrl']!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              recipe['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }
}
