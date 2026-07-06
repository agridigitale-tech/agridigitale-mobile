const mongoose = require('mongoose');

const FavoriSchema = new mongoose.Schema({
  libelle: {
    type: String,
    required: true,
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

module.exports = mongoose.model('Favori', FavoriSchema);
