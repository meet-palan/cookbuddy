import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // Private named constructor
  DatabaseHelper._privateConstructor();

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cookbuddy.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }


  // OnCreate method to initialize tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        categoryId INTEGER,
        uploaderId INTEGER,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        youtubeLink TEXT,
        insertedBy TEXT DEFAULT 'admin',
        image TEXT,
        time TEXT,
        FOREIGN KEY(categoryId) REFERENCES Categories(id),
        FOREIGN KEY(uploaderId) REFERENCES Users(id)
         FOREIGN KEY(userId) REFERENCES user(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE CommentAndRating(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER,
        userId INTEGER,
        comment TEXT,
        rating INTEGER,
        FOREIGN KEY(recipeId) REFERENCES Recipes(id),
        FOREIGN KEY(userId) REFERENCES Users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE Transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        credits INTEGER,
        recipeId INTEGER,
        FOREIGN KEY(userId) REFERENCES Users(id),
        FOREIGN KEY(recipeId) REFERENCES Recipes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE admin (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Insert predefined admin records
    await db.insert('admin', {'email': 'meet@gmail.com', 'password': 'meet06'});
    await db.insert('admin', {'email': 'ritik@gmail.com', 'password': 'ritik02'});
    await db.insert('admin', {'email': 'nandan@gmail.com', 'password': 'nandan18'});
  }

  // OnUpgrade method to handle database schema changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        )
      ''');
    }
  }

  // Add a new recipe to the database
  Future<void> addRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    await db.insert('Recipes', recipe);
  }

  // Update recipes on user deletion.
  Future<void> updateRecipesOnUserDeletion(int userId) async {
    final db = await database;
    await db.delete(
      'Recipes',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Fetch user details (recipes and comments).
  Future<List<Map<String, dynamic>>> fetchUserDetails(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT r.name, r.ingredients, r.instructions, r.youtubeLink
      FROM recipes r
      WHERE r.userId = ?
    ''', [userId]);
  }

  // Validate Admin Credentials
  Future<bool> validateAdminCredentials(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'admin',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty;
  }

  Future<bool> validateUserCredentials(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'Users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty;
  }

  // Add a new user
  Future<void> addUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('Users', user);
  }

  // Fetch user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Add category
  Future<void> addCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert('Categories', category);
  }
  //delete category
  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // Fetch all categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('Categories');
  }

  // Add comment and rating
  Future<void> addCommentAndRating(Map<String, dynamic> commentRating) async {
    final db = await database;
    await db.insert('CommentAndRating', commentRating);
  }

  // Fetch comments and ratings for a recipe
  Future<List<Map<String, dynamic>>> getCommentsAndRatings(int recipeId) async {
    final db = await database;
    return await db.query(
      'CommentAndRating',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
    );
  }

  // Close the database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
