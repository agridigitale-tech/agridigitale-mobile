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
}, { timestamps: { createdAt: 'dateRecuperation', updatedAt: false } });

module.exports = mongoose.model('Article', articleSchema);