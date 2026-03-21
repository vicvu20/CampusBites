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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE restaurants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        price TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final db = await instance.database;
    return db.query('restaurants');
  }

  Future<int> insertRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return db.insert('restaurants', row);
  }

  Future<int> updateRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return db.update('restaurants', row,
        where: 'id=?', whereArgs: [row['id']]);
  }

  Future<int> deleteRestaurant(int id) async {
    final db = await instance.database;
    return db.delete('restaurants', where: 'id=?', whereArgs: [id]);
  }

  // FAVORITES
  Future<void> toggleFavorite(int restaurantId) async {
    final db = await instance.database;

    final existing = await db.query(
      'favorites',
      where: 'restaurantId=?',
      whereArgs: [restaurantId],
    );

    if (existing.isEmpty) {
      await db.insert('favorites', {'restaurantId': restaurantId});
    } else {
      await db.delete(
        'favorites',
        where: 'restaurantId=?',
        whereArgs: [restaurantId],
      );
    }
  }

  Future<bool> isFavorite(int restaurantId) async {
    final db = await instance.database;

    final result = await db.query(
      'favorites',
      where: 'restaurantId=?',
      whereArgs: [restaurantId],
    );

    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await instance.database;

    return db.rawQuery('''
      SELECT restaurants.* FROM restaurants
      INNER JOIN favorites
      ON restaurants.id = favorites.restaurantId
    ''');
  }
}