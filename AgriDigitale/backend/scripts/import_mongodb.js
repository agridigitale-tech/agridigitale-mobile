const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const targetUri = process.argv[2] || process.env.MONGO_URI;

function restaurerTypes(obj) {
  if (obj === null || obj === undefined) return obj;
  if (Array.isArray(obj)) return obj.map(restaurerTypes);
  if (typeof obj !== 'object') return obj;

  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      // 1. Conversion des ObjectIds
      const isIdField = key === '_id' || key === 'article' || key === 'auteur' || key === 'utilisateur';
      if (isIdField && /^[0-9a-fA-F]{24}$/.test(value)) {
        result[key] = new mongoose.Types.ObjectId(value);
        continue;
      }
      // 2. Conversion des Dates ISO
      if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(value)) {
        const d = new Date(value);
        if (!isNaN(d.getTime())) {
          result[key] = d;
          continue;
        }
      }
      result[key] = value;
    } else if (typeof value === 'object') {
      result[key] = restaurerTypes(value);
    } else {
      result[key] = value;
    }
  }
  return result;
}

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
      const rawDocs = JSON.parse(content);

      if (rawDocs.length === 0) {
        console.log(`- Collection ${collectionName} : aucun document.`);
        continue;
      }

      const docs = rawDocs.map(restaurerTypes);
      const col = mongoose.connection.db.collection(collectionName);
      
      // Vider avant insertion pour éviter les conflits d'index unique
      await col.deleteMany({});
      
      // Insertion par batch de 500
      for (let i = 0; i < docs.length; i += 500) {
        const batch = docs.slice(i, i + 500);
        await col.insertMany(batch);
      }
      console.log(`✓ Collection ${collectionName} : ${docs.length} document(s) importé(s)`);
    }

    console.log('\nMigration des données terminée avec succès sur le nouveau cluster !');
    process.exit(0);
  } catch (err) {
    console.error('Erreur lors de l\'importation :', err);
    process.exit(1);
  }
})();
