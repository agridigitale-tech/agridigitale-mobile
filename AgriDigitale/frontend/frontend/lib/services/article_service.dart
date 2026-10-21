// Service articles : récupère les articles depuis le backend avec fallback cache SQLite et flux RSS direct.
// Sur le web, le cache SQLite est désactivé (kIsWeb). Les images passent par le proxy CORS.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/db_helper.dart';
import '../models/article.dart';

class ArticleService {
  final _dio = ApiClient().dio;
  final _db = DBHelper();

  static String get _backendBase => ApiClient.baseUrl.replaceAll('/api', '');

  Future<Article?> articleUne() async {
    try {
      final rep = await _dio.get('/articles/une');
      final article = Article.fromJson(rep.data);
      return article.copyWith(image: _normaliserImage(article.image));
    } catch (_) {
      // 1. Essai depuis le cache SQLite local
      if (!kIsWeb) {
        final cached = await _db.listerArticlesLocaux(limite: 1);
        if (cached.isNotEmpty) return Article.fromMap(cached.first);
      }
      // 2. Essai direct via le flux RSS officiel (le premier article = à la une)
      final rssArticles = await recupererDepuisRss();
      if (rssArticles.isNotEmpty) return rssArticles.first;
      return null;
    }
  }

  Future<List<Article>> lister({String? categorie, int page = 1, bool forceRefresh = false}) async {
    try {
      final rep = await _dio.get(
        '/articles',
        queryParameters: {
          if (categorie != null) 'categorie': categorie,
          'page': page,
          'limite': 20,
        },
      );
      debugPrint('[ArticleService] Statut: ${rep.statusCode}, type data: ${rep.data.runtimeType}');
      if (rep.data is! List) {
        debugPrint('[ArticleService] !! data n\'est PAS une List: ${rep.data}');
        return const [];
      }
      final raw = rep.data as List;
      final articles = <Article>[];
      for (final e in raw) {
        try {
          final a = Article.fromJson(e as Map<String, dynamic>);
          if (a.id.isEmpty) continue;
          articles.add(a.copyWith(image: _normaliserImage(a.image)));
        } catch (err) {
          // Un article invalide ne doit jamais faire échouer toute la liste
          debugPrint('[ArticleService] !! Article ignoré (parse échoué): $err');
        }
      }
      debugPrint('[ArticleService] ${articles.length} articles parsés OK');
      // Sauvegarder en cache (page 1 seulement) — non bloquant : un échec
      // de cache ne doit jamais empêcher l'affichage des articles.
      if (page == 1 && !kIsWeb) {
        try {
          await _db.sauvegarderArticles(
            articles.map((a) => a.toMap()).toList(),
            categorie: categorie,
          );
        } catch (e) {
          debugPrint('[ArticleService] Echec sauvegarde cache liste (non bloquant): $e');
        }
      }
      return articles;
    } on DioException catch (e) {
      debugPrint('[ArticleService] Erreur réseau, lecture cache: ${e.message}');
      if (!kIsWeb) {
        final cached = await _db.listerArticlesLocaux(categorie: categorie, page: page, limite: 20);
        if (cached.isNotEmpty) {
          debugPrint('[ArticleService] ${cached.length} articles depuis cache SQLite');
          return cached.map((m) => Article.fromMap(m)).toList();
        }
      }
      // Si le cache local est vide, secours direct sur le flux RSS d'agridigitale.net
      final rss = await recupererDepuisRss(categorie: categorie);
      if (rss.isNotEmpty) return rss;
      rethrow;
    } catch (e) {
      debugPrint('[ArticleService] !! Exception non-Dio dans lister: $e');
      final rss = await recupererDepuisRss(categorie: categorie);
      if (rss.isNotEmpty) return rss;
      rethrow;
    }
  }

  Future<Article> detail(String id) async {
    try {
      final rep = await _dio.get('/articles/$id');
      final raw = Article.fromJson(rep.data as Map<String, dynamic>);
      final article = raw.copyWith(image: _normaliserImage(raw.image));
      if (!kIsWeb) {
        try {
          await _db.sauvegarderArticleDetail(article.toMap());
        } catch (e) {
          debugPrint('[ArticleService] Echec sauvegarde cache detail (non bloquant): $e');
        }
      }
      return article;
    } on DioException catch (e) {
      debugPrint('[ArticleService] detail hors ligne: ${e.message}');
      if (!kIsWeb) {
        final cached = await _db.getArticleDetail(id);
        if (cached != null) return Article.fromMap(cached);
      }
      // Secours RSS si non trouvé en cache
      final rssArticles = await recupererDepuisRss();
      final trouve = rssArticles.where((a) => a.id == id || a.guid == id || a.lienSource.contains(id)).firstOrNull;
      if (trouve != null) return trouve;
      rethrow;
    }
  }

  // Parse direct du flux RSS public d'AgriDigitale (agridigitale.net/feed)
  // Permet à l'application de fonctionner 100% de manière autonome sans serveur Render
  Future<List<Article>> recupererDepuisRss({String? categorie}) async {
    try {
      final rep = await _dio.get<String>(
        'https://agridigitale.net/feed',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final xml = rep.data ?? '';
      if (xml.isEmpty) return const [];

      final itemRegex = RegExp(r'<item>([\s\S]*?)<\/item>', multiLine: true);
      final articles = <Article>[];

      String extraireBalise(String itemStr, String tag) {
        final reg = RegExp('<$tag>(?:<!\\[CDATA\\[)?([\\s\\S]*?)(?:\\]\\]>)?<\\/$tag>', caseSensitive: false);
        final m = reg.firstMatch(itemStr);
        return m != null ? m.group(1)!.trim() : '';
      }

      for (final match in itemRegex.allMatches(xml)) {
        final itemStr = match.group(1) ?? '';
        final titre = extraireBalise(itemStr, 'title');
        if (titre.isEmpty) continue;

        final link = extraireBalise(itemStr, 'link');
        final guid = extraireBalise(itemStr, 'guid');
        final description = extraireBalise(itemStr, 'description');
        var content = extraireBalise(itemStr, 'content');
        content = content.replaceAll('{{BASE_URL}}', 'https://agridigitale.net');
        final auteur = extraireBalise(itemStr, 'author');
        final pubDateStr = extraireBalise(itemStr, 'pubDate');
        final cat = extraireBalise(itemStr, 'category');

        final catFinale = cat.isNotEmpty ? cat : 'Général';
        if (categorie != null &&
            categorie.isNotEmpty &&
            !catFinale.toLowerCase().contains(categorie.toLowerCase())) {
          continue;
        }

        // Image de l'article (première image dans le corps)
        final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false).firstMatch(content);
        String? image = imgMatch?.group(1);
        if (image != null) {
          image = image.replaceFirst('agridigitale.com', 'agridigitale.net');
        }

        // Légende de l'image
        final figMatch = RegExp(r'<figcaption[^>]*>([\s\S]*?)<\/figcaption>', caseSensitive: false).firstMatch(content);
        final legendeImage = figMatch != null
            ? figMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim()
            : '';

        final id = guid.isNotEmpty
            ? guid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
            : (link.isNotEmpty ? link.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_') : titre.hashCode.toString());

        DateTime pubDate = DateTime.now();
        if (pubDateStr.isNotEmpty) {
          try {
            pubDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US').parse(pubDateStr.trim());
          } catch (_) {
            pubDate = DateTime.tryParse(pubDateStr) ?? DateTime.now();
          }
        }

        articles.add(Article(
          id: id,
          guid: guid.isNotEmpty ? guid : id,
          titre: titre,
          contenu: content.isNotEmpty ? content : description,
          resume: description,
          image: image,
          legendeImage: legendeImage,
          auteur: auteur.isNotEmpty ? auteur : 'La Rédaction',
          lienSource: link.isNotEmpty ? link : 'https://agridigitale.net',
          source: 'AgriDigitale',
          categorie: catFinale,
          datePublication: pubDate,
          vues: 0,
        ));
      }

      if (!kIsWeb && articles.isNotEmpty) {
        try {
          await _db.sauvegarderArticles(articles.map((a) => a.toMap()).toList(), categorie: categorie);
        } catch (_) {}
      }

      return articles;
    } catch (e) {
      debugPrint('[ArticleService] Erreur lecture flux RSS direct: $e');
      return const [];
    }
  }

  Future<List<Article>> rechercher(String motCle) async {
    final rep = await _dio.get(
      '/articles/recherche',
      queryParameters: {'motCle': motCle},
    );
    final raw = rep.data as List;
    final articles = <Article>[];
    for (final e in raw) {
      try {
        final a = Article.fromJson(e as Map<String, dynamic>);
        if (a.id.isEmpty) continue;
        articles.add(a.copyWith(image: _normaliserImage(a.image)));
      } catch (err) {
        debugPrint('[ArticleService] !! Article de recherche ignoré: $err');
      }
    }
    return articles;
  }

  Future<List<String>> listerCategories() async {
    try {
      final rep = await _dio.get('/articles/categories');
      return List<String>.from(rep.data);
    } catch (_) {
      return ['Togo', 'Afrique', 'Monde'];
    }
  }

  // Normalise une URL image :
  // - Sur mobile : URL directe vers agridigitale.net (très rapide, pas de restriction CORS).
  // - Sur web : passe par le proxy backend uniquement si nécessaire.
  String? _normaliserImage(String? image) {
    if (image == null || image.trim().isEmpty) return null;
    final t = image.trim();
    String url;
    if (t.startsWith('http://') || t.startsWith('https://')) {
      url = t;
    } else if (t.startsWith('/')) {
      url = 'https://agridigitale.net$t';
    } else {
      url = 'https://agridigitale.net/$t';
    }
    // Remplacement systématique de .com par .net
    url = url.replaceFirst('agridigitale.com', 'agridigitale.net');

    if (kIsWeb && !url.startsWith(_backendBase)) {
      return '$_backendBase/api/proxy-image?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
