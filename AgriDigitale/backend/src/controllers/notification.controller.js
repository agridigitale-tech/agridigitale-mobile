const { envoyerNotificationManuelle } = require('../services/notification.service');
const Utilisateur = require('../models/Utilisateur');
const Notification = require('../models/Notification');

// Enregistrer le token OneSignal de l'utilisateur
exports.enregistrerToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ message: 'Token manquant' });
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: token });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

exports.envoyerManuelle = async (req, res, next) => {
  try {
    const { titre, message } = req.body;

    if (!titre || !message) {
      return res.status(400).json({ message: 'Le titre et le message sont obligatoires' });
    }

    const tousUtilisateurs = await Utilisateur.find({}).select('tokenFCM _id');

    const notifDocs = tousUtilisateurs.map(u => ({
      titre,
      message,
      destinataire: u._id,
      lu: false,
    }));
    if (notifDocs.length > 0) {
      await Notification.insertMany(notifDocs);
    }

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

exports.listerNotifications = async (req, res, next) => {
  try {
    const notifs = await Notification.find({ destinataire: req.utilisateurId })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    const result = notifs.map(n => ({
      ...n,
      articleId: n.article ? n.article.toString() : null,
    }));
    res.json(result);
  } catch (err) {
    next(err);
  }
};

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
