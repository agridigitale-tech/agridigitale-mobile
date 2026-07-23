const Meteo = require('../models/Meteo');

// Utilisateur : consulter la dernière photo météo publiée
exports.consulterMeteo = async (req, res, next) => {
  try {
    const meteo = await Meteo.findOne({ source: 'manuel' }).sort({ dateMiseAJour: -1 });
    if (!meteo) return res.status(404).json({ message: 'Aucune photo météo disponible' });
    res.json(meteo);
  } catch (err) { next(err); }
};

// Utilisateur : lister toutes les photos météo (archives)
exports.archiverMeteo = async (req, res, next) => {
  try {
    const archives = await Meteo.find({ source: 'manuel' }).sort({ dateMiseAJour: -1 });
    res.json(archives);
  } catch (err) { next(err); }
};

// Admin : publier une photo météo
exports.publierMeteoManuelle = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Veuillez fournir une image' });
    }
    const imageUrl = `/uploads/${req.file.filename}`;
    const meteo = await Meteo.create({
      zone: 'Météo',
      description: 'Photo météo',
      icone: imageUrl,
      source: 'manuel',
    });
    res.status(201).json(meteo);
  } catch (err) { next(err); }
};
