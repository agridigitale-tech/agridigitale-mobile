const mongoose = require('mongoose');

const ParametreSchema = new mongoose.Schema({
  langue: {
    type: String,
    default: 'fr'
  },
  notifActives: {
    type: Boolean,
    default: true
  },
  utilisateur: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Utilisateur',
    required: true,
    unique: true // 1 seul profil de paramètres par utilisateur
  }
}, { timestamps: true });

module.exports = mongoose.model('Parametre', ParametreSchema);
