import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) return null; // sqflite non supporté sur Web
    _db ??= await _initDB();
    return _db;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'agridigitale.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE favoris_cache (
          id TEXT PRIMARY KEY,
          titre TEXT,
          resume TEXT,
          image TEXT,
          categorie TEXT,
          datePublication TEXT
        )
      '''),
    );
  }

  Future<void> sauvegarderFavori(Map<String, dynamic> article) async {
    final db = await database;
    if (db == null) return;
    await db.insert('favoris_cache', article, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> supprimerFavori(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('favoris_cache', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listerFavorisLocaux() async {
    final db = await database;
    if (db == null) return [];
    return db.query('favoris_cache');
  }
}
//***REMOVED-ANTHROPIC-KEY***