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
      version: 1,
      onCreate: _onCreate,
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
        FOREIGN KEY(categoryId) REFERENCES Categories(id),
        FOREIGN KEY(uploaderId) REFERENCES Users(id)
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

  // Close the database (optional cleanup)
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
