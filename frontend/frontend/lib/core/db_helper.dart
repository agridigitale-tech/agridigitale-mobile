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
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS articles_cache (
              id TEXT PRIMARY KEY,
              guid TEXT,
              titre TEXT,
              contenu TEXT,
              resume TEXT,
              image TEXT,
              lienSource TEXT,
              categorie TEXT,
              datePublication TEXT,
              vues INTEGER,
              cachedAt INTEGER
            )
          ''');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favoris_cache (
            id TEXT PRIMARY KEY,
            titre TEXT,
            resume TEXT,
            image TEXT,
            categorie TEXT,
            datePublication TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE articles_cache (
            id TEXT PRIMARY KEY,
            guid TEXT,
            titre TEXT,
            contenu TEXT,
            resume TEXT,
            image TEXT,
            lienSource TEXT,
            categorie TEXT,
            datePublication TEXT,
            vues INTEGER,
            cachedAt INTEGER
          )
        ''');
      },
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

  // ── Cache articles ──────────────────────────────────────────────
  static const _maxAge = Duration(hours: 6);
  static const _minArticles = 20;

  Future<void> sauvegarderArticles(List<Map<String, dynamic>> articles, {String? categorie}) async {
    final db = await database;
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    if (categorie == null) {
      batch.delete('articles_cache');
    } else {
      batch.delete('articles_cache', where: 'categorie = ?', whereArgs: [categorie]);
    }
    for (final a in articles) {
      batch.insert('articles_cache', {...a, 'cachedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> listerArticlesLocaux({String? categorie}) async {
    final db = await database;
    if (db == null) return [];
    final cutoff = DateTime.now().subtract(_maxAge).millisecondsSinceEpoch;

    // D'abord essayer les articles récents (< 6h)
    final recents = await db.query(
      'articles_cache',
      where: categorie != null ? 'categorie = ? AND cachedAt > ?' : 'cachedAt > ?',
      whereArgs: categorie != null ? [categorie, cutoff] : [cutoff],
      orderBy: 'datePublication DESC',
    );
    if (recents.length >= _minArticles) return recents;

    // Sinon retourner tous les articles en cache (même anciens) jusqu'à 20
    return db.query(
      'articles_cache',
      where: categorie != null ? 'categorie = ?' : null,
      whereArgs: categorie != null ? [categorie] : null,
      orderBy: 'datePublication DESC',
      limit: _minArticles,
    );
  }

  Future<void> sauvegarderArticleDetail(Map<String, dynamic> article) async {
    final db = await database;
    if (db == null) return;
    await db.insert('articles_cache', {...article, 'cachedAt': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getArticleDetail(String id) async {
    final db = await database;
    if (db == null) return null;
    final rows = await db.query('articles_cache', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }
}
//***REMOVED-ANTHROPIC-KEY***