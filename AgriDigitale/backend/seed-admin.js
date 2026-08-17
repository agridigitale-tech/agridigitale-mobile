/**
 * Script pour créer le premier administrateur.
 * Usage : node seed-admin.js
 * 
 * Lit les variables d'environnement depuis .env :
 *   MONGO_URI   — chaîne de connexion MongoDB
 *   ADMIN_EMAIL — email du admin à créer
 *   ADMIN_PASS  — mot de passe du admin
 *   ADMIN_NOM   — nom complet
 */

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const utilisateurSchema = new mongoose.Schema({
  nom:           { type: String, required: true, trim: true },
  email:         { type: String, required: true, unique: true, lowercase: true, trim: true },
  motDePasse:    { type: String, required: true, select: false },
  photo:         { type: String, default: null },
  role:          { type: String, enum: ['utilisateur', 'administrateur'], default: 'utilisateur' },
  preferencesRubriques: [{ type: String }],
  tokenFCM:      { type: String, default: null },
  theme:         { type: String, enum: ['clair', 'sombre'], default: 'clair' },
  langue:        { type: String, default: 'fr' },
  actif:         { type: Boolean, default: true },
  pays:          { type: String, default: '' },
  continent:     { type: String, default: '' },
}, { timestamps: true });

const Utilisateur = mongoose.model('Utilisateur', utilisateurSchema);

(async () => {
  try {
    const MONGO_URI   = process.env.MONGO_URI;
    const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
    const ADMIN_PASS  = process.env.ADMIN_PASS;
    const ADMIN_NOM   = process.env.ADMIN_NOM || 'Administrateur';

    if (!MONGO_URI || !ADMIN_EMAIL || !ADMIN_PASS) {
      console.error('Variables manquantes. Assure-toi que MONGO_URI, ADMIN_EMAIL et ADMIN_PASS sont dans ton .env');
      process.exit(1);
    }

    await mongoose.connect(MONGO_URI);
    console.log('Connecté à MongoDB');

    const existant = await Utilisateur.findOne({ email: ADMIN_EMAIL.toLowerCase() });
    if (existant) {
      if (existant.role === 'administrateur') {
        console.log(`Un admin existe déjà avec l'email ${ADMIN_EMAIL}. Rien à faire.`);
      } else {
        existant.role = 'administrateur';
        await existant.save();
        console.log(`L'utilisateur ${ADMIN_EMAIL} a été promu administrateur.`);
      }
      await mongoose.disconnect();
      process.exit(0);
    }

    const hash = await bcrypt.hash(ADMIN_PASS, 10);
    await Utilisateur.create({
      nom: ADMIN_NOM,
      email: ADMIN_EMAIL.toLowerCase(),
      motDePasse: hash,
      role: 'administrateur',
      actif: true,
    });

    console.log(`Administrateur créé : ${ADMIN_EMAIL}`);
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('Erreur :', err.message);
    process.exit(1);
  }
})();
