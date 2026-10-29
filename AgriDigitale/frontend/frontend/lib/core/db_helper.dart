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
      version: 6,
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
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS meteo_bulletins_semestriels (
              id TEXT PRIMARY KEY,
              date TEXT NOT NULL,
              titre TEXT,
              resumeMatin TEXT,
              resumeApresMidi TEXT,
              tempMin REAL,
              tempMax REAL,
              conseilAgricole TEXT,
              regionsJson TEXT,
              imageUrl TEXT,
              enregistreAt INTEGER NOT NULL
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
        await db.execute('''
          CREATE TABLE IF NOT EXISTS meteo_bulletins_semestriels (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            titre TEXT,
            resumeMatin TEXT,
            resumeApresMidi TEXT,
            tempMin REAL,
            tempMax REAL,
            conseilAgricole TEXT,
            regionsJson TEXT,
            imageUrl TEXT,
            enregistreAt INTEGER NOT NULL
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
      final contenuNouveau = (a['contenu'] as String?)?.trim() ?? '';
      if (contenuNouveau.isEmpty) {
        // Préserver le contenu complet existant en cache si la liste ne contient que le résumé
        batch.rawInsert('''
          INSERT INTO articles_cache (
            id, guid, titre, resume, contenu, image, legendeImage, auteur,
            lienSource, source, categorie, datePublication, vues, cachedAt
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            guid=excluded.guid,
            titre=excluded.titre,
            resume=excluded.resume,
            image=excluded.image,
            legendeImage=excluded.legendeImage,
            auteur=excluded.auteur,
            lienSource=excluded.lienSource,
            source=excluded.source,
            categorie=excluded.categorie,
            datePublication=excluded.datePublication,
            vues=excluded.vues,
            cachedAt=excluded.cachedAt,
            contenu = CASE 
              WHEN articles_cache.contenu IS NOT NULL AND LENGTH(TRIM(articles_cache.contenu)) > 0 
              THEN articles_cache.contenu 
              ELSE excluded.contenu 
            END
        ''', [
          a['id'],
          a['guid'],
          a['titre'],
          a['resume'],
          a['contenu'] ?? '',
          a['image'],
          a['legendeImage'],
          a['auteur'],
          a['lienSource'],
          a['source'],
          a['categorie'],
          a['datePublication'],
          a['vues'] ?? 0,
          now,
        ]);
      } else {
        batch.insert('articles_cache', {...a, 'cachedAt': now},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
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

  // ── Sauvegarde semestrielle des bulletins météo (6 mois / 180 jours max sur le téléphone)
  Future<void> sauvegarderBulletinSemestriel(Map<String, dynamic> bulletin) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'meteo_bulletins_semestriels',
      {
        'id': bulletin['id'] ?? DateTime.now().toIso8601String().substring(0, 10),
        'date': bulletin['date'] ?? DateTime.now().toIso8601String(),
        'titre': bulletin['titre'] ?? 'Bulletin agro-météorologique',
        'resumeMatin': bulletin['resumeMatin'] ?? '',
        'resumeApresMidi': bulletin['resumeApresMidi'] ?? '',
        'tempMin': bulletin['tempMin'] ?? 30.0,
        'tempMax': bulletin['tempMax'] ?? 37.0,
        'conseilAgricole': bulletin['conseilAgricole'] ?? '',
        'regionsJson': bulletin['regionsJson'] ?? '',
        'imageUrl': bulletin['imageUrl'] ?? '',
        'enregistreAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Purger automatiquement les bulletins de plus de 180 jours (6 mois)
    await purgerAnciensBulletins();
  }

  Future<List<Map<String, dynamic>>> getBulletinsSemestriels({int limite = 180}) async {
    final db = await database;
    if (db == null) return [];
    return db.query(
      'meteo_bulletins_semestriels',
      orderBy: 'enregistreAt DESC',
      limit: limite,
    );
  }

  Future<void> purgerAnciensBulletins() async {
    final db = await database;
    if (db == null) return;
    final cutoff180Jours = DateTime.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch;
    await db.delete(
      'meteo_bulletins_semestriels',
      where: 'enregistreAt < ?',
      whereArgs: [cutoff180Jours],
    );
  }
}
