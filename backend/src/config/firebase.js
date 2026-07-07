const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const serviceAccount = require('./firebase-service-account.json');

// Initialisation unique et sécurisée du SDK Firebase Admin
if (getApps().length === 0) {
  initializeApp({
    credential: cert(serviceAccount)
  });
}

// Nous exportons un objet personnalisé pour que votre code existant reste compatible
module.exports = {
  messaging: () => getMessaging()
};
