// Modèle de télémétrie et d'analytics (temps d'écran et intérêts par appareil)
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
  },
  typeEvenement: {
    type: String,
    enum: ['article_lecture', 'categorie_vue', 'session', 'app_open', 'recherche'],
    required: true,
    index: true,
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
  date: {
    type: Date,
    default: Date.now,
    index: true,
  },
}, { timestamps: true });

// Index composés pour des agrégations ultra-rapides sans charger le CPU de Render
analyticsSchema.index({ categorie: 1, date: -1 });
analyticsSchema.index({ deviceId: 1, date: -1 });
analyticsSchema.index({ typeEvenement: 1, date: -1 });
analyticsSchema.index({ date: -1 });
analyticsSchema.index({ deviceId: 1, typeEvenement: 1 });

module.exports = mongoose.model('Analytics', analyticsSchema);
