// Modèle de télémétrie et d'analytics (temps d'écran, écrans visités et profilage)
const mongoose = require('mongoose');

const analyticsSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true,
  },
  utilisateurId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Utilisateur',
    default: null,
    index: true,
  },
  nomUtilisateur: {
    type: String,
    default: null,
  },
  emailUtilisateur: {
    type: String,
    default: null,
  },
  typeEvenement: {
    type: String,
    enum: [
      'article_lecture',
      'categorie_vue',
      'session',
      'app_open',
      'recherche',
      'ecran_vue',
      'presence_ping',
      'premiere_action',
    ],
    required: true,
    index: true,
  },
  ecran: {
    type: String, // 'home' | 'meteo' | 'tv' | 'jeux' | 'favoris' | 'parametres' | 'article' | 'autre'
    default: null,
    index: true,
  },
  premierEcran: {
    type: String, // Le premier écran visité à l'ouverture de l'application
    default: null,
  },
  articleId: {
    type: String,
    default: null,
    index: true,
  },
  titreArticle: {
    type: String,
    default: null,
  },
  categorie: {
    type: String,
    default: null,
    index: true,
  },
  dureeSecondes: {
    type: Number,
    default: 0,
  },
  pourcentageLecture: {
    type: Number,
    default: 0,
  },
  plateforme: {
    type: String,
    enum: ['android', 'ios', 'web', 'inconnu'],
    default: 'inconnu',
  },
  heureJour: {
    type: Number, // 0 à 23 (heure locale de l'appareil)
    default: null,
  },
  date: {
    type: Date,
    default: Date.now,
    index: true,
  },
}, { timestamps: true });

// Index composés pour des requêtes ultra-rapides sans surcharger le serveur
analyticsSchema.index({ categorie: 1, date: -1 });
analyticsSchema.index({ deviceId: 1, date: -1 });
analyticsSchema.index({ ecran: 1, date: -1 });
analyticsSchema.index({ typeEvenement: 1, date: -1 });
analyticsSchema.index({ date: -1 });
analyticsSchema.index({ deviceId: 1, typeEvenement: 1 });

module.exports = mongoose.model('Analytics', analyticsSchema);
