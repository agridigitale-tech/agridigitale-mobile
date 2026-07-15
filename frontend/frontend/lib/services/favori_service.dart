//permet de gérer les favoris (ajouter, retirer, lister) en utilisant l'API backend et un cache local SQLite pour le hors-ligne.

import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/api_client.dart';
import '../core/db_helper.dart';
import '../models/article.dart';

class FavoriService {
  final _dio = ApiClient().dio;
  final _db = DBHelper();

  Future<void> ajouter(Article article) async {
    await _dio.post('/favoris', data: {'articleId': article.id});
    await _db.sauvegarderFavori(article.toSqlite()); // copie locale pour le hors-ligne
  }

  Future<void> retirer(String articleId) async {
    await _dio.delete('/favoris/$articleId');
    await _db.supprimerFavori(articleId);
  }

  Future<List<Article>> lister() async {
    final connectivite = await Connectivity().checkConnectivity();
    if (connectivite.contains(ConnectivityResult.none)) {
      // hors-ligne : on lit le cache local SQLite
      final rows = await _db.listerFavorisLocaux();
      return rows.map((r) => Article.fromSqlite(r)).toList();
    }
    // en ligne : on lit le serveur (source de vérité) et on resynchronise le cache
    final rep = await _dio.get('/favoris');
    final articles = (rep.data as List).map((e) => Article.fromJson(e)).toList();
    for (final a in articles) {
      await _db.sauvegarderFavori(a.toSqlite());
    }
    return articles;
  }
}