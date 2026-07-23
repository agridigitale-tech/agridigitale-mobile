const mongoose = require('mongoose');

const FavoriSchema = new mongoose.Schema({
  libelle: {
    type: String,
    required: false,
    trim: true
  },
  utilisateur: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Utilisateur',
    required: true
  },
  article: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Article',
    required: true
  }
}, { timestamps: true });

FavoriSchema.index({ utilisateur: 1, article: 1 }, { unique: true });

module.exports = mongoose.model('Favori', FavoriSchema);
