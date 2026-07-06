//permet de gérer l'authentification des utilisateurs et la génération de jetons JWT

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Utilisateur = require('../models/Utilisateur');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

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

    const motDePasseHache = await bcrypt.hash(motDePasse, 10);
    const utilisateur = await Utilisateur.create({ nom, email, motDePasse: motDePasseHache });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.status(201).json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
  } catch (err) { next(err); }
};

exports.enregistrerTokenFCM = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: req.body.token });
    res.status(204).send();
  } catch (err) { next(err); }
};