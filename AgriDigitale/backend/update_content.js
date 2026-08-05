// Script pour mettre à jour manuellement le contenu des articles existants
const { mettreAJourContenuArticles } = require('./src/services/rss.service');
const mongoose = require('mongoose');

async function main() {
  try {
    // Se connecter à la base de données
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/agridigitale');
    console.log('Connecté à la base de données');

    // Exécuter la mise à jour du contenu
    await mettreAJourContenuArticles();

    console.log('Mise à jour terminée');
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors de la mise à jour:', error);
    process.exit(1);
  }
}

main();