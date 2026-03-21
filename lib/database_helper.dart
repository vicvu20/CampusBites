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
      version: 1,
      onCreate: _createDB,
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
  }

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final db = await instance.database;
    return await db.query('restaurants', orderBy: 'name ASC');
  }

  Future<int> insertRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('restaurants', row);
  }

  // ✅ UPDATE
  Future<int> updateRestaurant(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'restaurants',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  // ✅ DELETE
  Future<int> deleteRestaurant(int id) async {
    final db = await instance.database;
    return await db.delete(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}