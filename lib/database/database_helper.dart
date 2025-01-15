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
        credits INTEGER,
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
        image BLOB,
        time TEXT,
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
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        message TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE SellingRecipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        categoryId INTEGER,
        image BLOB,
        credits INTEGER,
        userEmail TEXT,
        ingredients TEXT,
        instructions TEXT,
        FOREIGN KEY (categoryId) REFERENCES Categories(id)
      )
    ''');


    await db.execute('''
      CREATE TABLE CommentAndRating(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER,
        userId INTEGER,
        comment TEXT,
        rating INTEGER,
        timestamp TEXT NOT NULL,
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
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER UNIQUE,
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
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipeId INTEGER UNIQUE,
          FOREIGN KEY(recipeId) REFERENCES Recipes(id)
        )
      ''');
    }
  }
  Future<Map<String, dynamic>?> getRecipeDetails(int recipeId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Recipes',
      where: 'id = ?',
      whereArgs: [recipeId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Add a new recipe to the database
  Future<void> addRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    await db.insert('Recipes', recipe);
  }
  Future<List<Map<String, dynamic>>> fetchUserRecipes(int userId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT Recipes.*, 
           Categories.name AS categoryName
    FROM Recipes
    LEFT JOIN Categories ON Recipes.categoryId = Categories.id
    WHERE Recipes.uploaderId = ?
  ''', [userId]);
  }
  Future<void> addRecipeByUser(Map<String, dynamic> recipeData, String userEmail) async {
    final db = await database;

    // Find user ID based on email
    final userResult = await db.query(
      'Users',
      columns: ['id', 'username'],
      where: 'email = ?',
      whereArgs: [userEmail],
    );

    if (userResult.isEmpty) {
      throw Exception("User not found for the given email");
    }

    final userId = userResult.first['id'];
    final username = userResult.first['username'];


    // Insert the recipe
    await db.insert(
      'Recipes',
      {
        'name': recipeData['name'],
        'ingredients': recipeData['ingredients'],
        'instructions': recipeData['instructions'],
        'categoryId': recipeData['categoryId'],
        'youtubeLink': recipeData['youtubeLink'],
        'time': recipeData['time'],
        'image': recipeData['image'],
        'uploaderId': userId,
        'insertedBy': username, // Add username as "insertedBy"
      },
    );
  }


  Future<List<Map<String, dynamic>>> getRecipesByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT Recipes.*, Users.username AS uploaderName 
      FROM Recipes 
      INNER JOIN Users ON Recipes.uploaderId = Users.id
      WHERE Users.email = ?
    ''', [email]);
    return result;
  }
  //recipes for selling
  Future<void> addSellingRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    await db.insert(
      'SellingRecipes',
      recipe,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  //get recipes which are for selling
  Future<List<Map<String, dynamic>>> getSellingRecipes() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT sr.*, u.username AS listedBy
    FROM SellingRecipes sr
    LEFT JOIN Users u ON sr.userEmail = u.email
  ''');
  }

  //checking if same recipe listed or not
  Future<bool> isRecipeAlreadyListedForSale(String recipeName, String userEmail) async {
    final db = await database;
    final result = await db.query(
      'SellingRecipes',
      where: 'name = ? AND userEmail = ?',
      whereArgs: [recipeName, userEmail],
    );
    return result.isNotEmpty;
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

  Future<void> deleteRecipe(int recipeId) async {
    final db = await database;

    // Perform delete operation
    await db.delete(
      'recipes', // Replace 'recipes' with your table name
      where: 'id = ?', // Specify the condition for deletion
      whereArgs: [recipeId], // Provide the recipe ID
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
  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'Users',
      {
        'username': user['username'],
        'email': user['email'],
        'password': user['password'],
      },
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('Users'); // Replace 'Users' with your actual table name
  }
// Delete user and their recipes
  Future<void> deleteUserAndRecipes(int userId) async {
    final db = await instance.database;

    // Start a transaction to ensure both deletions happen together
    await db.transaction((txn) async {
      // Delete recipes associated with the user
      await txn.delete(
        'Recipes', // Replace 'Recipes' with your actual recipe table name
        where: 'uploaderId = ?',
        whereArgs: [userId],
      );

      // Delete the user
      await txn.delete(
        'Users',
        where: 'id = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getRecipesByUser(int userId) async {
    final db = await instance.database;

    // Query the Recipes table to fetch recipes for the given uploaderId
    final List<Map<String, dynamic>> recipes = await db.query(
      'Recipes', // Table name
      where: 'uploaderId = ?', // Condition to filter by userId
      whereArgs: [userId], // Pass userId as an argument
      columns: [
        'id',
        'name',
        'categoryId',
        'ingredients',
        'instructions',
        'youtubeLink',
        'insertedBy',
        'image',
        'time'
      ], // Specify the columns to retrieve
    );

    return recipes;
  }


  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert('Transactions', transaction);
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
  Future<void> addCommentAndRating(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('CommentAndRating', data);
  }

  //comment and rating by user
  Future<List<Map<String, dynamic>>> getCommentsAndRatingsByUser(int userId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT c.*
    FROM CommentAndRating c
    WHERE c.userId = ? 
  ''', [userId]);
  }

  //delete comment
  Future<void> deleteComment(int commentId) async {
    final db = await database;
    await db.delete(
      'CommentAndRating', // Replace with your actual table name
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }


  // Fetch comments and ratings for a recipe
  Future<List<Map<String, dynamic>>> getCommentsAndRatings(int recipeId) async {
    final db = await database;
    return await db.query(
      'CommentAndRating',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
      orderBy: 'id DESC',
    );
  }
  Future<void> subscribeUser(String email, String message) async {
    final db = await database;
    await db.insert('subscriptions', {
      'email': email,
      'message': message,
    });
  }

  Future<bool> isUserSubscribed(String email) async {
    final db = await database;
    final result = await db.query(
      'subscriptions',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<String> getCategoryName(int categoryId) async {
    final db = await database;

    // Query to get the category name from the Categories table
    final List<Map<String, dynamic>> result = await db.query(
      'Categories',
      columns: ['name'], // Fetching only the 'name' column
      where: 'id = ?',    // Filtering by categoryId
      whereArgs: [categoryId],
    );

    if (result.isNotEmpty) {
      return result.first['name'];
    } else {
      return 'Unknown';  // Return 'Unknown' if no category is found
    }
  }
  Future<int> addToFavorites(int recipeId) async {
    final db = await instance.database;
    return await db.insert('favorites', {'recipeId': recipeId});
  }

  // Remove recipe from favorites
  Future<int> removeFromFavorites(int recipeId) async {
    final db = await instance.database;
    return await db.delete(
      'favorites',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
    );
  }


  // Check if recipe is in favorites
  Future<bool> isRecipeFavorite(int recipeId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
    );
    return result.isNotEmpty;
  }

  // Get all favorite recipes
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await instance.database;
    final result = await db.query('favorites');
    return result;
  }
  Future<List<Map<String, dynamic>>> getFavoriteRecipes() async {
    final db = await database;
    return await db.rawQuery(
        '''
    SELECT recipes.* 
    FROM recipes 
    INNER JOIN favorites 
    ON recipes.id = favorites.recipeId
    '''
    );
  }
  Future<void> toggleFavorite(int recipeId, bool isFavorite) async {
    final db = await database;

    if (isFavorite) {
      // Add to favorites
      await db.insert('favorites', {'recipeId': recipeId});
    } else {
      // Remove from favorites
      await db.delete('favorites', where: 'recipeId = ?', whereArgs: [recipeId]);
    }
  }

  Future<int> updateUserCredits(int userId, int credits) async {
    final db = await instance.database;
    return await db.update(
      'Users',
      {'credits': credits},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  Future<void> assignInitialCredits() async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE Users
      SET credits = 1000
      WHERE credits IS NULL OR credits = 0
    ''');
  }


  // Close the database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
