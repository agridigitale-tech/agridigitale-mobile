//permet de représenter un article (pour la liste des articles et le détail d'un article)

class Article {
  final String id, titre, resume, categorie;
  final String? image, contenu, lienSource;
  final DateTime datePublication;

  Article({
    required this.id, required this.titre, required this.resume,
    required this.categorie, this.image, this.contenu, this.lienSource,
    required this.datePublication,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['_id'],
    titre: json['titre'],
    resume: json['resume'] ?? '',
    categorie: json['categorie'] ?? 'Non classé',
    image: json['image'],
    contenu: json['contenu'],
    lienSource: json['lienSource'],
    datePublication: DateTime.parse(json['datePublication']),
  );

  // pour le cache SQLite (voir db_helper.dart)
  Map<String, dynamic> toSqlite() => {
    'id': id, 'titre': titre, 'resume': resume,
    'image': image, 'categorie': categorie,
    'datePublication': datePublication.toIso8601String(),
  };
  factory Article.fromSqlite(Map<String, dynamic> row) => Article(
    id: row['id'], titre: row['titre'], resume: row['resume'],
    categorie: row['categorie'], image: row['image'],
    datePublication: DateTime.parse(row['datePublication']),
  );
}