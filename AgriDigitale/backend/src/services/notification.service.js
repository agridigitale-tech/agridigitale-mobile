const admin = require('../config/firebase');
const Utilisateur = require('../models/Utilisateur');

const _nettoyerTokensInvalides = async (responses, tokens) => {
  const invalides = responses
    .map((r, i) => (!r.success && ['registration-token-not-registered', 'invalid-registration-token']
      .includes(r.error?.code?.replace('messaging/', '')) ? tokens[i] : null))
    .filter(Boolean);
  if (invalides.length > 0) {
    await Utilisateur.updateMany({ tokenFCM: { $in: invalides } }, { $unset: { tokenFCM: '' } });
  }
};

const _buildMessage = (tokens, notification, data) => ({
  tokens,
  notification,
  data,
  android: {
    priority: 'high',
    ttl: 86400000,
    notification: {
      channelId: 'agridigitale_channel',
      sound: 'default',
      defaultVibrateTimings: true,
      notificationPriority: 'PRIORITY_HIGH',
      visibility: 'PUBLIC',
    },
  },
  apns: {
    headers: { 'apns-priority': '10' },
    payload: { aps: { sound: 'default', badge: 1, contentAvailable: true } },
  },
});

// FCM only — la sauvegarde en base est faite par rss.service.js
const notifierNouvelArticle = async (article) => {
  try {
    const utilisateurs = await Utilisateur.find({
      tokenFCM: { $ne: null },
      $or: [
        { preferencesRubriques: { $size: 0 } },
        { preferencesRubriques: article.categorie },
      ],
    }).select('tokenFCM');

    const tokens = utilisateurs.map(u => u.tokenFCM).filter(Boolean);
    if (tokens.length === 0) return;

    const result = await admin.messaging().sendEachForMulticast(_buildMessage(
      tokens,
      { title: '🌱 AgriDigitale — Nouvel article', body: article.titre },
      { articleId: article._id.toString(), type: 'nouvel_article', categorie: article.categorie || '', click_action: 'FLUTTER_NOTIFICATION_CLICK' }
    ));

    await _nettoyerTokensInvalides(result.responses, tokens);
    console.log(`[FCM] Article notifié à ${tokens.length} utilisateur(s)`);
  } catch (err) {
    console.error('[FCM] Erreur notifierNouvelArticle :', err.message);
  }
};

const envoyerNotificationManuelle = async (titre, message, tokens) => {
  const result = await admin.messaging().sendEachForMulticast(_buildMessage(
    tokens,
    { title: titre, body: message },
    {}
  ));
  await _nettoyerTokensInvalides(result.responses, tokens);
};

module.exports = { notifierNouvelArticle, envoyerNotificationManuelle };
