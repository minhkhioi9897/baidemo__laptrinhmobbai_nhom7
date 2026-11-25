import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('voicehub_hybrid.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE voice_items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        audio_path TEXT,
        mood_emoji TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('voice_items', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getItemsByType(String type) async {
    final db = await instance.database;
    return await db.query(
      'voice_items',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await instance.database;
    return await db.query('voice_items', orderBy: 'created_at DESC');
  }

  Future<int> deleteItem(String id) async {
    final db = await instance.database;
    return await db.delete('voice_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
