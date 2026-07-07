//permet d'envoyer des notifications push aux utilisateurs via Firebase Cloud Messaging (FCM)

const admin = require('../config/firebase');
const Utilisateur = require('../models/Utilisateur');

const notifierNouvelArticle = async (article) => {
  try {
    // Ne notifie que les utilisateurs ayant choisi cette rubrique (ou qui n'ont pas de préférence = tous)
    const utilisateurs = await Utilisateur.find({
      tokenFCM: { $ne: null },
      $or: [
        { preferencesRubriques: { $size: 0 } },
        { preferencesRubriques: article.categorie },
      ],
    });

    const tokens = utilisateurs.map(u => u.tokenFCM).filter(Boolean);
    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: 'AgriDigitale',
        body: article.titre,
      },
      data: { articleId: article._id.toString(), type: 'nouvel_article' },
    });
    console.log(` Notification envoyée à ${tokens.length} utilisateur(s)`);
  } catch (err) {
    console.error(' Erreur notification :', err.message);
  }
};

const envoyerNotificationManuelle = async (titre, message, tokens) => {
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: titre, body: message },
  });
};

module.exports = { notifierNouvelArticle, envoyerNotificationManuelle };