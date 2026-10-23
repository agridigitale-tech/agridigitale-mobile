const mongoose = require('mongoose');

const MeteoSchema = new mongoose.Schema({
  zone: { 
    type: String, 
    required: true
   },
  temperature: { 
    type: Number
   },
  description: { 
    type: String, 
    required: true
   },
  icone: { 
    type: String
   },
  iconeUrl: { 
    type: String
   },
  donneesPhoto: {
    type: Buffer,
    select: false, // Ne pas charger le gros buffer binaire dans les requêtes de liste
  },
  mimeType: {
    type: String,
    default: 'image/jpeg',
  },
  humidite: { 
    type: Number
   },
  vitesseVent: { 
    type: Number
   },
  source: { 
    type: String, 
    default: 'api'
   },
  dateMiseAJour: { 
    type: Date, 
    default: Date.now
  },

  // Données synthétiques et régionales du bulletin officiel (ANAMET / AgriDigitale)
  resumeMatin: {
    type: String,
    default: 'Au cours de cette matinée, on observe un ciel nuageux sur l\'ensemble du pays avec des brumes matinales locales.',
  },
  resumeApresMidi: {
    type: String,
    default: 'Dans l\'après-midi, des orages associés à quelques pluies localisées sont attendus dans la Maritime et les Plateaux.',
  },
  tempMin: {
    type: Number,
    default: 30,
  },
  tempMax: {
    type: Number,
    default: 37,
  },
  conseilAgricole: {
    type: String,
    default: 'Maritime & Plateaux : Attention aux averses orageuses pour les travaux champêtres et le séchage. Nord : Poursuite des récoltes par temps chaud.',
  },
  regions: [{
    code: String, // 'maritime', 'plateaux', 'centrale', 'kara', 'savanes'
    nom: String,
    chefLieu: String,
    condition: String,
    icone: String,
    tempMin: Number,
    tempMax: Number,
    pluie: Boolean,
  }],

  // Champs administratifs (optionnels)
  publiePar: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Utilisateur'
  }

   
}, { timestamps: true });

module.exports = mongoose.model('Meteo', MeteoSchema);
