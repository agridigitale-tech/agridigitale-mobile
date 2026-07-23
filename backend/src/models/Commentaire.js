const mongoose = require('mongoose');

const CommentaireSchema = new mongoose.Schema({
  article: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Article', 
    required: true, 
    index: true 
  },
  auteur: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Utilisateur', 
    required: true 
  },
  nomAuteur: { 
    type: String, 
    required: true, 
    trim: true, 
    maxlength: 80 
  },

  contenu: { 
    type: String, 
    required: true, 
    trim: true, 
    maxlength: 1000 
  },
}, { timestamps: true });

module.exports = mongoose.model('Commentaire', CommentaireSchema);
