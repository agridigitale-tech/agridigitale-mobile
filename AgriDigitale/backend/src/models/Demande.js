const mongoose = require('mongoose');

const DemandeSchema = new mongoose.Schema({
  nomComplet: {
    type: String,
    required: true,
    trim: true
  },
  profession: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  telephone: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  statut: {
    type: String,
    enum: ['EN_ATTENTE', 'TRAITE', 'REJETE'],
    default: 'EN_ATTENTE'
  },
  utilisateur: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Utilisateur',
    required: true
  }
}, { timestamps: true });

module.exports = mongoose.model('Demande', DemandeSchema);
