import '../core/api_client.dart';

class Commentaire {
  final String id;
  final String nomAuteur;
  final String contenu;
  final DateTime createdAt;

  Commentaire({
    required this.id,
    required this.nomAuteur,
    required this.contenu,
    required this.createdAt,
  });

  factory Commentaire.fromJson(Map<String, dynamic> json) => Commentaire(
        id: json['_id'] ?? '',
        nomAuteur: json['nomAuteur'] ?? 'Anonyme',
        contenu: json['contenu'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class CommentaireService {
  final _dio = ApiClient().dio;

  Future<List<Commentaire>> lister(String articleId) async {
    final rep = await _dio.get('/articles/$articleId/commentaires');
    return (rep.data as List).map((e) => Commentaire.fromJson(e)).toList();
  }

  Future<Commentaire> ajouter(String articleId, String contenu) async {
    final rep = await _dio.post(
      '/articles/$articleId/commentaires',
      data: {'contenu': contenu},
    );
    return Commentaire.fromJson(rep.data);
  }

  Future<void> supprimer(String articleId, String commentaireId) async {
    await _dio.delete('/articles/$articleId/commentaires/$commentaireId');
  }
}
