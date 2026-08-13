// src/controllers/banniere.controller.js
const Banniere = require('../models/Banniere');

// Récupérer les bannières actives pour le carousel (utilisateurs)
// Seules les bannières actives ET dans la plage de dates sont retournées
exports.listerBannieres = async (req, res, next) => {
  try {
    const now = new Date();
    const bannieres = await Banniere.find({
      actif: true,
      dateDebut: { $lte: now },
      dateFin: { $gte: now },
    })
      .sort({ ordre: 1 })
      .limit(10);
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
    const dateDebut = req.body.dateDebut ? new Date(req.body.dateDebut) : new Date();
    const dateFin = req.body.dateFin ? new Date(req.body.dateFin) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    // Validation : date de fin doit être après date de début
    if (dateFin <= dateDebut) {
      return res.status(400).json({ message: 'La date de fin doit être après la date de début' });
    }
    const banniere = await Banniere.create({
      ...req.body,
      image: imageUrl,
      actif: req.body.actif === 'true' || req.body.actif === true,
      ordre: req.body.ordre ? Number(req.body.ordre) : 0,
      dateDebut,
      dateFin,
    });
    res.status(201).json(banniere);
  } catch (err) {
    next(err);
  }
};

// Admin : modifier les dates, l'ordre et le lien d'une bannière existante
exports.modifierBanniere = async (req, res, next) => {
  try {
    const { dateDebut, dateFin, ordre, lien, actif } = req.body;
    const debut = dateDebut ? new Date(dateDebut) : undefined;
    const fin = dateFin ? new Date(dateFin) : undefined;

    // Validation : date de fin doit être après date de début
    if (debut && fin && fin <= debut) {
      return res.status(400).json({ message: 'La date de fin doit être après la date de début' });
    }
    const update = {};
    if (debut) update.dateDebut = debut;
    if (fin) update.dateFin = fin;
    if (ordre !== undefined) update.ordre = Number(ordre);
    if (lien !== undefined) update.lien = lien;
    if (actif !== undefined) update.actif = actif === 'true' || actif === true;

    const banniere = await Banniere.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!banniere) return res.status(404).json({ message: 'Bannière introuvable' });
    res.json(banniere);
  } catch (err) {
    next(err);
  }
};

// Cron : désactive automatiquement les bannières dont la date de fin est dépassée
exports.desactiverBannieresExpirees = async () => {
  try {
    const result = await Banniere.updateMany(
      { actif: true, dateFin: { $lt: new Date() } },
      { $set: { actif: false } }
    );
    if (result.modifiedCount > 0) {
      console.log(`[Banniere] ${result.modifiedCount} bannière(s) expirée(s) désactivée(s)`);
    }
  } catch (err) {
    console.error('[Banniere] Erreur désactivation auto:', err.message);
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