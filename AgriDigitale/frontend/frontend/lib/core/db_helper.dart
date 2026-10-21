// Base de données locale SQLite (via sqflite).
// Stocke les favoris, le cache articles (TTL 6h) et le cache météo (TTL 2h).
// Sur le web, sqflite n'est pas supporté — toutes les méthodes retournent null/[].
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  // Retourne la DB (ouvre si besoin). Retourne null sur le web.
  Future<Database?> get database async {
    if (kIsWeb) return null; // sqflite non supporté sur Web
    _db ??= await _initDB();
    return _db;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'agridigitale.db');
    return openDatabase(
      path,
      version: 5,
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
              source TEXT,
              categorie TEXT,
              datePublication TEXT,
              vues INTEGER,
              cachedAt INTEGER
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS meteo_cache (
              ville TEXT PRIMARY KEY,
              imageUrl TEXT NOT NULL,
              cachedAt INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS meteo_historique (
              ville TEXT PRIMARY KEY,
              consultéAt INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE articles_cache ADD COLUMN source TEXT');
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE articles_cache ADD COLUMN legendeImage TEXT');
            await db.execute('ALTER TABLE articles_cache ADD COLUMN auteur TEXT');
          } catch (_) {}
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favoris_cache (
            id TEXT PRIMARY KEY,
            titre TEXT,
            resume TEXT,
            image TEXT,
            legendeImage TEXT,
            auteur TEXT,
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
            legendeImage TEXT,
            auteur TEXT,
            lienSource TEXT,
            source TEXT,
            categorie TEXT,
            datePublication TEXT,
            vues INTEGER,
            cachedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE meteo_cache (
            ville TEXT PRIMARY KEY,
            imageUrl TEXT NOT NULL,
            cachedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE meteo_historique (
            ville TEXT PRIMARY KEY,
            consultéAt INTEGER NOT NULL
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

  // ── Cache articles


  Future<void> sauvegarderArticles(List<Map<String, dynamic>> articles, {String? categorie}) async {
    final db = await database;
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final a in articles) {
      batch.insert('articles_cache', {...a, 'cachedAt': now},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> listerArticlesLocaux({
    String? categorie,
    int page = 1,
    int limite = 20,
  }) async {
    final db = await database;
    if (db == null) return [];
    final offset = (page - 1) * limite;
    return db.query(
      'articles_cache',
      where: categorie != null ? 'categorie = ?' : null,
      whereArgs: categorie != null ? [categorie] : null,
      orderBy: 'datePublication DESC',
      limit: limite,
      offset: offset,
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

  // ── Cache météo : TTL 2h pour éviter trop d'appels API
  static const _meteoCacheTTL = Duration(hours: 2);

  Future<void> sauvegarderMeteoCache(String ville, String imageUrl) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'meteo_cache',
      {'ville': ville.toLowerCase(), 'imageUrl': imageUrl, 'cachedAt': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMeteoCache(String ville) async {
    final db = await database;
    if (db == null) return null;
    final cutoff = DateTime.now().subtract(_meteoCacheTTL).millisecondsSinceEpoch;
    final rows = await db.query(
      'meteo_cache',
      where: 'ville = ? AND cachedAt > ?',
      whereArgs: [ville.toLowerCase(), cutoff],
    );
    return rows.isNotEmpty ? rows.first['imageUrl'] as String? : null;
  }

  // ── Historique des villes recherchées (10 dernières, triées par date)
  Future<void> ajouterVilleHistorique(String ville) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'meteo_historique',
      {'ville': ville.toLowerCase(), 'consultéAt': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getHistoriqueVilles() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query('meteo_historique', orderBy: 'consultéAt DESC', limit: 10);
    return rows.map((r) => r['ville'] as String).toList();
  }

  Future<void> supprimerVilleHistorique(String ville) async {
    final db = await database;
    if (db == null) return;
    await db.delete('meteo_historique', where: 'ville = ?', whereArgs: [ville.toLowerCase()]);
  }
}
