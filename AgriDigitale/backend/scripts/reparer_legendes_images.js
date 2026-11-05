// Script de réparation et synchronisation des légendes d'images pour tous les articles
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const Article = require('../src/models/Article');
const { scrapeContenuInertia } = require('../src/services/rss.service');

async function reparerLegendes() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connecté à MongoDB.');

    // Articles sans légende ou avec légende vide / générique
    const articles = await Article.find({
      $or: [
        { legendeImage: null },
        { legendeImage: { $exists: false } },
        { legendeImage: '' },
        { legendeImage: 'Photo : © agridigitale.net' },
        { legendeImage: 'Photo : agridigitale.net' },
      ],
      lienSource: { $exists: true, $ne: '' },
    }).sort({ datePublication: -1 });

    console.log(`Trouvé ${articles.length} articles à réparer.`);

    let succes = 0;
    let sansLegende = 0;
    let erreurs = 0;

    // Traitement par lots de 5 pour aller vite sans surcharger agridigitale.net
    const batchSize = 5;
    for (let i = 0; i < articles.length; i += batchSize) {
      const batch = articles.slice(i, i + batchSize);
      await Promise.all(
        batch.map(async (art) => {
          try {
            const scrapeRes = await scrapeContenuInertia(art.lienSource);
            if (scrapeRes && scrapeRes.legende && scrapeRes.legende.trim().length > 0) {
              const updates = { legendeImage: scrapeRes.legende.trim() };
              if (scrapeRes.contenu && scrapeRes.contenu.length > (art.contenu || '').length) {
                updates.contenu = scrapeRes.contenu;
              }
              await Article.updateOne({ _id: art._id }, { $set: updates });
              succes++;
              console.log(`[✓ ${succes}] ${art.titre.slice(0, 45)}... -> "${scrapeRes.legende.slice(0, 50)}..."`);
            } else {
              sansLegende++;
            }
          } catch (err) {
            erreurs++;
            console.warn(`[✗] Erreur ${art.titre.slice(0, 30)}: ${err.message}`);
          }
        })
      );
      // Petite pause de 100ms entre les lots
      await new Promise((r) => setTimeout(r, 100));
    }

    console.log('\n--- RAPPORT FINAL ---');
    console.log(`Articles mis à jour avec succès : ${succes}`);
    console.log(`Articles sans légende sur le site : ${sansLegende}`);
    console.log(`Erreurs réseau : ${erreurs}`);

    process.exit(0);
  } catch (err) {
    console.error('Erreur globale:', err);
    process.exit(1);
  }
}

reparerLegendes();
