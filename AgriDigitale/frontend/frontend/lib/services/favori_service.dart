// Service favoris : ajoute/retire/liste les articles favoris.
// Sur mobile : synchronise avec SQLite pour un accès hors ligne.
// Sur web : uniquement via l'API (pas de SQLite).
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/api_client.dart';
import '../core/db_helper.dart';
import '../models/article.dart';

class FavoriService {
  final _dio = ApiClient().dio;
  final _db = DBHelper();

  static String get _backendBase => ApiClient.baseUrl.replaceAll('/api', '');

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

  Future<void> ajouter(Article article) async {
    await _dio.post('/favoris', data: {'articleId': article.id});
    if (!kIsWeb) {
      await _db.sauvegarderFavori(article.toSqlite());
    }
  }

  Future<void> retirer(String articleId) async {
    await _dio.delete('/favoris/$articleId');
    if (!kIsWeb) {
      await _db.supprimerFavori(articleId);
    }
  }

  // Vérifie si un article est en favori :
  // mobile → lecture SQLite locale | web → appel API
  Future<bool> estEnFavori(String articleId) async {
    try {
      if (!kIsWeb) {
        final local = await _db.listerFavorisLocaux();
        return local.any((r) => r['id'] == articleId);
      }
      final rep = await _dio.get('/favoris');
      final data = rep.data as List;
      return data.any((e) => e != null && (e['_id'] == articleId || e['id'] == articleId));
    } catch (_) {
      return false;
    }
  }

  Future<List<Article>> lister() async {
    if (!kIsWeb) {
      final connectivite = await Connectivity().checkConnectivity();
      if (connectivite.contains(ConnectivityResult.none)) {
        final rows = await _db.listerFavorisLocaux();
        return rows.map((r) => Article.fromSqlite(r)).toList();
      }
    }
    final rep = await _dio.get('/favoris');
    final data = rep.data as List;
    final articles = data
        .where((e) => e != null)
        .map((e) {
          final article = Article.fromJson(e as Map<String, dynamic>);
          return article.copyWith(image: _normaliserImage(article.image));
        })
        .toList();
    if (!kIsWeb) {
      for (final a in articles) {
        await _db.sauvegarderFavori(a.toSqlite());
      }
    }
    return articles;
  }
}
