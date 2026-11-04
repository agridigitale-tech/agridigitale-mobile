const PrixMarche = require('../models/PrixMarche');
const Utilisateur = require('../models/Utilisateur');
const Notification = require('../models/Notification');
const { envoyerNotificationManuelle } = require('../services/notification.service');

// Données officielles de référence des marchés agricoles au Togo
const defaultMarchesTogo = [
  {
    id: 'lome',
    nom: 'Marché de Lomé',
    ville: 'Lomé',
    region: 'Maritime',
    produits: [
      { produit: 'Maïs', prixActuel: 500, prixPrecedent: 500, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [500, 500, 520, 500, 500] },
      { produit: 'Soja', prixActuel: 1050, prixPrecedent: 1050, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1000, 1050, 1100, 1050, 1050] },
      { produit: 'Haricot local', prixActuel: 1450, prixPrecedent: 1450, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/haricot.jpg', historiquePrix: [1400, 1450, 1450, 1450, 1450] },
      { produit: 'Haricot (autres variétés)', prixActuel: 1650, prixPrecedent: 1650, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/haricot_grand_tail.jpg', historiquePrix: [1600, 1650, 1650, 1650, 1650] },
      { produit: 'Sorgho', prixActuel: 950, prixPrecedent: 950, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [950, 950, 950, 950, 950] },
      { produit: 'Arachides', prixActuel: 2000, prixPrecedent: 2000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/arachide.jpg', historiquePrix: [2000, 2000, 2000, 2000, 2000] },
      { produit: 'Voandzou', prixActuel: 2000, prixPrecedent: 2000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/voandzou.jpeg', historiquePrix: [2000, 2000, 2000, 2000, 2000] },
    ],
  },
  {
    id: 'notse',
    nom: 'Marché de Notsè',
    ville: 'Notsè',
    region: 'Plateaux',
    produits: [
      { produit: 'Maïs', prixActuel: 500, prixPrecedent: 500, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [500, 520, 500, 500, 500] },
      { produit: 'Haricot', prixActuel: 1800, prixPrecedent: 1800, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/haricot.jpg', historiquePrix: [1750, 1800, 1800, 1800, 1800] },
      { produit: 'Soja', prixActuel: 900, prixPrecedent: 900, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [900, 900, 950, 900, 900] },
      { produit: 'Mil', prixActuel: 800, prixPrecedent: 800, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mil.webp', historiquePrix: [800, 800, 800, 800, 800] },
      { produit: 'Sorgho', prixActuel: 900, prixPrecedent: 900, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [900, 900, 900, 900, 900] },
      { produit: 'Arachides', prixActuel: 2000, prixPrecedent: 2000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/arachide.jpg', historiquePrix: [2000, 2000, 2000, 2000, 2000] },
      { produit: 'Voandzou', prixActuel: 2200, prixPrecedent: 2200, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/voandzou.jpeg', historiquePrix: [2200, 2200, 2200, 2200, 2200] },
      { produit: 'Gari', prixActuel: 600, prixPrecedent: 600, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/gari.jpg', historiquePrix: [600, 600, 650, 600, 600] },
    ],
  },
  {
    id: 'kara',
    nom: 'Grand marché de Kara',
    ville: 'Kara',
    region: 'Kara',
    produits: [
      { produit: 'Maïs', prixActuel: 400, prixPrecedent: 400, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [400, 420, 400, 400, 400] },
      { produit: 'Sorgho', prixActuel: 875, prixPrecedent: 875, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [850, 875, 900, 875, 875] },
      { produit: 'Mil', prixActuel: 650, prixPrecedent: 650, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mil.webp', historiquePrix: [650, 650, 680, 650, 650] },
      { produit: 'Haricot', prixActuel: 1700, prixPrecedent: 1700, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/haricot.jpg', historiquePrix: [1700, 1700, 1700, 1700, 1700] },
      { produit: 'Soja', prixActuel: 1250, prixPrecedent: 1250, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1200, 1250, 1300, 1250, 1250] },
    ],
  },
  {
    id: 'bafilo',
    nom: 'Marché de Bafilo',
    ville: 'Bafilo',
    region: 'Kara',
    produits: [
      { produit: 'Maïs', prixActuel: 450, prixPrecedent: 450, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [450, 450, 480, 450, 450] },
      { produit: 'Haricot de grande taille', prixActuel: 2000, prixPrecedent: 2000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/haricot_grand_tail.jpg', historiquePrix: [2000, 2000, 2000, 2000, 2000] },
      { produit: 'Soja', prixActuel: 1000, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1000, 1000, 1000, 1000, 1000] },
      { produit: 'Sorgho', prixActuel: 650, prixPrecedent: 650, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [650, 650, 650, 650, 650] },
      { produit: 'Mil', prixActuel: 500, prixPrecedent: 500, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mil.webp', historiquePrix: [500, 500, 500, 500, 500] },
    ],
  },
  {
    id: 'mango',
    nom: 'Marché de Mango',
    ville: 'Mango',
    region: 'Savanes',
    produits: [
      { produit: 'Maïs', prixActuel: 300, prixPrecedent: 300, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mais.jpg', historiquePrix: [300, 300, 320, 300, 300] },
      { produit: 'Soja', prixActuel: 1000, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/soja.jpeg', historiquePrix: [1000, 1000, 1000, 1000, 1000] },
      { produit: 'Mil', prixActuel: 1000, prixPrecedent: 1000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/mil.webp', historiquePrix: [1000, 1000, 1000, 1000, 1000] },
      { produit: 'Sorgho', prixActuel: 900, prixPrecedent: 900, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/sorgho.jpeg', historiquePrix: [900, 900, 900, 900, 900] },
      { produit: 'Haricot', prixActuel: 1500, prixPrecedent: 1500, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/haricot.jpg', historiquePrix: [1500, 1500, 1500, 1500, 1500] },
      { produit: 'Arachides', prixActuel: 1800, prixPrecedent: 1800, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/arachide.jpg', historiquePrix: [1800, 1800, 1800, 1800, 1800] },
      { produit: 'Voandzou', prixActuel: 2000, prixPrecedent: 2000, unite: 'Bol (2,5 kg)', tendance: 'stable', icone: 'assets/images/cereales/voandzou.jpeg', historiquePrix: [2000, 2000, 2000, 2000, 2000] },
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

// Téléversement d'une image de produit depuis le téléphone
exports.uploadImageProduit = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Aucun fichier image fourni' });
    }
    const imageUrl = `/uploads/${req.file.filename}`;
    const baseUrl = process.env.BACKEND_URL || 'https://agridigitale-mobile.onrender.com';
    return res.status(200).json({
      message: 'Image téléversée avec succès',
      url: imageUrl,
      fullUrl: `${baseUrl}${imageUrl}`,
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
