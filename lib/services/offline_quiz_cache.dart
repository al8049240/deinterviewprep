import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class OfflineQuizCache {
  OfflineQuizCache._();

  static final OfflineQuizCache instance = OfflineQuizCache._();
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, 'quiz_cache.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE quiz_sets (cache_key TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER NOT NULL)',
        );
      },
    );
    return _database!;
  }

  Future<void> saveSet(
    String cacheKey,
    List<Map<String, dynamic>> questions,
  ) async {
    final db = await _db;
    await db.insert('quiz_sets', {
      'cache_key': cacheKey,
      'payload': jsonEncode(questions),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> readSet(String cacheKey) async {
    final db = await _db;
    final rows = await db.query(
      'quiz_sets',
      columns: ['payload'],
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return const [];
    final decoded = jsonDecode(rows.first['payload']! as String) as List;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
