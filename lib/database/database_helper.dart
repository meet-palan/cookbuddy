import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cookbuddy.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
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
  }
}
