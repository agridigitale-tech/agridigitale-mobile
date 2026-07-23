const { envoyerNotificationManuelle } = require('../services/notification.service');
const Utilisateur = require('../models/Utilisateur');
const Notification = require('../models/Notification');

exports.envoyerManuelle = async (req, res, next) => {
  try {
    const { titre, message } = req.body;

    if (!titre || !message) {
      return res.status(400).json({ message: 'Le titre et le message sont obligatoires' });
    }

    // Récupérer TOUS les utilisateurs pour sauvegarder la notification en base
    const tousUtilisateurs = await Utilisateur.find({}).select('tokenFCM _id');

    // Sauvegarder la notification en base pour TOUS les utilisateurs
    const notifDocs = tousUtilisateurs.map(u => ({
      titre,
      message,
      destinataire: u._id,
      lu: false,
    }));
    if (notifDocs.length > 0) {
      await Notification.insertMany(notifDocs);
    }

    // Envoyer FCM uniquement aux utilisateurs avec un token
    const tokens = tousUtilisateurs.map(u => u.tokenFCM).filter(Boolean);
    if (tokens.length === 0) {
      return res.json({ success: true, message: `Notification sauvegardée pour ${tousUtilisateurs.length} utilisateur(s), aucun token FCM`, envoyes: 0 });
    }

    await envoyerNotificationManuelle(titre, message, tokens);

    res.json({
      success: true,
      message: `Notification envoyée à ${tokens.length} utilisateur(s)`,
      envoyes: tokens.length,
    });
  } catch (err) {
    next(err);
  }
};

// Compter les notifications non lues de l'utilisateur connecté
exports.getNonLues = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      destinataire: req.utilisateurId,
      lu: false,
    });
    res.json({ count });
  } catch (err) {
    next(err);
  }
};

// Lister toutes les notifications de l'utilisateur (lues + non lues)
exports.listerNotifications = async (req, res, next) => {
  try {
    const notifs = await Notification.find({ destinataire: req.utilisateurId })
      .sort({ createdAt: -1 })
      .limit(50);
    res.json(notifs);
  } catch (err) {
    next(err);
  }
};

// Marquer toutes les notifications de l'utilisateur comme lues
exports.marquerLues = async (req, res, next) => {
  try {
    await Notification.updateMany(
      { destinataire: req.utilisateurId, lu: false },
      { $set: { lu: true } }
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};
