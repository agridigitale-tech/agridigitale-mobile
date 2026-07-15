// src/models/Banniere.js
const mongoose = require('mongoose');

const banniereSchema = new mongoose.Schema({
  image: { 
    type: String,
    required: true
  },
  titre: { 
    type: String,
    default: '' 
},
  description: { 
    type: String, 
    default: '' 
 },
  lien: { 
    type: String, 
    default: null 
},
  ordre: { 
    type: Number, 
    default: 0 
},
  actif: { 
    type: Boolean, 
    default: true 
},
  type: { 
    type: String, 
    enum: ['pub', 'promo', 'banniere'], 
    default: 'banniere' 
}

}, { timestamps: true });

module.exports = mongoose.model('Banniere', banniereSchema);