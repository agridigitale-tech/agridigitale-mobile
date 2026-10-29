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

  const PrixProduit({
    required this.produit,
    required this.unite,
    required this.prixActuel,
    required this.prixPrecedent,
    required this.tendance,
    required this.icone,
  });

  int get difference => prixActuel - prixPrecedent;
  double get pourcentageVariation {
    if (prixPrecedent == 0) return 0;
    return ((prixActuel - prixPrecedent) / prixPrecedent) * 100;
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
}

class MarchesData {
  static const List<MarcheAgricole> marches = [
    MarcheAgricole(
      id: 'cacaveli',
      nom: 'Marché de Cacaveli',
      ville: 'Lomé',
      region: 'Maritime',
      produits: [
        PrixProduit(produit: 'Maïs blanc', unite: 'Bol (2.5 kg)', prixActuel: 750, prixPrecedent: 800, tendance: TendancePrix.baisse, icone: '🌽'),
        PrixProduit(produit: 'Soja grain', unite: 'Bol (2.5 kg)', prixActuel: 1100, prixPrecedent: 1050, tendance: TendancePrix.hausse, icone: '🌱'),
        PrixProduit(produit: 'Haricot (Niébé)', unite: 'Bol (2.5 kg)', prixActuel: 1500, prixPrecedent: 1500, tendance: TendancePrix.stable, icone: '🫘'),
        PrixProduit(produit: 'Gari blanc fin', unite: 'Bol (2.5 kg)', prixActuel: 900, prixPrecedent: 950, tendance: TendancePrix.baisse, icone: '🥣'),
        PrixProduit(produit: 'Tomate ronde', unite: 'Cagette', prixActuel: 18000, prixPrecedent: 15000, tendance: TendancePrix.hausse, icone: '🍅'),
        PrixProduit(produit: 'Piment frais', unite: 'Panier', prixActuel: 8500, prixPrecedent: 9000, tendance: TendancePrix.baisse, icone: '🌶️'),
      ],
    ),
    MarcheAgricole(
      id: 'notse',
      nom: 'Marché de Notsè',
      ville: 'Notsè',
      region: 'Plateaux',
      produits: [
        PrixProduit(produit: 'Maïs blanc', unite: 'Bol (2.5 kg)', prixActuel: 650, prixPrecedent: 700, tendance: TendancePrix.baisse, icone: '🌽'),
        PrixProduit(produit: 'Igname Laboco', unite: 'Tas de 5 gros', prixActuel: 4000, prixPrecedent: 3500, tendance: TendancePrix.hausse, icone: '🥔'),
        PrixProduit(produit: 'Soja grain', unite: 'Bol (2.5 kg)', prixActuel: 950, prixPrecedent: 900, tendance: TendancePrix.hausse, icone: '🌱'),
        PrixProduit(produit: 'Manioc frais', unite: 'Sac 50 kg', prixActuel: 7000, prixPrecedent: 7000, tendance: TendancePrix.stable, icone: '🍠'),
      ],
    ),
    MarcheAgricole(
      id: 'kpalime',
      nom: 'Grand Marché de Kpalimé',
      ville: 'Kpalimé',
      region: 'Plateaux',
      produits: [
        PrixProduit(produit: 'Maïs blanc', unite: 'Bol (2.5 kg)', prixActuel: 700, prixPrecedent: 750, tendance: TendancePrix.baisse, icone: '🌽'),
        PrixProduit(produit: 'Tomate de saison', unite: 'Cagette', prixActuel: 14000, prixPrecedent: 12000, tendance: TendancePrix.hausse, icone: '🍅'),
        PrixProduit(produit: 'Banane plantain', unite: 'Régime moyen', prixActuel: 2500, prixPrecedent: 2500, tendance: TendancePrix.stable, icone: '🍌'),
        PrixProduit(produit: 'Haricot (Niébé)', unite: 'Bol (2.5 kg)', prixActuel: 1400, prixPrecedent: 1350, tendance: TendancePrix.hausse, icone: '🫘'),
      ],
    ),
    MarcheAgricole(
      id: 'kara',
      nom: 'Marché Central de Kara',
      ville: 'Kara',
      region: 'Kara',
      produits: [
        PrixProduit(produit: 'Sorgho rouge', unite: 'Bol (2.5 kg)', prixActuel: 800, prixPrecedent: 850, tendance: TendancePrix.baisse, icone: '🌾'),
        PrixProduit(produit: 'Mil pénicillaire', unite: 'Bol (2.5 kg)', prixActuel: 850, prixPrecedent: 850, tendance: TendancePrix.stable, icone: '🌾'),
        PrixProduit(produit: 'Soja grain', unite: 'Sac 100 kg', prixActuel: 32000, prixPrecedent: 30000, tendance: TendancePrix.hausse, icone: '🌱'),
        PrixProduit(produit: 'Igname de Kara', unite: 'Tas de 5', prixActuel: 3000, prixPrecedent: 3000, tendance: TendancePrix.stable, icone: '🥔'),
      ],
    ),
    MarcheAgricole(
      id: 'dapaong',
      nom: 'Marché de Dapaong',
      ville: 'Dapaong',
      region: 'Savanes',
      produits: [
        PrixProduit(produit: 'Mil local', unite: 'Bol (2.5 kg)', prixActuel: 750, prixPrecedent: 800, tendance: TendancePrix.baisse, icone: '🌾'),
        PrixProduit(produit: 'Sorgho blanc', unite: 'Bol (2.5 kg)', prixActuel: 700, prixPrecedent: 700, tendance: TendancePrix.stable, icone: '🌾'),
        PrixProduit(produit: 'Oignon Galmi', unite: 'Sac 50 kg', prixActuel: 28000, prixPrecedent: 32000, tendance: TendancePrix.baisse, icone: '🧅'),
        PrixProduit(produit: 'Arachide décortiquée', unite: 'Bol (2.5 kg)', prixActuel: 1600, prixPrecedent: 1500, tendance: TendancePrix.hausse, icone: '🥜'),
      ],
    ),
  ];
}
