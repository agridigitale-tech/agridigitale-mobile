// lib/models/article.dart
class Article {
  final String id;
  final String guid;
  final String titre;
  final String contenu;
  final String resume;
  final String? image;
  final String lienSource;
  final String categorie;
  final DateTime datePublication;
  final int vues;

  Article({
    required this.id,
    required this.guid,
    required this.titre,
    required this.contenu,
    required this.resume,
    this.image,
    required this.lienSource,
    required this.categorie,
    required this.datePublication,
    this.vues = 0,
  });

  // Convertit un JSON venant de notre API Node.js en objet Article
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'] ?? json['id'] ?? '',
      guid: json['guid'] ?? '',
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      resume: json['resume'] ?? '',
      image: json['image'],
      lienSource: json['lienSource'] ?? '',
      categorie: json['categorie'] ?? 'Général',
      datePublication: DateTime.parse(json['datePublication'] ?? DateTime.now().toIso8601String()),
      vues: json['vues'] ?? 0,
    );
  }

  // Convertit un objet Article en Map pour l'insérer dans SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guid': guid,
      'titre': titre,
      'contenu': contenu,
      'resume': resume,
      'image': image,
      'lienSource': lienSource,
      'categorie': categorie,
      'datePublication': datePublication.toIso8601String(),
      'vues': vues,
    };
  }

  // Convertit une ligne SQLite en objet Article
  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] ?? '',
      guid: map['guid'] ?? '',
      titre: map['titre'] ?? '',
      contenu: map['contenu'] ?? '',
      resume: map['resume'] ?? '',
      image: map['image'],
      lienSource: map['lienSource'] ?? '',
      categorie: map['categorie'] ?? 'Général',
      datePublication: DateTime.parse(map['datePublication'] ?? DateTime.now().toIso8601String()),
      vues: map['vues'] ?? 0,
    );
  }

  Article copyWith({String? image}) {
    return Article(
      id: id,
      guid: guid,
      titre: titre,
      contenu: contenu,
      resume: resume,
      image: image ?? this.image,
      lienSource: lienSource,
      categorie: categorie,
      datePublication: datePublication,
      vues: vues,
    );
  }

  Map<String, dynamic> toSqlite() => {
        'id': id,
        'titre': titre,
        'resume': resume,
        'image': image,
        'categorie': categorie,
        'datePublication': datePublication.toIso8601String(),
      };

  factory Article.fromSqlite(Map<String, dynamic> map) {
    return Article(
      id: map['id'] ?? '',
      guid: '',
      titre: map['titre'] ?? '',
      contenu: map['contenu'] ?? '',
      resume: map['resume'] ?? '',
      image: map['image'],
      lienSource: '',
      categorie: map['categorie'] ?? 'Général',
      datePublication: DateTime.tryParse(map['datePublication'] ?? '') ?? DateTime.now(),
      vues: 0,
    );
  }
}