const mongoose = require('mongoose');

const articleSchema = new mongoose.Schema({
  guid: { 
    type: String, 
    required: true, 
    unique: true, 
    index: true
 },
  titre: { 
    type: String, 
    required: true 
 },
  contenu: { 
    type: String 
 },
  resume: { 
    type: String 
 },
  image: { 
    type: String, 
    default: null 
 },
  lienSource: { 
    type: String
  },
  source: {
    type: String,
    default: 'AgriDigitale'
  },
  categorie: { 
    type: String, 
    index: true, 
    default: 'Non classé' 
  },
  datePublication: { 
    type: Date, 
    required: true, 
    index: true 
 },
  vues: { 
    type: Number, 
    default: 0 
 }, // pour les stats admin
  legendeImage: {
    type: String,
    default: null
  },
  auteur: {
    type: String,
    default: null
  },
}, { timestamps: { createdAt: 'dateRecuperation', updatedAt: false } });

// Index composés pour des requêtes ultra rapides
articleSchema.index({ categorie: 1, datePublication: -1 });
articleSchema.index({ vues: -1, datePublication: -1 });

module.exports = mongoose.model('Article', articleSchema);