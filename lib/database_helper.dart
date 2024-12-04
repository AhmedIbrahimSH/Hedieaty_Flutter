import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    // If not initialized, initialize it
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'users.db');
    return await openDatabase(path, onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER, phone TEXT, notstatus INTEGER)',
      );
    }, version: 1);
  }

  // Save user data
  Future<void> updateUser(int id, String name, int age, String phone, int notstatus) async {
    final db = await database;
    await db.update(
      'users',
      {'name': name, 'age': age, 'phone': phone, 'notstatus': notstatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get user by id
  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
