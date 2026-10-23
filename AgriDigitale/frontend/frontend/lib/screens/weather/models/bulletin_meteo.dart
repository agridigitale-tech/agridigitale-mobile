import 'dart:convert';

/// Modèle représentant un bulletin agro-météorologique complet
class RegionMeteo {
  final String code; // 'savanes', 'kara', 'centrale', 'plateaux', 'maritime'
  final String nom;
  final String chefLieu;
  final String condition;
  final String icone; // 'soleil', 'nuage', 'orage', 'pluie', 'eclaircie'
  final double tempMin;
  final double tempMax;
  final bool pluie;
  final String conseil;

  const RegionMeteo({
    required this.code,
    required this.nom,
    required this.chefLieu,
    required this.condition,
    required this.icone,
    required this.tempMin,
    required this.tempMax,
    this.pluie = false,
    this.conseil = '',
  });

  factory RegionMeteo.fromMap(Map<String, dynamic> map) {
    return RegionMeteo(
      code: map['code']?.toString().toLowerCase() ?? '',
      nom: map['nom']?.toString() ?? '',
      chefLieu: map['chefLieu']?.toString() ?? '',
      condition: map['condition']?.toString() ?? '',
      icone: map['icone']?.toString() ?? 'nuage',
      tempMin: (map['tempMin'] as num?)?.toDouble() ?? 24.0,
      tempMax: (map['tempMax'] as num?)?.toDouble() ?? 34.0,
      pluie: map['pluie'] == true,
      conseil: map['conseil']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nom': nom,
      'chefLieu': chefLieu,
      'condition': condition,
      'icone': icone,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'pluie': pluie,
      'conseil': conseil,
    };
  }
}

class BulletinMeteo {
  final String id;
  final DateTime date;
  final String titre;
  final String description;
  final String resumeMatin;
  final String resumeApresMidi;
  final String resumeNuit;
  final double tempMin;
  final double tempMax;
  final String conseilAgricole;
  final String imageUrl;
  final List<RegionMeteo> regions;

  const BulletinMeteo({
    required this.id,
    required this.date,
    required this.titre,
    required this.description,
    required this.resumeMatin,
    required this.resumeApresMidi,
    required this.resumeNuit,
    required this.tempMin,
    required this.tempMax,
    required this.conseilAgricole,
    required this.imageUrl,
    required this.regions,
  });

  /// Données de référence pour les 5 régions du Togo
  static List<RegionMeteo> get regionsParDefaut => const [
    RegionMeteo(
      code: 'savanes',
      nom: 'Savanes',
      chefLieu: 'Dapaong (Mango)',
      condition: 'Ciel dégagé, ensoleillé et très chaud',
      icone: 'soleil',
      tempMin: 24.0,
      tempMax: 37.0,
      pluie: false,
      conseil: 'Poursuite des récoltes et stockage par temps sec. Bonne ventilation nécessaire pour les greniers.',
    ),
    RegionMeteo(
      code: 'kara',
      nom: 'Kara',
      chefLieu: 'Kara (Bassar, Pagouda)',
      condition: 'Éclaircies larges avec passages nuageux',
      icone: 'eclaircie',
      tempMin: 23.0,
      tempMax: 36.0,
      pluie: false,
      conseil: 'Conditions propices aux labours légers et séchage des céréales et tubercules.',
    ),
    RegionMeteo(
      code: 'centrale',
      nom: 'Centrale',
      chefLieu: 'Sokodé (Tchamba, Sotouboua)',
      condition: 'Partiellement nuageux avec éclaircies',
      icone: 'nuage',
      tempMin: 22.0,
      tempMax: 35.0,
      pluie: false,
      conseil: 'Idéal pour le travail du sol. Surveillance de l\'humidité des semis.',
    ),
    RegionMeteo(
      code: 'plateaux',
      nom: 'Plateaux',
      chefLieu: 'Atakpamé (Kpalimé, Badou)',
      condition: 'Orages et pluies localisées l\'après-midi',
      icone: 'orage',
      tempMin: 21.0,
      tempMax: 32.0,
      pluie: true,
      conseil: 'Vigilance pour le café-cacao et séchage extérieur. Suspendre les traitements phytosanitaires l\'après-midi.',
    ),
    RegionMeteo(
      code: 'maritime',
      nom: 'Maritime',
      chefLieu: 'Lomé (Tsévié, Aného)',
      condition: 'Ciel nuageux le matin, averses orageuses locales l\'après-midi',
      icone: 'pluie',
      tempMin: 25.0,
      tempMax: 31.0,
      pluie: true,
      conseil: 'Attention aux averses orageuses en fin de journée pour les cultures maraîchères côtières.',
    ),
  ];

  factory BulletinMeteo.fromApiResponse(Map<String, dynamic> json, String urlImage) {
    final rawRegions = json['regions'];
    List<RegionMeteo> listRegions = [];
    if (rawRegions is List && rawRegions.isNotEmpty) {
      listRegions = rawRegions.map((r) => RegionMeteo.fromMap(r as Map<String, dynamic>)).toList();
    } else {
      listRegions = regionsParDefaut;
    }

    return BulletinMeteo(
      id: json['_id']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10),
      date: json['dateMiseAJour'] != null ? DateTime.tryParse(json['dateMiseAJour'].toString()) ?? DateTime.now() : DateTime.now(),
      titre: json['zone'] ?? 'Bulletin agro-météorologique officiel',
      description: json['description'] ?? 'Bulletin météo officiel',
      resumeMatin: json['resumeMatin'] ??
          'Au cours de cette matinée, on observe un ciel nuageux sur l\'ensemble du pays avec des brumes matinales locales.',
      resumeApresMidi: json['resumeApresMidi'] ??
          'Dans l\'après-midi, des orages associés à quelques pluies localisées sont attendus dans la Maritime et les Plateaux.',
      resumeNuit: json['resumeNuit'] ??
          'En soirée et nuit, accalmie progressive avec un ciel variable et des températures douces.',
      tempMin: (json['tempMin'] as num?)?.toDouble() ?? 30.0,
      tempMax: (json['tempMax'] as num?)?.toDouble() ?? 37.0,
      conseilAgricole: json['conseilAgricole'] ??
          'Maritime & Plateaux : Attention aux orages pour les traitements et séchages. Régions Nord : Temps chaud favorable aux récoltes.',
      imageUrl: urlImage,
      regions: listRegions,
    );
  }

  factory BulletinMeteo.fromDbRow(Map<String, dynamic> row) {
    List<RegionMeteo> listRegions = [];
    final jsonStr = row['regionsJson'] as String?;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List;
        listRegions = decoded.map((e) => RegionMeteo.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {
        listRegions = regionsParDefaut;
      }
    } else {
      listRegions = regionsParDefaut;
    }

    return BulletinMeteo(
      id: row['id']?.toString() ?? '',
      date: DateTime.tryParse(row['date']?.toString() ?? '') ?? DateTime.now(),
      titre: row['titre']?.toString() ?? 'Bulletin agro-météorologique',
      description: '',
      resumeMatin: row['resumeMatin']?.toString() ?? '',
      resumeApresMidi: row['resumeApresMidi']?.toString() ?? '',
      resumeNuit: 'Accalmie en soirée et durant la nuit.',
      tempMin: (row['tempMin'] as num?)?.toDouble() ?? 30.0,
      tempMax: (row['tempMax'] as num?)?.toDouble() ?? 37.0,
      conseilAgricole: row['conseilAgricole']?.toString() ?? '',
      imageUrl: row['imageUrl']?.toString() ?? '',
      regions: listRegions,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'titre': titre,
      'resumeMatin': resumeMatin,
      'resumeApresMidi': resumeApresMidi,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'conseilAgricole': conseilAgricole,
      'regionsJson': jsonEncode(regions.map((r) => r.toMap()).toList()),
      'imageUrl': imageUrl,
      'enregistreAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
