/**
 * Script de test notification push FCM
 * Usage : node test_notif.js
 */
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const serviceAccount = require('./src/config/firebase-service-account.json');

console.log('project_id utilise:', serviceAccount.project_id);

// ⚠️ Mettre à jour ce token depuis MongoDB avant chaque test
const FCM_TOKEN = 'cXGDJDSjSPqOAUKhe7yBqx:APA91bGBjD_Fn0QThmyiLfr3dyET6UvY9PdY-uGX4CrO8GkdZAcYyw_h8x47iGVX8tazD5ibTm2lIgcbDaUaRka-Av8NgKa-Ip_L4XiuuDmAlpNfsG3H8mU';
const ARTICLE_ID = '6ab7ec034254fdc6401b6059';

if (getApps().length === 0) {
  initializeApp({ credential: cert(serviceAccount) });
}

async function testerNotification(scenario) {
  console.log(`\n Envoi notification - Scenario : ${scenario}`);
  try {
    const result = await getMessaging().send({
      token: FCM_TOKEN,
      notification: {
        title: `AgriDigitale — Nouvel article [${scenario}]`,
        body: 'Test push : Cliquez pour ouvrir l\'article',
      },
      data: {
        type: 'nouvel_article',
        articleId: ARTICLE_ID,
        categorie: 'Général',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
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
    console.log('Notification envoyée avec succès !');
    console.log('   Message ID :', result);
  } catch (err) {
    console.error('Erreur :', err.message);
    if (err.code) console.error('   Code FCM :', err.code);
  }
}

// Lance le test
testerNotification(process.argv[2] || 'TEST');
