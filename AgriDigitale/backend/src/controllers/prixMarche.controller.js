const PrixMarche = require('../models/PrixMarche');
const Utilisateur = require('../models/Utilisateur');
const Notification = require('../models/Notification');
const { envoyerNotificationManuelle } = require('../services/notification.service');

// Données officielles de référence des marchés agricoles au Togo
const defaultMarchesTogo = [
  {
    id: 'cacaveli',
    nom: 'Marché de Cacaveli',
    ville: 'Lomé',
    region: 'Maritime',
    produits: [
      { produit: 'Maïs blanc', prixActuel: 800, prixPrecedent: 750, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [700, 720, 740, 750, 800] },
      { produit: 'Soja grain', prixActuel: 1100, prixPrecedent: 1150, unite: 'Bol (2,5 kg)', tendance: 'baisse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1250, 1200, 1180, 1150, 1100] },
      { produit: 'Tomate locale', prixActuel: 7500, prixPrecedent: 8500, unite: 'Panier (15 kg)', tendance: 'baisse', icone: 'assets/images/cereales/tomate.jpeg', historiquePrix: [9500, 9000, 8700, 8500, 7500] },
      { produit: 'Piment vert', prixActuel: 2000, prixPrecedent: 1800, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: 'assets/images/cereales/piment_frais.jpeg', historiquePrix: [1600, 1700, 1750, 1800, 2000] },
      { produit: 'Igname Laboco', prixActuel: 3500, prixPrecedent: 3500, unite: 'Tas de 5 tubercules', tendance: 'stable', icone: 'assets/images/cereales/igname.jpg', historiquePrix: [3500, 3400, 3600, 3500, 3500] },
      { produit: 'Haricot rouge', prixActuel: 1400, prixPrecedent: 1350, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: 'assets/images/cereales/haricot.jpg', historiquePrix: [1300, 1320, 1350, 1350, 1400] },
      { produit: 'Oignon rouge', prixActuel: 28000, prixPrecedent: 30000, unite: 'Sac de 50 kg', tendance: 'baisse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [32000, 31500, 31000, 30000, 28000] },
    ],
  },
  {
    id: 'notse',
    nom: 'Grand Marché de Notsè',
    ville: 'Notsè',
    region: 'Plateaux',
    produits: [
      { produit: 'Maïs blanc', prixActuel: 650, prixPrecedent: 650, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [650, 640, 660, 650, 650] },
      { produit: 'Soja grain', prixActuel: 950, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'baisse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1100, 1050, 1020, 1000, 950] },
      { produit: 'Manioc frais', prixActuel: 3000, prixPrecedent: 2800, unite: 'Cuvette (25 kg)', tendance: 'hausse', icone: 'assets/images/cereales/manioc.jpeg', historiquePrix: [2500, 2600, 2700, 2800, 3000] },
      { produit: 'Riz local étuvé', prixActuel: 1200, prixPrecedent: 1200, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [1200, 1180, 1220, 1200, 1200] },
    ],
  },
  {
    id: 'kpalime',
    nom: 'Marché Château de Kpalimé',
    ville: 'Kpalimé',
    region: 'Plateaux',
    produits: [
      { produit: 'Banane plantain', prixActuel: 2500, prixPrecedent: 2800, unite: 'Régime moyen', tendance: 'baisse', icone: 'assets/images/cereales/manioc.jpeg', historiquePrix: [3200, 3000, 2900, 2800, 2500] },
      { produit: 'Café vert décortiqué', prixActuel: 1600, prixPrecedent: 1500, unite: 'Kg', tendance: 'hausse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1400, 1450, 1480, 1500, 1600] },
      { produit: 'Cacao fèves séchées', prixActuel: 3200, prixPrecedent: 3000, unite: 'Kg', tendance: 'hausse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [2700, 2850, 2950, 3000, 3200] },
      { produit: 'Avocat', prixActuel: 1000, prixPrecedent: 1200, unite: 'Tas de 6 fruits', tendance: 'baisse', icone: 'assets/images/cereales/tomate.jpeg', historiquePrix: [1400, 1300, 1250, 1200, 1000] },
    ],
  },
  {
    id: 'kara',
    nom: 'Grand Marché de Kara',
    ville: 'Kara',
    region: 'Kara',
    produits: [
      { produit: 'Sorgho rouge', prixActuel: 900, prixPrecedent: 850, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [800, 820, 840, 850, 900] },
      { produit: 'Mil petit grain', prixActuel: 1000, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [1000, 980, 1020, 1000, 1000] },
      { produit: 'Igname douce', prixActuel: 2200, prixPrecedent: 2400, unite: 'Tas de 5', tendance: 'baisse', icone: 'assets/images/cereales/igname.jpg', historiquePrix: [2700, 2600, 2500, 2400, 2200] },
      { produit: 'Sésame blanc', prixActuel: 2500, prixPrecedent: 2300, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [2100, 2200, 2250, 2300, 2500] },
    ],
  },
  {
    id: 'dapaong',
    nom: 'Marché Central de Dapaong',
    ville: 'Dapaong',
    region: 'Savanes',
    produits: [
      { produit: 'Niébé / Haricot blanc', prixActuel: 1100, prixPrecedent: 1200, unite: 'Bol (2,5 kg)', tendance: 'baisse', icone: 'assets/images/cereales/haricot.jpg', historiquePrix: [1350, 1300, 1250, 1200, 1100] },
      { produit: 'Oignon Galmi', prixActuel: 24000, prixPrecedent: 26000, unite: 'Sac de 50 kg', tendance: 'baisse', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [29000, 28000, 27000, 26000, 24000] },
      { produit: 'Maïs jaune', prixActuel: 700, prixPrecedent: 650, unite: 'Bol (2,5 kg)', tendance: 'hausse', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [600, 620, 640, 650, 700] },
      { produit: 'Arachide en coque', prixActuel: 16500, prixPrecedent: 16500, unite: 'Sac de 50 kg', tendance: 'stable', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [16500, 16300, 16700, 16500, 16500] },
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

// ── CRUD MARCHÉS (Admin) ──

exports.creerMarche = async (req, res, next) => {
  try {
    const { id, nom, ville, region } = req.body;
    if (!nom || !ville) {
      return res.status(400).json({ message: 'Le nom et la ville sont obligatoires' });
    }
    const slugId = id || (nom.toLowerCase().replace(/[^a-z0-9]/g, '_') + '_' + Date.now().toString().slice(-4));
    const existant = await PrixMarche.findOne({ id: slugId });
    if (existant) {
      return res.status(400).json({ message: 'Un marché avec cet identifiant existe déjà' });
    }

    const marche = await PrixMarche.create({
      id: slugId,
      nom,
      ville,
      region: region || 'Maritime',
      produits: [],
    });

    return res.status(201).json({ message: 'Marché créé avec succès', marche });
  } catch (err) {
    next(err);
  }
};

exports.modifierMarche = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nom, ville, region } = req.body;
    const marche = await PrixMarche.findOne({ id });
    if (!marche) return res.status(404).json({ message: 'Marché introuvable' });

    if (nom) marche.nom = nom;
    if (ville) marche.ville = ville;
    if (region) marche.region = region;
    marche.dateMiseAJour = new Date();
    await marche.save();

    return res.status(200).json({ message: 'Marché modifié avec succès', marche });
  } catch (err) {
    next(err);
  }
};

exports.supprimerMarche = async (req, res, next) => {
  try {
    const { id } = req.params;
    const marche = await PrixMarche.findOneAndDelete({ id });
    if (!marche) return res.status(404).json({ message: 'Marché introuvable' });

    return res.status(200).json({ message: 'Marché supprimé avec succès' });
  } catch (err) {
    next(err);
  }
};

// ── CRUD PRODUITS & PRIX (Admin) ──

exports.updatePrixProduit = async (req, res, next) => {
  try {
    const { marcheId, produit } = req.body;
    if (!marcheId || !produit || !produit.produit) {
      return res.status(400).json({ message: 'Données produit ou marché manquantes' });
    }

    let marche = await PrixMarche.findOne({ id: marcheId });
    if (!marche) {
      const fallback = defaultMarchesTogo.find(m => m.id === marcheId);
      if (fallback) {
        marche = await PrixMarche.create(fallback);
      } else {
        return res.status(404).json({ message: 'Marché introuvable' });
      }
    }

    const indexProd = marche.produits.findIndex(p => p.produit === produit.produit);
    const pActuel = Number(produit.prixActuel);
    const pPrec = Number(produit.prixPrecedent ?? pActuel);
    const diff = pActuel - pPrec;

    if (indexProd !== -1) {
      marche.produits[indexProd] = {
        ...marche.produits[indexProd].toObject(),
        ...produit,
        prixActuel: pActuel,
        prixPrecedent: pPrec,
        dateMiseAJour: new Date(),
      };
    } else {
      marche.produits.push({
        ...produit,
        prixActuel: pActuel,
        prixPrecedent: pPrec,
        dateMiseAJour: new Date(),
      });
    }

    marche.dateMiseAJour = new Date();
    await marche.save();

    // ── NOTIFICATION PUSH DIRECTE À TOUS LES UTILISATEURS ──
    let notifTitre = '';
    let notifMessage = '';

    if (diff > 0) {
      notifTitre = `📈 Alerte Marché : Hausse du cours du ${produit.produit}`;
      notifMessage = `Le prix de "${produit.produit}" au ${marche.nom} (${marche.ville}) est passé à ${pActuel} FCFA (+${diff} F).`;
    } else if (diff < 0) {
      notifTitre = `📉 Alerte Marché : Baisse de prix sur le ${produit.produit}`;
      notifMessage = `Bonne nouvelle ! Le cours de "${produit.produit}" au ${marche.nom} (${marche.ville}) a baissé à ${pActuel} FCFA (${diff} F).`;
    } else if (indexProd === -1) {
      notifTitre = `🌾 Nouveau cours disponible : ${produit.produit}`;
      notifMessage = `La denrée "${produit.produit}" est désormais cotée au ${marche.nom} (${marche.ville}) à ${pActuel} FCFA / ${produit.unite || 'Bol'}.`;
    }

    if (notifTitre && notifMessage) {
      try {
        const tousUtilisateurs = await Utilisateur.find({}).select('tokenFCM _id');
        const notifDocs = tousUtilisateurs.map(u => ({
          titre: notifTitre,
          message: notifMessage,
          destinataire: u._id,
          lu: false,
        }));
        if (notifDocs.length > 0) {
          await Notification.insertMany(notifDocs);
        }
        const tokens = tousUtilisateurs.map(u => u.tokenFCM).filter(Boolean);
        await envoyerNotificationManuelle(notifTitre, notifMessage, tokens);
        console.log(`[PrixMarche] Notification push envoyée à tous les utilisateurs pour ${produit.produit}`);
      } catch (errNotif) {
        console.error('[PrixMarche] Erreur envoi notifications push:', errNotif.message);
      }
    }

    return res.status(200).json({
      message: 'Prix du produit mis à jour avec succès',
      marche,
    });
  } catch (error) {
    next(error);
  }
};

exports.supprimerProduit = async (req, res, next) => {
  try {
    const { marcheId, nomProduit } = req.params;
    const marche = await PrixMarche.findOne({ id: marcheId });
    if (!marche) return res.status(404).json({ message: 'Marché introuvable' });

    const decodedNom = decodeURIComponent(nomProduit);
    marche.produits = marche.produits.filter(p => p.produit !== decodedNom);
    marche.dateMiseAJour = new Date();
    await marche.save();

    return res.status(200).json({ message: 'Produit retiré du marché avec succès', marche });
  } catch (err) {
    next(err);
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
