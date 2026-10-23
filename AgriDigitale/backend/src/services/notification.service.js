const https = require('https');
const Utilisateur = require('../models/Utilisateur');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_API_KEY = process.env.ONESIGNAL_API_KEY;

// OneSignal n'accepte que des "subscription_id" au format UUID (v4).
// Un seul token au format différent (ancien token FCM brut, token tronqué)
// fait échouer TOUTE la requête en HTTP 400 → aucune notification ne part.
// On filtre donc les tokens avant l'envoi et on purge les invalides.
const UUID_SOUSCRIPTION =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const estUuidValide = (token) =>
  typeof token === 'string' && UUID_SOUSCRIPTION.test(token.trim());

// Conserve uniquement les tokens exploitables et supprime de la base
// les tokens corrompus / hérités de l'ancienne API FCM.
const filtrerTokensValides = async (utilisateurs) => {
  const valides = [];
  const invalides = [];

  for (const u of utilisateurs) {
    const token = (u.tokenFCM || '').trim();
    if (!token) continue;
    if (estUuidValide(token)) valides.push(token);
    else invalides.push({ _id: u._id, token });
  }

  if (invalides.length > 0) {
    try {
      await Utilisateur.updateMany(
        { _id: { $in: invalides.map((i) => i._id) } },
        { $unset: { tokenFCM: '' } }
      );
      console.log(
        `[OneSignal] ${invalides.length} token(s) invalide(s) purgé(s) de la base`
      );
    } catch (err) {
      console.error('[OneSignal] Purge des tokens invalides impossible :', err.message);
    }
  }

  return valides;
};

// Retire de la base les subscription_id que OneSignal signale comme
// invalides (app désinstallée, token expiré, réinscription).
const purgerTokensRejetes = async (tokensRejetes = []) => {
  if (!Array.isArray(tokensRejetes) || tokensRejetes.length === 0) return;
  try {
    const res = await Utilisateur.updateMany(
      { tokenFCM: { $in: tokensRejetes } },
      { $unset: { tokenFCM: '' } }
    );
    console.log(
      `[OneSignal] ${res.modifiedCount} subscription_id rejete(s) purge(s) de la base`
    );
  } catch (err) {
    console.error('[OneSignal] Purge des tokens rejetés impossible :', err.message);
  }
};

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
    res.on('end', () => {
      let body = {};
      try { body = JSON.parse(result); } catch (_) { body = { raw: result }; }
      resolve({ status: res.statusCode, body });
    });
  });
  req.on('error', reject);
  req.write(data);
  req.end();
});

const notifierNouvelArticle = async (article) => {
  try {
    // Cibler par tokens individuels si disponibles, sinon envoyer à tous les abonnés
    const utilisateurs = await Utilisateur.find({ tokenFCM: { $ne: null } }).select('tokenFCM');
    // Un token non-UUID fait échouer toute la requête (HTTP 400) : on filtre.
    const playerIds = await filtrerTokensValides(utilisateurs);

    // Pour maximiser la livraison en ARRIÈRE-PLAN (Android/iOS), on évite
    // big_picture/ios_attachments qui peuvent bloquer l'affichage quand l'app
    // est tuée. Les données (articleId) permettent l'ouverture au clic.
    const body = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: 'AgriDigitale — Nouvel article', fr: 'AgriDigitale — Nouvel article' },
      contents: { en: article.titre, fr: article.titre },
      data: { type: 'nouvel_article', articleId: article._id.toString(), categorie: article.categorie || '' },
      android_channel_id: 'agridigitale_channel',
      priority: 10,
      android_visibility: 1,
      content_available: true,
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      ttl: 259200,
      collapse_id: `article_${article._id.toString()}`,
    };

    // Envoyer à TOUS les abonnés OneSignal (segment All) est plus fiable
    // pour la livraison en arrière-plan que de cibler une liste de tokens.
    // On garde un ciblage réduit uniquement s'il y a peu de tokens valides.
    if (playerIds.length > 0 && playerIds.length <= 150) {
      body.include_subscription_ids = playerIds;
      console.log(`[OneSignal] Article ciblé par ${playerIds.length} subscription_id(s)`);
    } else {
      body.included_segments = ['All'];
      console.log(`[OneSignal] Article envoyé au segment All (tokens valides en base: ${playerIds.length})`);
    }

    const result = await _envoyerOneSignal(body);
    console.log(`[OneSignal] Article notifié — status: ${result.status}, mode: ${body.included_segments ? 'All' : 'ciblé'}`);

    // OneSignal peut répondre 200 tout en signalant des subscription_id invalides
    // (app désinstallée, réinscription) : on les purge pour ne plus les cibler.
    const rejetes = result.body?.errors?.invalid_player_ids;
    if (Array.isArray(rejetes) && rejetes.length > 0) {
      await purgerTokensRejetes(rejetes);
    }

    if (result.status >= 400) {
      console.error(
        `[OneSignal] Envoi en erreur (${result.status}) :`,
        JSON.stringify(result.body).substring(0, 300)
      );
    }
  } catch (err) {
    console.error('[OneSignal] Erreur notifierNouvelArticle :', err.message);
  }
};

const envoyerNotificationManuelle = async (titre, message, playerIds = []) => {
  // Même filtrage que pour les notifications d'articles : un token au mauvais
  // format ferait échouer l'envoi complet.
  const tokens = (playerIds || []).filter(estUuidValide);
  const rejets = (playerIds || []).filter((t) => t && !estUuidValide(t));

  if (rejets.length > 0) {
    console.log(`[OneSignal] ${rejets.length} token(s) manuel(s) au format invalide ignoré(s)`);
  }

  const body = {
    app_id: ONESIGNAL_APP_ID,
    headings: { en: titre, fr: titre },
    contents: { en: message, fr: message },
  };

  if (tokens.length > 0) {
    body.include_subscription_ids = tokens;
  } else {
    body.included_segments = ['All'];
  }

  const result = await _envoyerOneSignal(body);

  const rejetes = result.body?.errors?.invalid_player_ids;
  if (Array.isArray(rejets) && rejetes.length > 0) {
    await purgerTokensRejetes(rejets);
  }

  return result;
};

module.exports = { notifierNouvelArticle, envoyerNotificationManuelle };
