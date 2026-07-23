import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/article.dart';

class ArticleService {
  final _dio = ApiClient().dio;

  static String get _backendBase => ApiClient.baseUrl.replaceAll('/api', '');

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
      final List<Article> articles = (rep.data as List)
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .toList();
      return articles.map((a) => a.copyWith(image: _normaliserImage(a.image))).toList();
    } on DioException catch (e) {
      debugPrint('[ArticleService] Erreur: ${e.message}');
      rethrow;
    }
  }

  Future<Article> detail(String id) async {
    final rep = await _dio.get('/articles/$id');
    final article = Article.fromJson(rep.data);
    return article.copyWith(image: _normaliserImage(article.image));
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
