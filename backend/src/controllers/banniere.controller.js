// src/controllers/banniere.controller.js
const Banniere = require('../models/Banniere');

// Récupérer les bannières actives pour le carousel (utilisateurs)
exports.listerBannieres = async (req, res, next) => {
  try {
    const now = new Date();
    const bannieres = await Banniere.find({
      actif: true,
      dateDebut: { $lte: now },
      dateFin: { $gte: now },
    })
      .sort({ ordre: 1 })
      .limit(5);
    res.json(bannieres);
  } catch (err) { 
    next(err); 
  }
};

// Admin : récupérer TOUTES les bannières (actives et inactives)
exports.listerToutesBannieres = async (req, res, next) => {
  try {
    const bannieres = await Banniere.find().sort({ ordre: 1 });
    res.json(bannieres);
  } catch (err) { 
    next(err); 
  }
};

exports.creerBanniere = async (req, res, next) => {
  try {
    let imageUrl;
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    } else if (req.body.image) {
      imageUrl = req.body.image;
    } else {
      return res.status(400).json({ message: 'Image requise' });
    }
    const banniere = await Banniere.create({
      ...req.body,
      image: imageUrl,
      actif: req.body.actif === 'true' || req.body.actif === true,
      ordre: req.body.ordre ? Number(req.body.ordre) : 0,
      dateDebut: req.body.dateDebut ? new Date(req.body.dateDebut) : new Date(),
      dateFin: req.body.dateFin ? new Date(req.body.dateFin) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });
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