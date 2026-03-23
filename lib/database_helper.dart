import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Singleton class to manage a single database instance across the app
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Lazy initialization: only create DB when first accessed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('campusbites.db');
    return _database!;
  }

  // Initialize database and define version for upgrades
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // version used for schema updates
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Create all tables and insert initial sample data
  Future<void> _createDB(Database db, int version) async {
    // Stores restaurant information
    await db.execute('''
      CREATE TABLE restaurants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        price TEXT NOT NULL
      )
    ''');

    // Stores favorite restaurants (relationship table)
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER NOT NULL
      )
    ''');

    // Stores user spending data
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        cost REAL NOT NULL
      )
    ''');

    // Stores user reviews for restaurants
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL
      )
    ''');

    // Insert sample data for testing/demo purposes
    await db.insert('restaurants', {
      'name': 'Chick-fil-A',
      'type': 'Fast Food',
      'price': '\$',
    });

    await db.insert('restaurants', {
      'name': 'Panda Express',
      'type': 'Chinese',
      'price': '\$\$',
    });

    await db.insert('restaurants', {
      'name': 'Subway',
      'type': 'Sandwiches',
      'price': '\$',
    });

    await db.insert('restaurants', {
      'name': 'Cook Out',
      'type': 'Burgers',
      'price': '\$',
    });

    await db.insert('expenses', {
      'item': 'Chick-fil-A Meal',
      'cost': 9.50,
    });

    await db.insert('expenses', {
      'item': 'Subway Combo',
      'cost': 11.25,
    });

    await db.insert('reviews', {
      'restaurantId': 1,
      'rating': 5,
      'comment': 'Great chicken sandwich and fast service.',
    });

    await db.insert('reviews', {
      'restaurantId': 2,
      'rating': 4,
      'comment': 'Solid portions and decent value.',
    });
  }

  // Handles schema updates when database version changes
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          restaurantId INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item TEXT NOT NULL,
          cost REAL NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reviews (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          restaurantId INTEGER NOT NULL,
          rating INTEGER NOT NULL,
          comment TEXT NOT NULL
        )
      ''');
    }
  }

  // Retrieve all restaurants sorted alphabetically
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final db = await instance.database;
    return await db.query('restaurants', orderBy: 'name ASC');
  }

  // Add new restaurant
  Future<int> insertRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('restaurants', row);
  }

  // Update existing restaurant by ID
  Future<int> updateRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'restaurants',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  // Delete restaurant and related data (prevents orphan records)
  Future<int> deleteRestaurant(int id) async {
    final db = await instance.database;

    await db.delete(
      'favorites',
      where: 'restaurantId = ?',
      whereArgs: [id],
    );

    await db.delete(
      'reviews',
      where: 'restaurantId = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Toggle favorite status (add/remove)
  Future<void> toggleFavorite(int restaurantId) async {
    final db = await instance.database;

    final existing = await db.query(
      'favorites',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
    );

    if (existing.isEmpty) {
      await db.insert('favorites', {'restaurantId': restaurantId});
    } else {
      await db.delete(
        'favorites',
        where: 'restaurantId = ?',
        whereArgs: [restaurantId],
      );
    }
  }

  // Check if a restaurant is marked as favorite
  Future<bool> isFavorite(int restaurantId) async {
    final db = await instance.database;

    final result = await db.query(
      'favorites',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
    );

    return result.isNotEmpty;
  }

  // Join query to retrieve full restaurant details for favorites
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT restaurants.* 
      FROM restaurants
      INNER JOIN favorites
      ON restaurants.id = favorites.restaurantId
      ORDER BY restaurants.name ASC
    ''');
  }

  // Add expense entry
  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('expenses', row);
  }

  // Retrieve all expenses (most recent first)
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  // Calculate total spending using SQL aggregation
  Future<double> getTotalExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(cost) AS total FROM expenses',
    );

    final value = result.first['total'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  // Add review for a restaurant
  Future<int> insertReview(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('reviews', row);
  }

  // Retrieve reviews for a specific restaurant
  Future<List<Map<String, dynamic>>> getReviewsForRestaurant(
    int restaurantId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'reviews',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
      orderBy: 'id DESC',
    );
  }

  // Delete a single expense record by its ID
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}