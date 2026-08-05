
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const utilisateurSchema = new mongoose.Schema({
  nom: { 
    type: String,
    required: true, 
    trim: true 
  },
  email: { 
    type: String, 
    required: true, 
    unique: true, 
    lowercase: true, 
    trim: true 
  },
  motDePasse: { 
    type: String, 
    required: true, 
    select: false 
  }, // select:false = jamais renvoyé par défaut
  photo: { 
    type: String, 
    default: null 
  },
  role: { 
    type: String, 
    enum: ['utilisateur', 'administrateur'], 
    default: 'utilisateur' 
  },
  preferencesRubriques: [{ 
    type: String 
  }],
  tokenFCM: { 
    type: String, 
    default: null 
  }, // pour cibler les notifications push
  theme: { 
    type: String, 
    enum: ['clair', 'sombre'], 
    default: 'clair' 
  },
  langue: { 
    type: String, 
    default: 'fr' 
  },
  actif: { 
    type: Boolean, 
    default: true 
  },
  pays: {
    type: String,
    default: ''
  },
  continent: {
    type: String,
    default: ''
  },
  resetToken: { type: String, default: null, select: false },
  resetTokenExpiry: { type: Date, default: null, select: false },
  otpTentatives: { type: Number, default: 0, select: false },
  otpFenetre: { type: Date, default: null, select: false },
}, { timestamps: true });

// Hash du mot de passe avant sauvegarde
// NOTE: Password hashing is now handled in the controller to avoid Mongoose pre-save hook issues
// utilisateurSchema.pre('save', async function(next) {
//   if (!this.isModified('motDePasse')) return next();
//
//   try {
//     const salt = await bcrypt.genSalt(10);
//     this.motDePasse = await bcrypt.hash(this.motDePasse, salt);
//     next();
//   } catch (err) {
//     // Create a proper error and pass it to next
//     const error = new Error('Erreur lors du hachage du mot de passe');
//     return next(error);
//   }
// });

module.exports = mongoose.model('Utilisateur', utilisateurSchema);
