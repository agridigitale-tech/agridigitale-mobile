const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

(async () => {
  try {
    const backupDir = path.join(__dirname, '../backup_data');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }

    console.log('Connexion à la base MongoDB actuelle...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connecté avec succès.');

    const collections = await mongoose.connection.db.listCollections().toArray();
    for (const c of collections) {
      const name = c.name;
      const docs = await mongoose.connection.db.collection(name).find({}).toArray();
      const filePath = path.join(backupDir, `${name}.json`);
      fs.writeFileSync(filePath, JSON.stringify(docs, null, 2), 'utf8');
      console.log(`✓ Collection ${name} exportée (${docs.length} documents) -> ${filePath}`);
    }

    console.log('\nSauvegarde terminée avec succès dans :', backupDir);
    process.exit(0);
  } catch (err) {
    console.error('Erreur lors de l\'exportation :', err);
    process.exit(1);
  }
})();
