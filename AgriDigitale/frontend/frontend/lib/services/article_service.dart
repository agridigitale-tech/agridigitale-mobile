// Service articles : récupère les articles depuis le backend avec fallback cache SQLite.
// Sur le web, le cache SQLite est désactivé (kIsWeb). Les images passent par le proxy CORS.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      return null;
    }
  }

  Future<List<Article>> lister({String? categorie, int page = 1, bool forceRefresh = false}) async {
    try {
      final rep = await _dio.get(
        '/articles',
        queryParameters: {
          'categorie': ?categorie,
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
        final cached = await _db.listerArticlesLocaux(categorie: categorie);
        if (cached.isNotEmpty) {
          debugPrint('[ArticleService] ${cached.length} articles depuis cache SQLite');
          return cached.map((m) => Article.fromMap(m)).toList();
        }
      }
      rethrow;
    } catch (e) {
      debugPrint('[ArticleService] !! Exception non-Dio dans lister: $e');
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
      rethrow;
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

  // Normalise une URL image : ajoute le domaine backend si relative,
  // et redirige via le proxy CORS sur le web pour éviter les erreurs cross-origin
  String? _normaliserImage(String? image) {
    if (image == null || image.trim().isEmpty) return null;
    final t = image.trim();
    String url;
    if (t.startsWith('http://') || t.startsWith('https://')) {
      url = t;
    } else if (t.startsWith('/')) {
      url = '$_backendBase$t';
    } else {
      url = '$_backendBase/$t';
    }
    if (!url.startsWith(_backendBase)) {
      return '$_backendBase/api/proxy-image?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
