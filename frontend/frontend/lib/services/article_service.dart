//permet de gérer les articles (lister, détailler, rechercher) en utilisant l'API backend.
// Optimisé pour la performance avec cache et gestion d'erreur améliorée.

import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/article.dart';

class ArticleService {
  final _dio = ApiClient().dio;

  Future<List<Article>> lister({String? categorie, int page = 1, bool forceRefresh = false}) async {
    try {
      // Utilisation du cache avec option de rafraîchissement forcé
      final options = forceRefresh
          ? Options(extra: {'cache': {'forceRefresh': true}})
          : Options(extra: {'cache': {'maxAge': const Duration(minutes: 5), 'maxStale': const Duration(minutes: 10)}});

      final rep = await _dio.get(
        '/api/articles',
        queryParameters: {
          if (categorie != null) 'categorie': categorie,
          'page': page,
        },
        options: options,
      );
      return (rep.data as List).map((e) => Article.fromJson(e)).toList();
    } catch (e) {
      // En cas d'erreur, essayer de récupérer les données du cache
      try {
        final cachedRep = await _dio.get(
          '/api/articles',
          queryParameters: {
            if (categorie != null) 'categorie': categorie,
            'page': page,
          },
          options: Options(extra: {'cache': {'onlyCache': true}}),
        );
        return (cachedRep.data as List).map((e) => Article.fromJson(e)).toList();
      } catch (cacheError) {
        // Si aucune donnée en cache, retourner des données de test pour le développement
        return _getTestArticles();
      }
    }
  }

  // Méthode pour retourner des articles de test si le backend n'est pas disponible
  List<Article> _getTestArticles() {
    return [
      Article(
        id: '1',
        titre: 'Bienvenue sur AgriDigitale',
        resume: 'Ceci est un article de test. Le backend semble ne pas être disponible.',
        categorie: 'News',
        datePublication: DateTime.now(),
        image: 'https://via.placeholder.com/150',
      ),
      Article(
        id: '2',
        titre: 'Comment utiliser l\'application',
        resume: 'Appuyez sur le bouton de rafraîchissement pour recharger les données une fois le backend démarré.',
        categorie: 'Business',
        datePublication: DateTime.now().subtract(const Duration(days: 1)),
        image: 'https://via.placeholder.com/150',
      ),
    ];
  }

  Future<Article> detail(String id) async {
    try {
      final rep = await _dio.get('/api/articles/$id');
      return Article.fromJson(rep.data);
    } catch (e) {
      throw Exception('Impossible de charger les détails de l\'article');
    }
  }

  Future<List<Article>> rechercher(String motCle) async {
    try {
      final rep = await _dio.get(
        '/api/articles/recherche',
        queryParameters: {'motCle': motCle},
        options: Options(extra: {'cache': {'maxAge': const Duration(minutes: 1)}}),
      );
      return (rep.data as List).map((e) => Article.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Impossible de effectuer la recherche');
    }
  }
  
  // Méthode pour lister les catégories d'articles
  Future<List<String>> listerCategories() async {
  final rep = await _dio.get('/articles/categories');
  return List<String>.from(rep.data);
  }

  // Méthode pour vider le cache des articles
  Future<void> viderCache() async {
    await _dio.get(
      '/api/articles',
      options: Options(extra: {'cache': {'clean': true}}),
    );
  }
}
