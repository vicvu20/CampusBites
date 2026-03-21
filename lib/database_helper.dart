import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('campusbites.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE restaurants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        price TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        cost REAL NOT NULL
      )
    ''');

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
  }

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
  }

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final db = await instance.database;
    return await db.query('restaurants', orderBy: 'name ASC');
  }

  Future<int> insertRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('restaurants', row);
  }

  Future<int> updateRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'restaurants',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteRestaurant(int id) async {
    final db = await instance.database;

    await db.delete(
      'favorites',
      where: 'restaurantId = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<bool> isFavorite(int restaurantId) async {
    final db = await instance.database;

    final result = await db.query(
      'favorites',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
    );

    return result.isNotEmpty;
  }

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

  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('expenses', row);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  Future<double> getTotalExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(cost) AS total FROM expenses',
    );

    final value = result.first['total'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }
}