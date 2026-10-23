const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Accepte un URI en argument ou utilise process.env.MONGO_URI
const targetUri = process.argv[2] || process.env.MONGO_URI;

(async () => {
  try {
    const backupDir = path.join(__dirname, '../backup_data');
    if (!fs.existsSync(backupDir)) {
      console.error('Dossier de sauvegarde inexistant :', backupDir);
      process.exit(1);
    }

    console.log('Connexion à la base MongoDB cible :', targetUri.replace(/:([^:@]+)@/, ':****@'));
    await mongoose.connect(targetUri);
    console.log('Connecté avec succès.');

    const files = fs.readdirSync(backupDir).filter(f => f.endsWith('.json'));
    for (const f of files) {
      const collectionName = path.basename(f, '.json');
      const content = fs.readFileSync(path.join(backupDir, f), 'utf8');
      const docs = JSON.parse(content);

      if (docs.length === 0) {
        console.log(`- Collection ${collectionName} : aucun document à importer.`);
        continue;
      }

      const col = mongoose.connection.db.collection(collectionName);
      
      // Nettoie la collection avant réimport pour éviter les doublons
      await col.deleteMany({});
      
      // Réinsère par paquets de 500 pour optimiser la mémoire
      for (let i = 0; i < docs.length; i += 500) {
        const batch = docs.slice(i, i + 500);
        await col.insertMany(batch);
      }
      console.log(`✓ Collection ${collectionName} : ${docs.length} document(s) importé(s)`);
    }

    console.log('\nMigration des données terminée avec succès !');
    process.exit(0);
  } catch (err) {
    console.error('Erreur lors de l\'importation :', err);
    process.exit(1);
  }
})();
