// Permet de gérer l'authentification des utilisateurs et la génération de jetons JWT
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Utilisateur = require('../models/Utilisateur');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

// 1. INSCRIPTION
exports.inscrire = async (req, res, next) => {
  try {
    const { nom, email, motDePasse } = req.body;
    if (!nom || !email || !motDePasse) {
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
    }
    if (motDePasse.length < 6) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });
    }

    const existe = await Utilisateur.findOne({ email });
    if (existe) return res.status(409).json({ message: 'Cet e-mail est déjà utilisé' });

    // Hash the password before creating the user
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(motDePasse, salt);

    const utilisateur = new Utilisateur({ nom, email, motDePasse: hashedPassword });
    await utilisateur.save();

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.status(201).json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
   } catch (err) {
     console.error('Registration error:', err);
     res.status(500).json({ message: 'Erreur lors de l\'inscription' });
   }
};

// 2. CONNEXION (Ajouté pour corriger le bug des routes)
exports.connecter = async (req, res, next) => {
  try {
    const { email, motDePasse } = req.body;
    if (!email || !motDePasse) {
      return res.status(400).json({ message: 'L\'email et le mot de passe sont obligatoires' });
    }

    const utilisateur = await Utilisateur.findOne({ email }).select('+motDePasse');
    if (!utilisateur) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const valide = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
    if (!valide) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Erreur lors de la connexion' });
  }
};

// 3. PROFIL (Ajouté pour corriger le bug des routes)
exports.profil = async (req, res, next) => {
  try {
    const utilisateur = await Utilisateur.findById(req.utilisateurId).select('-motDePasse');
    res.json(utilisateur);
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ message: 'Erreur lors de la récupération du profil' });
  }
};

// 4. MODIFIER LE PROFIL
exports.modifierProfil = async (req, res, next) => {
  try {
    const { nom, photo, preferencesRubriques, theme, langue } = req.body;
    const champsAutorises = {};
    if (nom !== undefined) champsAutorises.nom = nom;
    if (photo !== undefined) champsAutorises.photo = photo;
    if (preferencesRubriques !== undefined) champsAutorises.preferencesRubriques = preferencesRubriques;
    if (theme !== undefined) champsAutorises.theme = theme;
    if (langue !== undefined) champsAutorises.langue = langue;

    const utilisateur = await Utilisateur.findByIdAndUpdate(
      req.utilisateurId,
      champsAutorises,
      { new: true, runValidators: true }
    ).select('-motDePasse');
    res.json(utilisateur);
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ message: 'Erreur lors de la mise à jour du profil' });
  }
};

// 5. ENREGISTRER TOKEN FCM
exports.enregistrerTokenFCM = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: req.body.token });
    res.status(204).send();
  } catch (err) {
    console.error('FCM token error:', err);
    res.status(500).json({ message: 'Erreur lors de l\'enregistrement du token FCM' });
  }
};
