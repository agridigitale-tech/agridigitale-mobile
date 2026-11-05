// Service articles : récupère les articles depuis le backend avec fallback cache SQLite et flux RSS direct.
// Sur le web, le cache SQLite est désactivé (kIsWeb). Les images passent par le proxy CORS.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/db_helper.dart';
import '../models/article.dart';

class AccueilDashboardData {
  final Article? alaUne;
  final List<Article> articles;
  final List<String> categories;
  final List<Map<String, dynamic>> bannieres;

  AccueilDashboardData({
    this.alaUne,
    required this.articles,
    required this.categories,
    required this.bannieres,
  });
}

class ArticleService {
  final _dio = ApiClient().dio;
  final _db = DBHelper();

  static String get _backendBase => ApiClient.baseUrl.replaceAll('/api', '');

  /// Récupère en un seul appel réseau l'ensemble des données de démarrage d'accueil
  Future<AccueilDashboardData> recupererDashboardAccueil() async {
    final rep = await _dio.get('/articles/dashboard-accueil');
    final data = rep.data as Map<String, dynamic>;

    Article? alaUne;
    if (data['alaUne'] != null && data['alaUne'] is Map<String, dynamic>) {
      final a = Article.fromJson(data['alaUne'] as Map<String, dynamic>);
      alaUne = a.copyWith(image: _normaliserImage(a.image));
    }

    final articlesList = <Article>[];
    if (data['articles'] is List) {
      for (final e in (data['articles'] as List)) {
        if (e is Map<String, dynamic>) {
          try {
            final a = Article.fromJson(e);
            if (a.id.isNotEmpty) {
              articlesList.add(a.copyWith(image: _normaliserImage(a.image)));
            }
          } catch (_) {}
        }
      }
    }

    final categoriesList = <String>[];
    if (data['categories'] is List) {
      for (final c in (data['categories'] as List)) {
        if (c != null && c.toString().trim().isNotEmpty) {
          categoriesList.add(c.toString().trim());
        }
      }
    }

    final bannieresList = <Map<String, dynamic>>[];
    if (data['bannieres'] is List) {
      for (final b in (data['bannieres'] as List)) {
        if (b is Map<String, dynamic>) {
          bannieresList.add(b);
        }
      }
    }

    // Sauvegarde cache SQLite non bloquante
    if (!kIsWeb && articlesList.isNotEmpty) {
      try {
        _db.sauvegarderArticles(articlesList.map((a) => a.toMap()).toList());
      } catch (_) {}
    }

    return AccueilDashboardData(
      alaUne: alaUne,
      articles: articlesList,
      categories: categoriesList,
      bannieres: bannieresList,
    );
  }

  /// Récupère immédiatement les articles en cache local sans bloquer ni attendre le réseau
  Future<List<Article>> recupererDepuisCacheLocal({String? categorie, int limite = 20}) async {
    if (kIsWeb) return const [];
    try {
      final cached = await _db.listerArticlesLocaux(categorie: categorie, page: 1, limite: limite);
      return cached.map((m) => Article.fromMap(m)).toList();
    } catch (_) {
      return const [];
    }
  }

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
      var article = raw.copyWith(image: _normaliserImage(raw.image));

      // Si la légende de l'image est manquante, tenter de l'extraire rapidement depuis la page source
      if (article.legendeImage.trim().isEmpty && article.lienSource.isNotEmpty) {
        try {
          final legendeExtraite = await _extraireLegendeDepuisLien(article.lienSource);
          if (legendeExtraite != null && legendeExtraite.trim().isNotEmpty) {
            article = article.copyWith(legendeImage: legendeExtraite.trim());
          }
        } catch (_) {}
      }

      // Si le contenu est anormalement court (< 100 car.) ou vide, secours direct sur le flux RSS
      final texteContenu = article.contenu.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (texteContenu.length < 100) {
        try {
          final rssArticles = await recupererDepuisRss();
          final trouve = rssArticles.where((a) =>
              a.id == id ||
              a.guid == id ||
              (a.lienSource.isNotEmpty && article.lienSource.isNotEmpty && a.lienSource == article.lienSource) ||
              (a.titre.isNotEmpty && article.titre.isNotEmpty && a.titre.toLowerCase() == article.titre.toLowerCase())
          ).firstOrNull;
          if (trouve != null && trouve.contenu.trim().isNotEmpty) {
            article = article.copyWith(contenu: trouve.contenu);
          }
        } catch (_) {}
      }

      if (!kIsWeb) {
        try {
          await _db.sauvegarderArticleDetail(article.toMap());
        } catch (e) {
          debugPrint('[ArticleService] Echec sauvegarde cache detail (non bloquant): $e');
        }
      }
      return article;
    } catch (e) {
      debugPrint('[ArticleService] detail hors ligne / exception: $e');
      if (!kIsWeb) {
        try {
          final cached = await _db.getArticleDetail(id);
          if (cached != null) {
            var a = Article.fromMap(cached);
            // Si le corps HTML complet n'est pas encore en cache, utiliser le résumé pour permettre la lecture hors ligne
            if (a.contenu.trim().isEmpty && a.resume.trim().isNotEmpty) {
              a = a.copyWith(contenu: a.resume);
            }
            if (a.contenu.trim().isNotEmpty || a.titre.trim().isNotEmpty) {
              debugPrint('[ArticleService] Article detail servi depuis le cache local SQLite: ${a.titre}');
              return a;
            }
          }
        } catch (dbErr) {
          debugPrint('[ArticleService] Erreur lecture cache local detail: $dbErr');
        }
      }
      // Secours RSS si connectivité partielle
      try {
        final rssArticles = await recupererDepuisRss();
        final trouve = rssArticles.where((a) => a.id == id || a.guid == id || a.lienSource.contains(id)).firstOrNull;
        if (trouve != null) {
          if (!kIsWeb) {
            try {
              await _db.sauvegarderArticleDetail(trouve.toMap());
            } catch (_) {}
          }
          return trouve;
        }
      } catch (_) {}
      rethrow;
    }
  }

  /// Sauvegarde locale explicite d'un article pour garantir sa disponibilité hors ligne
  Future<void> sauvegarderLocalement(Article article) async {
    if (!kIsWeb) {
      try {
        await _db.sauvegarderArticleDetail(article.toMap());
      } catch (e) {
        debugPrint('[ArticleService] Echec sauvegarde locale: $e');
      }
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

        // Image de l'article (enclosure, media:content ou première balise <img>)
        final encMatch = RegExp(r'<enclosure[^>]+url="([^">]+)"', caseSensitive: false).firstMatch(itemStr);
        final mediaMatch = RegExp(r'<media:content[^>]+url="([^">]+)"', caseSensitive: false).firstMatch(itemStr);
        final imgMatch = RegExp(r'<img[^>]+(?:src|data-src)="([^">]+)"', caseSensitive: false).firstMatch(content);
        String? image = encMatch?.group(1) ?? mediaMatch?.group(1) ?? imgMatch?.group(1);
        if (image != null) {
          image = image
              .replaceFirst('agridigitale.com', 'agridigitale.net')
              .replaceAllMapped(
                RegExp(r'(https?://[^/]+)?(?<!/storage)/ck/', caseSensitive: false),
                (m) => '${m.group(1) ?? "https://agridigitale.net"}/storage/ck/',
              );
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

  /// Extrait directement la légende de l'image de couverture depuis la page agridigitale.net
  Future<String?> _extraireLegendeDepuisLien(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final rep = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      final html = rep.data ?? '';
      final m = RegExp(r'data-page="([^"]+)"').firstMatch(html);
      if (m != null) {
        final raw = m.group(1)!
            .replaceAll('&quot;', '"')
            .replaceAll('&#039;', "'")
            .replaceAll('&amp;', '&');
        final parsed = jsonDecode(raw);
        final art = parsed['props']?['article'];
        if (art != null && art['legend'] != null) {
          final leg = art['legend'];
          if (leg is Map) {
            return (leg['fr'] ?? leg['en'] ?? leg.values.firstOrNull)?.toString().trim();
          } else if (leg is String) {
            try {
              final legMap = jsonDecode(leg);
              if (legMap is Map) {
                return (legMap['fr'] ?? legMap['en'] ?? legMap.values.firstOrNull)?.toString().trim();
              }
            } catch (_) {
              return leg.trim();
            }
          }
        }
      }
      final figMatch = RegExp(r'<figcaption[^>]*>([\s\S]*?)<\/figcaption>', caseSensitive: false).firstMatch(html);
      if (figMatch != null) {
        final t = figMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (t.isNotEmpty) return t;
      }
    } catch (_) {}
    return null;
  }
}
