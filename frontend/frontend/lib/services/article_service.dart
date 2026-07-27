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
      final articles = (rep.data as List)
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .map((a) => a.copyWith(image: _normaliserImage(a.image)))
          .toList();
      // Sauvegarder en cache (page 1 seulement)
      if (page == 1 && !kIsWeb) {
        await _db.sauvegarderArticles(
          articles.map((a) => a.toMap()).toList(),
          categorie: categorie,
        );
      }
      return articles;
    } on DioException catch (e) {
      debugPrint('[ArticleService] Erreur réseau, lecture cache: ${e.message}');
      if (!kIsWeb) {
        final cached = await _db.listerArticlesLocaux(categorie: categorie);
        if (cached.isNotEmpty) {
          return cached.map((m) => Article.fromMap(m)).toList();
        }
      }
      rethrow;
    }
  }

  Future<Article> detail(String id) async {
    try {
      final rep = await _dio.get('/articles/$id');
      final raw = Article.fromJson(rep.data);
      final article = raw.copyWith(image: _normaliserImage(raw.image));
      if (!kIsWeb) await _db.sauvegarderArticleDetail(article.toMap());
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
    final List<Article> articles = (rep.data as List)
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
    return articles.map((a) => a.copyWith(image: _normaliserImage(a.image))).toList();
  }

  Future<List<String>> listerCategories() async {
    try {
      final rep = await _dio.get('/articles/categories');
      return List<String>.from(rep.data);
    } catch (_) {
      return [];
    }
  }

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
    if (kIsWeb && !url.startsWith(_backendBase)) {
      return '$_backendBase/api/proxy-image?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
