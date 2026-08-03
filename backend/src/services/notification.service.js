//permet d'envoyer des notifications push aux utilisateurs via Firebase Cloud Messaging (FCM)

const admin = require('../config/firebase');
const Utilisateur = require('../models/Utilisateur');

const notifierNouvelArticle = async (article) => {
  try {
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
        title: '\uD83C\uDF31 AgriDigitale — Nouvel article',
        body: article.titre,
      },
      data: {
        articleId: article._id.toString(),
        type: 'nouvel_article',
        categorie: article.categorie || '',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'agridigitale_channel',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
    console.log(`[FCM] Notification envoyée à ${tokens.length} utilisateur(s)`);
  } catch (err) {
    console.error('[FCM] Erreur notification :', err.message);
  }
};

const envoyerNotificationManuelle = async (titre, message, tokens) => {
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: titre, body: message },
    android: {
      priority: 'high',
      notification: {
        channelId: 'agridigitale_channel',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
  });
};

module.exports = { notifierNouvelArticle, envoyerNotificationManuelle };