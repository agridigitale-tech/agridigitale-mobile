// Modèle Article : représente un article de presse venant du backend.
// Supporte 3 conversions : JSON (API) ↔ objet, Map (SQLite) ↔ objet.
class Article {
  final String id;
  final String guid;
  final String titre;
  final String contenu;
  final String resume;
  final String? image;
  final String legendeImage;
  final String auteur;
  final String lienSource;
  final String source;
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
    this.legendeImage = '',
    this.auteur = 'La Rédaction',
    required this.lienSource,
    this.source = 'AgriDigitale',
    required this.categorie,
    required this.datePublication,
    this.vues = 0,
  });

  // Convertit un JSON venant de notre API Node.js ou du flux en objet Article
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'] ?? json['id'] ?? '',
      guid: json['guid'] ?? '',
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      resume: json['resume'] ?? '',
      image: json['image'],
      legendeImage: json['legendeImage'] ?? json['legend'] ?? '',
      auteur: json['auteur'] ?? json['author'] ?? 'La Rédaction',
      lienSource: json['lienSource'] ?? '',
      source: json['source'] ?? 'AgriDigitale',
      categorie: json['categorie'] ?? 'Général',
      datePublication: DateTime.tryParse(json['datePublication'] ?? '') ?? DateTime.now(),
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
      'legendeImage': legendeImage,
      'auteur': auteur,
      'lienSource': lienSource,
      'source': source,
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
      legendeImage: map['legendeImage'] ?? '',
      auteur: map['auteur'] ?? 'La Rédaction',
      lienSource: map['lienSource'] ?? '',
      source: map['source'] ?? 'AgriDigitale',
      categorie: map['categorie'] ?? 'Général',
      datePublication: DateTime.tryParse(map['datePublication'] ?? '') ?? DateTime.now(),
      vues: map['vues'] ?? 0,
    );
  }

  Article copyWith({
    String? image,
    String? titre,
    String? contenu,
    String? resume,
    String? legendeImage,
    String? auteur,
  }) {
    return Article(
      id: id,
      guid: guid,
      titre: titre ?? this.titre,
      contenu: contenu ?? this.contenu,
      resume: resume ?? this.resume,
      image: image ?? this.image,
      legendeImage: legendeImage ?? this.legendeImage,
      auteur: auteur ?? this.auteur,
      lienSource: lienSource,
      source: source,
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
        'legendeImage': legendeImage,
        'auteur': auteur,
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
      legendeImage: map['legendeImage'] ?? '',
      auteur: map['auteur'] ?? 'La Rédaction',
      lienSource: '',
      categorie: map['categorie'] ?? 'Général',
      datePublication: DateTime.tryParse(map['datePublication'] ?? '') ?? DateTime.now(),
      vues: 0,
    );
  }
}