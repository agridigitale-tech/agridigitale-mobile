//permet de corriger le contenu des articles dans la base de données MongoDB
// Exécuter UNE SEULE FOIS depuis le dossier backend :
//   node fix_contenu.js
require('dotenv').config();
const mongoose = require('mongoose');
const { mettreAJourContenuArticles } = require('./src/services/rss.service');
require('dotenv').config();

console.log("MONGO_URI =", process.env.MONGO_URI);

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log('[DB] Connecté à MongoDB');
    await mettreAJourContenuArticles();
    await mongoose.disconnect();
    console.log('[DB] Terminé — relance le serveur backend');
    process.exit(0);
  })
  .catch((err) => {
    console.error('[DB] Erreur connexion:', err.message);
    process.exit(1);
  });
