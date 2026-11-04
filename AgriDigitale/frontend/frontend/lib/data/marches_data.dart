// Données et référentiel des cours des marchés agricoles locaux au Togo.
// Fonctionne 100% hors-ligne avec des relevés économiques représentatifs.

enum TendancePrix {
  hausse,
  baisse,
  stable,
}

class PrixProduit {
  final String produit;
  final String unite; // ex: "Bol (2.5 kg)", "Sac 100 kg", "Cagette", "Tas de 5"
  final int prixActuel; // En FCFA
  final int prixPrecedent; // En FCFA
  final TendancePrix tendance;
  final String icone;
  final List<int>? historiquePrix; // Évolution sur les dernières semaines pour mini-graphe

  const PrixProduit({
    required this.produit,
    required this.unite,
    required this.prixActuel,
    required this.prixPrecedent,
    required this.tendance,
    required this.icone,
    this.historiquePrix,
  });

  int get difference => prixActuel - prixPrecedent;

  double get pourcentageVariation {
    if (prixPrecedent == 0) return 0;
    return ((prixActuel - prixPrecedent) / prixPrecedent) * 100;
  }

  PrixProduit copyWith({
    String? produit,
    String? unite,
    int? prixActuel,
    int? prixPrecedent,
    TendancePrix? tendance,
    String? icone,
    List<int>? historiquePrix,
  }) {
    final actuel = prixActuel ?? this.prixActuel;
    final precedent = prixPrecedent ?? this.prixPrecedent;
    final t = tendance ??
        (actuel > precedent
            ? TendancePrix.hausse
            : (actuel < precedent ? TendancePrix.baisse : TendancePrix.stable));

    return PrixProduit(
      produit: produit ?? this.produit,
      unite: unite ?? this.unite,
      prixActuel: actuel,
      prixPrecedent: precedent,
      tendance: t,
      icone: icone ?? this.icone,
      historiquePrix: historiquePrix ?? this.historiquePrix,
    );
  }

  Map<String, dynamic> toJson() => {
        'produit': produit,
        'unite': unite,
        'prixActuel': prixActuel,
        'prixPrecedent': prixPrecedent,
        'tendance': tendance.name,
        'icone': icone,
        if (historiquePrix != null) 'historiquePrix': historiquePrix,
      };

  factory PrixProduit.fromJson(Map<String, dynamic> json) {
    final actuel = json['prixActuel'] as int? ?? 0;
    final precedent = json['prixPrecedent'] as int? ?? 0;

    TendancePrix t;
    if (json['tendance'] != null) {
      t = TendancePrix.values.firstWhere(
        (e) => e.name == json['tendance'],
        orElse: () => actuel > precedent
            ? TendancePrix.hausse
            : (actuel < precedent ? TendancePrix.baisse : TendancePrix.stable),
      );
    } else {
      t = actuel > precedent
          ? TendancePrix.hausse
          : (actuel < precedent ? TendancePrix.baisse : TendancePrix.stable);
    }

    return PrixProduit(
      produit: json['produit'] as String? ?? '',
      unite: json['unite'] as String? ?? 'Bol (2.5 kg)',
      prixActuel: actuel,
      prixPrecedent: precedent,
      tendance: t,
      icone: json['icone'] as String? ?? '🌾',
      historiquePrix: (json['historiquePrix'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

class MarcheAgricole {
  final String id;
  final String nom;
  final String ville;
  final String region;
  final List<PrixProduit> produits;

  const MarcheAgricole({
    required this.id,
    required this.nom,
    required this.ville,
    required this.region,
    required this.produits,
  });

  MarcheAgricole copyWith({
    String? id,
    String? nom,
    String? ville,
    String? region,
    List<PrixProduit>? produits,
  }) {
    return MarcheAgricole(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      ville: ville ?? this.ville,
      region: region ?? this.region,
      produits: produits ?? this.produits,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'ville': ville,
        'region': region,
        'produits': produits.map((p) => p.toJson()).toList(),
      };

  factory MarcheAgricole.fromJson(Map<String, dynamic> json) => MarcheAgricole(
        id: json['id'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        ville: json['ville'] as String? ?? '',
        region: json['region'] as String? ?? '',
        produits: (json['produits'] as List<dynamic>? ?? [])
            .map((p) => PrixProduit.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class MarchesData {
  static const List<MarcheAgricole> marches = [
    MarcheAgricole(
      id: 'lome',
      nom: 'Marché de Lomé',
      ville: 'Lomé',
      region: 'Maritime',
      produits: [
        PrixProduit(
          produit: 'Maïs',
          unite: 'Bol (2.5 kg)',
          prixActuel: 500,
          prixPrecedent: 500,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mais.jpg',
          historiquePrix: [500, 500, 520, 500, 500],
        ),
        PrixProduit(
          produit: 'Soja',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1050,
          prixPrecedent: 1050,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/soja.jpeg',
          historiquePrix: [1000, 1050, 1100, 1050, 1050],
        ),
        PrixProduit(
          produit: 'Haricot local',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1450,
          prixPrecedent: 1450,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/haricot.jpg',
          historiquePrix: [1400, 1450, 1450, 1450, 1450],
        ),
        PrixProduit(
          produit: 'Haricot (autres variétés)',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1650,
          prixPrecedent: 1650,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/haricot_grand_tail.jpg',
          historiquePrix: [1600, 1650, 1650, 1650, 1650],
        ),
        PrixProduit(
          produit: 'Sorgho',
          unite: 'Bol (2.5 kg)',
          prixActuel: 950,
          prixPrecedent: 950,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/sorgho.jpeg',
          historiquePrix: [950, 950, 950, 950, 950],
        ),
        PrixProduit(
          produit: 'Arachides',
          unite: 'Bol (2.5 kg)',
          prixActuel: 2000,
          prixPrecedent: 2000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/arachide.jpg',
          historiquePrix: [2000, 2000, 2000, 2000, 2000],
        ),
        PrixProduit(
          produit: 'Voandzou',
          unite: 'Bol (2.5 kg)',
          prixActuel: 2000,
          prixPrecedent: 2000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/voandzou.jpeg',
          historiquePrix: [2000, 2000, 2000, 2000, 2000],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'notse',
      nom: 'Marché de Notsè',
      ville: 'Notsè',
      region: 'Plateaux',
      produits: [
        PrixProduit(
          produit: 'Maïs',
          unite: 'Bol (2.5 kg)',
          prixActuel: 500,
          prixPrecedent: 500,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mais.jpg',
          historiquePrix: [500, 520, 500, 500, 500],
        ),
        PrixProduit(
          produit: 'Haricot',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1800,
          prixPrecedent: 1800,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/haricot.jpg',
          historiquePrix: [1750, 1800, 1800, 1800, 1800],
        ),
        PrixProduit(
          produit: 'Soja',
          unite: 'Bol (2.5 kg)',
          prixActuel: 900,
          prixPrecedent: 900,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/soja.jpeg',
          historiquePrix: [900, 900, 950, 900, 900],
        ),
        PrixProduit(
          produit: 'Mil',
          unite: 'Bol (2.5 kg)',
          prixActuel: 800,
          prixPrecedent: 800,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mil.webp',
          historiquePrix: [800, 800, 800, 800, 800],
        ),
        PrixProduit(
          produit: 'Sorgho',
          unite: 'Bol (2.5 kg)',
          prixActuel: 900,
          prixPrecedent: 900,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/sorgho.jpeg',
          historiquePrix: [900, 900, 900, 900, 900],
        ),
        PrixProduit(
          produit: 'Arachides',
          unite: 'Bol (2.5 kg)',
          prixActuel: 2000,
          prixPrecedent: 2000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/arachide.jpg',
          historiquePrix: [2000, 2000, 2000, 2000, 2000],
        ),
        PrixProduit(
          produit: 'Voandzou',
          unite: 'Bol (2.5 kg)',
          prixActuel: 2200,
          prixPrecedent: 2200,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/voandzou.jpeg',
          historiquePrix: [2200, 2200, 2200, 2200, 2200],
        ),
        PrixProduit(
          produit: 'Gari',
          unite: 'Bol (2.5 kg)',
          prixActuel: 600,
          prixPrecedent: 600,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/gari.jpg',
          historiquePrix: [600, 600, 650, 600, 600],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'kara',
      nom: 'Grand marché de Kara',
      ville: 'Kara',
      region: 'Kara',
      produits: [
        PrixProduit(
          produit: 'Maïs',
          unite: 'Bol (2.5 kg)',
          prixActuel: 400,
          prixPrecedent: 400,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mais.jpg',
          historiquePrix: [400, 420, 400, 400, 400],
        ),
        PrixProduit(
          produit: 'Sorgho',
          unite: 'Bol (2.5 kg)',
          prixActuel: 875,
          prixPrecedent: 875,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/sorgho.jpeg',
          historiquePrix: [850, 875, 900, 875, 875],
        ),
        PrixProduit(
          produit: 'Mil',
          unite: 'Bol (2.5 kg)',
          prixActuel: 650,
          prixPrecedent: 650,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mil.webp',
          historiquePrix: [650, 650, 680, 650, 650],
        ),
        PrixProduit(
          produit: 'Haricot',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1700,
          prixPrecedent: 1700,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/haricot.jpg',
          historiquePrix: [1700, 1700, 1700, 1700, 1700],
        ),
        PrixProduit(
          produit: 'Soja',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1250,
          prixPrecedent: 1250,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/soja.jpeg',
          historiquePrix: [1200, 1250, 1300, 1250, 1250],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'bafilo',
      nom: 'Marché de Bafilo',
      ville: 'Bafilo',
      region: 'Kara',
      produits: [
        PrixProduit(
          produit: 'Maïs',
          unite: 'Bol (2.5 kg)',
          prixActuel: 450,
          prixPrecedent: 450,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mais.jpg',
          historiquePrix: [450, 450, 480, 450, 450],
        ),
        PrixProduit(
          produit: 'Haricot de grande taille',
          unite: 'Bol (2.5 kg)',
          prixActuel: 2000,
          prixPrecedent: 2000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/haricot_grand_tail.jpg',
          historiquePrix: [2000, 2000, 2000, 2000, 2000],
        ),
        PrixProduit(
          produit: 'Soja',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1000,
          prixPrecedent: 1000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/soja.jpeg',
          historiquePrix: [1000, 1000, 1000, 1000, 1000],
        ),
        PrixProduit(
          produit: 'Sorgho',
          unite: 'Bol (2.5 kg)',
          prixActuel: 650,
          prixPrecedent: 650,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/sorgho.jpeg',
          historiquePrix: [650, 650, 650, 650, 650],
        ),
        PrixProduit(
          produit: 'Mil',
          unite: 'Bol (2.5 kg)',
          prixActuel: 500,
          prixPrecedent: 500,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mil.webp',
          historiquePrix: [500, 500, 500, 500, 500],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'mango',
      nom: 'Marché de Mango',
      ville: 'Mango',
      region: 'Savanes',
      produits: [
        PrixProduit(
          produit: 'Maïs',
          unite: 'Bol (2.5 kg)',
          prixActuel: 300,
          prixPrecedent: 300,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mais.jpg',
          historiquePrix: [300, 300, 320, 300, 300],
        ),
        PrixProduit(
          produit: 'Soja',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1000,
          prixPrecedent: 1000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/soja.jpeg',
          historiquePrix: [1000, 1000, 1000, 1000, 1000],
        ),
        PrixProduit(
          produit: 'Mil',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1000,
          prixPrecedent: 1000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/mil.webp',
          historiquePrix: [1000, 1000, 1000, 1000, 1000],
        ),
        PrixProduit(
          produit: 'Sorgho',
          unite: 'Bol (2.5 kg)',
          prixActuel: 900,
          prixPrecedent: 900,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/sorgho.jpeg',
          historiquePrix: [900, 900, 900, 900, 900],
        ),
        PrixProduit(
          produit: 'Haricot',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1500,
          prixPrecedent: 1500,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/haricot.jpg',
          historiquePrix: [1500, 1500, 1500, 1500, 1500],
        ),
        PrixProduit(
          produit: 'Arachides',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1800,
          prixPrecedent: 1800,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/arachide.jpg',
          historiquePrix: [1800, 1800, 1800, 1800, 1800],
        ),
        PrixProduit(
          produit: 'Voandzou',
          unite: 'Bol (2.5 kg)',
          prixActuel: 2000,
          prixPrecedent: 2000,
          tendance: TendancePrix.stable,
          icone: 'assets/images/cereales/voandzou.jpeg',
          historiquePrix: [2000, 2000, 2000, 2000, 2000],
        ),
      ],
    ),
  ];
}
