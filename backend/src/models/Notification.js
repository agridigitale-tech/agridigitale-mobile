const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  titre: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  dateEnvoi: {
    type: Date,
    default: Date.now
  },
  lu: {
    type: Boolean,
    default: false
  },
  article: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Article'
  },
  destinataire: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Utilisateur',
    required: true
  }
}, { timestamps: true });


module.exports = mongoose.model('Notification', NotificationSchema);//permet d'exporter le modèle Notification pour l'utiliser dans d'autres parties de l'application

