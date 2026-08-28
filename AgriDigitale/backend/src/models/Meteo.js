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

  // Champs administratifs (optionnels)
  publiePar: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Utilisateur'
   }

   
}, { timestamps: true });

module.exports = mongoose.model('Meteo', MeteoSchema);
