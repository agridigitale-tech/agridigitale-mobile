const PrixMarche = require('../models/PrixMarche');

// Données officielles de référence des marchés agricoles au Togo
const defaultMarchesTogo = [
  {
    id: 'cacaveli',
    nom: 'Marché de Cacaveli',
    ville: 'Lomé',
    region: 'Maritime',
    produits: [
      { produit: 'Maïs blanc', prixActuel: 800, prixPrecedent: 750, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: '🌽', historiquePrix: [700, 720, 740, 750, 800] },
      { produit: 'Soja grain', prixActuel: 1100, prixPrecedent: 1150, unite: 'Bol (2,5 kg)', tendance: 'baisse', icone: '🌱', historiquePrix: [1250, 1200, 1180, 1150, 1100] },
      { produit: 'Tomate locale', prixActuel: 7500, prixPrecedent: 8500, unite: 'Panier (15 kg)', tendance: 'baisse', icone: '🍅', historiquePrix: [9500, 9000, 8700, 8500, 7500] },
      { produit: 'Piment vert', prixActuel: 2000, prixPrecedent: 1800, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: '🌶️', historiquePrix: [1600, 1700, 1750, 1800, 2000] },
      { produit: 'Igname Laboco', prixActuel: 3500, prixPrecedent: 3500, unite: 'Tas de 5 tubercules', tendance: 'stable', icone: '🥔', historiquePrix: [3500, 3400, 3600, 3500, 3500] },
      { produit: 'Haricot rouge', prixActuel: 1400, prixPrecedent: 1350, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: '🫘', historiquePrix: [1300, 1320, 1350, 1350, 1400] },
      { produit: 'Oignon rouge', prixActuel: 28000, prixPrecedent: 30000, unite: 'Sac de 50 kg', tendance: 'baisse', icone: '🧅', historiquePrix: [32000, 31500, 31000, 30000, 28000] },
    ],
  },
  {
    id: 'notse',
    nom: 'Grand Marché de Notsè',
    ville: 'Notsè',
    region: 'Plateaux',
    produits: [
      { produit: 'Maïs blanc', prixActuel: 650, prixPrecedent: 650, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: '🌽', historiquePrix: [650, 640, 660, 650, 650] },
      { produit: 'Soja grain', prixActuel: 950, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'baisse', icone: '🌱', historiquePrix: [1100, 1050, 1020, 1000, 950] },
      { produit: 'Manioc frais', prixActuel: 3000, prixPrecedent: 2800, unite: 'Cuvette (25 kg)', tendance: 'hausse', icone: '🥔', historiquePrix: [2500, 2600, 2700, 2800, 3000] },
      { produit: 'Riz local étuvé', prixActuel: 1200, prixPrecedent: 1200, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: '🌾', historiquePrix: [1200, 1180, 1220, 1200, 1200] },
    ],
  },
  {
    id: 'kpalime',
    nom: 'Marché Château de Kpalimé',
    ville: 'Kpalimé',
    region: 'Plateaux',
    produits: [
      { produit: 'Banane plantain', prixActuel: 2500, prixPrecedent: 2800, unite: 'Régime moyen', tendance: 'baisse', icone: '🍌', historiquePrix: [3200, 3000, 2900, 2800, 2500] },
      { produit: 'Café vert décortiqué', prixActuel: 1600, prixPrecedent: 1500, unite: 'Kg', tendance: 'hausse', icone: '☕', historiquePrix: [1400, 1450, 1480, 1500, 1600] },
      { produit: 'Cacao fèves séchées', prixActuel: 3200, prixPrecedent: 3000, unite: 'Kg', tendance: 'hausse', icone: '🍫', historiquePrix: [2700, 2850, 2950, 3000, 3200] },
      { produit: 'Avocat', prixActuel: 1000, prixPrecedent: 1200, unite: 'Tas de 6 fruits', tendance: 'baisse', icone: '🥑', historiquePrix: [1400, 1300, 1250, 1200, 1000] },
    ],
  },
  {
    id: 'kara',
    nom: 'Grand Marché de Kara',
    ville: 'Kara',
    region: 'Kara',
    produits: [
      { produit: 'Sorgho rouge', prixActuel: 900, prixPrecedent: 850, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: '🌾', historiquePrix: [800, 820, 840, 850, 900] },
      { produit: 'Mil petit grain', prixActuel: 1000, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: '🌾', historiquePrix: [1000, 980, 1020, 1000, 1000] },
      { produit: 'Igname douce', prixActuel: 2200, prixPrecedent: 2400, unite: 'Tas de 5', tendance: 'baisse', icone: '🥔', historiquePrix: [2700, 2600, 2500, 2400, 2200] },
      { produit: 'Sésame blanc', prixActuel: 2500, prixPrecedent: 2300, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: '🌱', historiquePrix: [2100, 2200, 2250, 2300, 2500] },
    ],
  },
  {
    id: 'dapaong',
    nom: 'Marché Central de Dapaong',
    ville: 'Dapaong',
    region: 'Savanes',
    produits: [
      { produit: 'Niébé / Haricot blanc', prixActuel: 1100, prixPrecedent: 1200, unite: 'Bol (2,5 kg)', tendance: 'baisse', icone: '🫘', historiquePrix: [1350, 1300, 1250, 1200, 1100] },
      { produit: 'Oignon Galmi', prixActuel: 24000, prixPrecedent: 26000, unite: 'Sac de 50 kg', tendance: 'baisse', icone: '🧅', historiquePrix: [29000, 28000, 27000, 26000, 24000] },
      { produit: 'Maïs jaune', prixActuel: 700, prixPrecedent: 650, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: '🌽', historiquePrix: [600, 620, 640, 650, 700] },
      { produit: 'Arachide en coque', prixActuel: 16500, prixPrecedent: 16500, unite: 'Sac de 50 kg', tendance: 'stable', icone: '🥜', historiquePrix: [16500, 16300, 16700, 16500, 16500] },
    ],
  },
];

// Consultation des marchés (publique)
exports.getMarches = async (req, res, next) => {
  try {
    let marches = await PrixMarche.find({}).sort({ nom: 1 });
    if (!marches || marches.length === 0) {
      // Auto-amorçage avec le référentiel officiel
      await PrixMarche.insertMany(defaultMarchesTogo);
      marches = await PrixMarche.find({}).sort({ nom: 1 });
    }
    return res.status(200).json(marches);
  } catch (error) {
    next(error);
  }
};

// Mise à jour du cours d'un produit dans un marché (admin)
exports.updatePrixProduit = async (req, res, next) => {
  try {
    const { marcheId, produit } = req.body;
    if (!marcheId || !produit || !produit.produit) {
      return res.status(400).json({ message: 'Données produit ou marché manquantes' });
    }

    let marche = await PrixMarche.findOne({ id: marcheId });
    if (!marche) {
      // Si la collection n'a pas encore ce marché, le créer depuis le référentiel
      const fallback = defaultMarchesTogo.find(m => m.id === marcheId);
      if (fallback) {
        marche = await PrixMarche.create(fallback);
      } else {
        return res.status(404).json({ message: 'Marché introuvable' });
      }
    }

    const indexProd = marche.produits.findIndex(p => p.produit === produit.produit);
    if (indexProd !== -1) {
      // Mise à jour
      marche.produits[indexProd] = {
        ...marche.produits[indexProd].toObject(),
        ...produit,
        dateMiseAJour: new Date(),
      };
    } else {
      // Ajout
      marche.produits.push({
        ...produit,
        dateMiseAJour: new Date(),
      });
    }

    marche.dateMiseAJour = new Date();
    await marche.save();

    return res.status(200).json({
      message: 'Prix du produit mis à jour avec succès',
      marche,
    });
  } catch (error) {
    next(error);
  }
};

// Réinitialisation aux valeurs d'origine (admin)
exports.resetToDefaults = async (req, res, next) => {
  try {
    await PrixMarche.deleteMany({});
    await PrixMarche.insertMany(defaultMarchesTogo);
    const marches = await PrixMarche.find({}).sort({ nom: 1 });
    return res.status(200).json({
      message: 'Tous les marchés ont été réinitialisés aux valeurs de référence',
      marches,
    });
  } catch (error) {
    next(error);
  }
};
