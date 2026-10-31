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
      id: 'cacaveli',
      nom: 'Marché de Cacaveli',
      ville: 'Lomé',
      region: 'Maritime',
      produits: [
        PrixProduit(
          produit: 'Maïs blanc',
          unite: 'Bol (2.5 kg)',
          prixActuel: 750,
          prixPrecedent: 800,
          tendance: TendancePrix.baisse,
          icone: '🌽',
          historiquePrix: [850, 830, 820, 800, 750],
        ),
        PrixProduit(
          produit: 'Soja grain',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1100,
          prixPrecedent: 1050,
          tendance: TendancePrix.hausse,
          icone: '🌱',
          historiquePrix: [1000, 1020, 1040, 1050, 1100],
        ),
        PrixProduit(
          produit: 'Haricot (Niébé)',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1500,
          prixPrecedent: 1500,
          tendance: TendancePrix.stable,
          icone: '🫘',
          historiquePrix: [1500, 1500, 1520, 1500, 1500],
        ),
        PrixProduit(
          produit: 'Gari blanc fin',
          unite: 'Bol (2.5 kg)',
          prixActuel: 900,
          prixPrecedent: 950,
          tendance: TendancePrix.baisse,
          icone: '🥣',
          historiquePrix: [1000, 980, 960, 950, 900],
        ),
        PrixProduit(
          produit: 'Tomate ronde',
          unite: 'Cagette',
          prixActuel: 18000,
          prixPrecedent: 15000,
          tendance: TendancePrix.hausse,
          icone: '🍅',
          historiquePrix: [13000, 14000, 14500, 15000, 18000],
        ),
        PrixProduit(
          produit: 'Piment frais',
          unite: 'Panier',
          prixActuel: 8500,
          prixPrecedent: 9000,
          tendance: TendancePrix.baisse,
          icone: '🌶️',
          historiquePrix: [9500, 9300, 9200, 9000, 8500],
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
          produit: 'Maïs blanc',
          unite: 'Bol (2.5 kg)',
          prixActuel: 650,
          prixPrecedent: 700,
          tendance: TendancePrix.baisse,
          icone: '🌽',
          historiquePrix: [750, 720, 710, 700, 650],
        ),
        PrixProduit(
          produit: 'Igname Laboco',
          unite: 'Tas de 5 gros',
          prixActuel: 4000,
          prixPrecedent: 3500,
          tendance: TendancePrix.hausse,
          icone: '🥔',
          historiquePrix: [3000, 3200, 3400, 3500, 4000],
        ),
        PrixProduit(
          produit: 'Soja grain',
          unite: 'Bol (2.5 kg)',
          prixActuel: 950,
          prixPrecedent: 900,
          tendance: TendancePrix.hausse,
          icone: '🌱',
          historiquePrix: [850, 880, 890, 900, 950],
        ),
        PrixProduit(
          produit: 'Manioc frais',
          unite: 'Sac 50 kg',
          prixActuel: 7000,
          prixPrecedent: 7000,
          tendance: TendancePrix.stable,
          icone: '🍠',
          historiquePrix: [7000, 7100, 7000, 7000, 7000],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'kpalime',
      nom: 'Grand Marché de Kpalimé',
      ville: 'Kpalimé',
      region: 'Plateaux',
      produits: [
        PrixProduit(
          produit: 'Maïs blanc',
          unite: 'Bol (2.5 kg)',
          prixActuel: 700,
          prixPrecedent: 750,
          tendance: TendancePrix.baisse,
          icone: '🌽',
          historiquePrix: [800, 780, 760, 750, 700],
        ),
        PrixProduit(
          produit: 'Tomate de saison',
          unite: 'Cagette',
          prixActuel: 14000,
          prixPrecedent: 12000,
          tendance: TendancePrix.hausse,
          icone: '🍅',
          historiquePrix: [11000, 11500, 11800, 12000, 14000],
        ),
        PrixProduit(
          produit: 'Banane plantain',
          unite: 'Régime moyen',
          prixActuel: 2500,
          prixPrecedent: 2500,
          tendance: TendancePrix.stable,
          icone: '🍌',
          historiquePrix: [2500, 2600, 2500, 2500, 2500],
        ),
        PrixProduit(
          produit: 'Haricot (Niébé)',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1400,
          prixPrecedent: 1350,
          tendance: TendancePrix.hausse,
          icone: '🫘',
          historiquePrix: [1300, 1320, 1340, 1350, 1400],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'kara',
      nom: 'Marché Central de Kara',
      ville: 'Kara',
      region: 'Kara',
      produits: [
        PrixProduit(
          produit: 'Sorgho rouge',
          unite: 'Bol (2.5 kg)',
          prixActuel: 800,
          prixPrecedent: 850,
          tendance: TendancePrix.baisse,
          icone: '🌾',
          historiquePrix: [900, 880, 860, 850, 800],
        ),
        PrixProduit(
          produit: 'Mil pénicillaire',
          unite: 'Bol (2.5 kg)',
          prixActuel: 850,
          prixPrecedent: 850,
          tendance: TendancePrix.stable,
          icone: '🌾',
          historiquePrix: [850, 860, 850, 850, 850],
        ),
        PrixProduit(
          produit: 'Soja grain',
          unite: 'Sac 100 kg',
          prixActuel: 32000,
          prixPrecedent: 30000,
          tendance: TendancePrix.hausse,
          icone: '🌱',
          historiquePrix: [28000, 29000, 29500, 30000, 32000],
        ),
        PrixProduit(
          produit: 'Igname de Kara',
          unite: 'Tas de 5',
          prixActuel: 3000,
          prixPrecedent: 3000,
          tendance: TendancePrix.stable,
          icone: '🥔',
          historiquePrix: [3000, 3100, 3000, 3000, 3000],
        ),
      ],
    ),
    MarcheAgricole(
      id: 'dapaong',
      nom: 'Marché de Dapaong',
      ville: 'Dapaong',
      region: 'Savanes',
      produits: [
        PrixProduit(
          produit: 'Mil local',
          unite: 'Bol (2.5 kg)',
          prixActuel: 750,
          prixPrecedent: 800,
          tendance: TendancePrix.baisse,
          icone: '🌾',
          historiquePrix: [850, 820, 810, 800, 750],
        ),
        PrixProduit(
          produit: 'Sorgho blanc',
          unite: 'Bol (2.5 kg)',
          prixActuel: 700,
          prixPrecedent: 700,
          tendance: TendancePrix.stable,
          icone: '🌾',
          historiquePrix: [700, 720, 700, 700, 700],
        ),
        PrixProduit(
          produit: 'Oignon Galmi',
          unite: 'Sac 50 kg',
          prixActuel: 28000,
          prixPrecedent: 32000,
          tendance: TendancePrix.baisse,
          icone: '🧅',
          historiquePrix: [35000, 34000, 33000, 32000, 28000],
        ),
        PrixProduit(
          produit: 'Arachide décortiquée',
          unite: 'Bol (2.5 kg)',
          prixActuel: 1600,
          prixPrecedent: 1500,
          tendance: TendancePrix.hausse,
          icone: '🥜',
          historiquePrix: [1400, 1450, 1480, 1500, 1600],
        ),
      ],
    ),
  ];
}
