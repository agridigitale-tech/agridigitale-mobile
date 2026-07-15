// src/controllers/banniere.controller.js
const Banniere = require('../models/Banniere');

// Récupérer les bannières actives pour le carousel
exports.listerBannieres = async (req, res, next) => {
  try {
    const bannieres = await Banniere.find({ actif: true })
      .sort({ ordre: 1 })
      .limit(5);
    res.json(bannieres);
  } catch (err) { 
    next(err); 
  }
};

// Admin : créer une bannière
exports.creerBanniere = async (req, res, next) => {
  try {
    const banniere = await Banniere.create(req.body);
    res.status(201).json(banniere);
  } catch (err) { 
    next(err); 
  }
};

// Admin : supprimer une bannière
exports.supprimerBanniere = async (req, res, next) => {
  try {
    await Banniere.findByIdAndDelete(req.params.id);
    res.status(204).send();
  } catch (err) { 
    next(err); 
  }
};