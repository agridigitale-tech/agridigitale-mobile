const UtilisateurSchema = new mongoose.Schema({
  nom: {
    type: String,
    required: [true, "Le nom est obligatoire"],
    trim: true
  },
  email: {
    type: String,
    required: [true, "L'email est obligatoire"],
    unique: true,
    lowercase: true,
    trim: true
  },
  motDePass: {
    type: String,
    required: [true, "Le mot de passe est obligatoire"],
    minlength: [6, "Le mot de passe doit contenir au moins 6 caractères"]
  },
  role: {
    type: String,
    enum: ['USER', 'ADMIN'],
    default: 'USER'
  },
  dateCreation: {
    type: Date,
    default: Date.now
  },
  
  //renitialisation du mot de passe
  resetPasswordToken: {
    type: String,
    default: null
  },
  resetPasswordExpires: {
    type: Date,
    default: null
  }
});
