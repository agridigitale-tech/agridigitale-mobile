const mongoose = require('mongoose');

const CategorieSchema = new mongoose.Schema({
  nom: {
    type: String,
    required: true,
    trim: true
  },
  slug: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  }
}, { timestamps: true });

module.exports = mongoose.model('Categorie', CategorieSchema);
