// Script : remplace les marqueurs {{BASE_URL}} dans le contenu des
// articles existants pour que les images internes chargent correctement.
require('dotenv').config();
const Article = require('./src/models/Article');
const mongoose = require('mongoose');

async function main() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/agridigitale');
    console.log('Connecté à la base de données');

    const articles = await Article.find({ contenu: { $regex: /\{\{BASE_URL\}\}/ } });
    let corriges = 0;
    for (const a of articles) {
      const nouveau = a.contenu.replace(/\{\{BASE_URL\}\}/g, 'https://agridigitale.com');
      if (nouveau !== a.contenu) {
        await Article.updateOne({ _id: a._id }, { $set: { contenu: nouveau } });
        corriges++;
      }
    }
    console.log(`Article corrigés : ${corriges} / ${articles.length}`);
    process.exit(0);
  } catch (e) {
    console.error('Erreur:', e.message);
    process.exit(1);
  }
}

main();
