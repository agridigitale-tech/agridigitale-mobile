const https = require('https');
const Utilisateur = require('../models/Utilisateur');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_API_KEY = process.env.ONESIGNAL_API_KEY;

const _envoyerOneSignal = (body) => new Promise((resolve, reject) => {
  const data = JSON.stringify(body);
  const req = https.request({
    hostname: 'api.onesignal.com',
    path: '/notifications',
    method: 'POST',
    headers: {
      'Authorization': `Key ${ONESIGNAL_API_KEY}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data),
    },
  }, (res) => {
    let result = '';
    res.on('data', chunk => result += chunk);
    res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(result) }));
  });
  req.on('error', reject);
  req.write(data);
  req.end();
});

const notifierNouvelArticle = async (article) => {
  try {
    const utilisateurs = await Utilisateur.find({
      tokenFCM: { $ne: null },
      $or: [
        { preferencesRubriques: { $size: 0 } },
        { preferencesRubriques: { $in: [article.categorie] } },
      ],
    }).select('tokenFCM');

    const playerIds = utilisateurs.map(u => u.tokenFCM).filter(Boolean);
    if (playerIds.length === 0) return;

    const result = await _envoyerOneSignal({
      app_id: ONESIGNAL_APP_ID,
      include_subscription_ids: playerIds,
      headings: { en: 'AgriDigitale — Nouvel article', fr: 'AgriDigitale — Nouvel article' },
      contents: { en: article.titre, fr: article.titre },
      data: { type: 'nouvel_article', articleId: article._id.toString(), categorie: article.categorie || '' },
      android_channel_id: 'agridigitale_channel',
    });

    console.log(`[OneSignal] Article notifié à ${playerIds.length} utilisateur(s) — status: ${result.status}`);
  } catch (err) {
    console.error('[OneSignal] Erreur notifierNouvelArticle :', err.message);
  }
};

const envoyerNotificationManuelle = async (titre, message, playerIds) => {
  return _envoyerOneSignal({
    app_id: ONESIGNAL_APP_ID,
    include_subscription_ids: playerIds,
    headings: { en: titre, fr: titre },
    contents: { en: message, fr: message },
  });
};

module.exports = { notifierNouvelArticle, envoyerNotificationManuelle };
