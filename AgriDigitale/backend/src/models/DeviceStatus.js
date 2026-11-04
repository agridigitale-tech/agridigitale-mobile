// Modèle d'état et profilage d'appareil en temps réel
// Permet de connaître instantanément qui est en ligne, sur quel écran,
// le temps passé par menu (Home, Météo, TV, Jeux), et les heures d'activité.
const mongoose = require('mongoose');

const deviceStatusSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    unique: true,
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
  plateforme: {
    type: String,
    enum: ['android', 'ios', 'web', 'inconnu'],
    default: 'inconnu',
  },
  ecranActif: {
    type: String,
    default: 'home', // 'home', 'meteo', 'tv', 'jeux', 'favoris', 'parametres', 'article', 'autre'
  },
  derniereActivite: {
    type: Date,
    default: Date.now,
    index: true,
  },
  premiereActivite: {
    type: Date,
    default: Date.now,
  },
  nombreOuvertures: {
    type: Number,
    default: 0,
  },
  tempsTotalSecondes: {
    type: Number,
    default: 0,
  },
  // Temps passé par écran / menu (en secondes cumulées)
  tempsParEcran: {
    home: { type: Number, default: 0 },
    meteo: { type: Number, default: 0 },
    tv: { type: Number, default: 0 },
    jeux: { type: Number, default: 0 },
    favoris: { type: Number, default: 0 },
    parametres: { type: Number, default: 0 },
    article: { type: Number, default: 0 },
    autre: { type: Number, default: 0 },
  },
  // Compteurs des premières actions réalisées à l'ouverture
  premieresActions: {
    home: { type: Number, default: 0 },
    meteo: { type: Number, default: 0 },
    tv: { type: Number, default: 0 },
    jeux: { type: Number, default: 0 },
    favoris: { type: Number, default: 0 },
    parametres: { type: Number, default: 0 },
    article: { type: Number, default: 0 },
    autre: { type: Number, default: 0 },
  },
  // Compteurs d'activité par heure de la journée (h0 à h23)
  heuresUtilisation: {
    h0: { type: Number, default: 0 },
    h1: { type: Number, default: 0 },
    h2: { type: Number, default: 0 },
    h3: { type: Number, default: 0 },
    h4: { type: Number, default: 0 },
    h5: { type: Number, default: 0 },
    h6: { type: Number, default: 0 },
    h7: { type: Number, default: 0 },
    h8: { type: Number, default: 0 },
    h9: { type: Number, default: 0 },
    h10: { type: Number, default: 0 },
    h11: { type: Number, default: 0 },
    h12: { type: Number, default: 0 },
    h13: { type: Number, default: 0 },
    h14: { type: Number, default: 0 },
    h15: { type: Number, default: 0 },
    h16: { type: Number, default: 0 },
    h17: { type: Number, default: 0 },
    h18: { type: Number, default: 0 },
    h19: { type: Number, default: 0 },
    h20: { type: Number, default: 0 },
    h21: { type: Number, default: 0 },
    h22: { type: Number, default: 0 },
    h23: { type: Number, default: 0 },
  },
  articlesLus: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

// Index pour tri rapide leaderboard
deviceStatusSchema.index({ tempsTotalSecondes: -1 });
deviceStatusSchema.index({ tempsTotalSecondes: 1 });
deviceStatusSchema.index({ derniereActivite: -1 });

module.exports = mongoose.model('DeviceStatus', deviceStatusSchema);
