const Meteo = require('../models/Meteo');
const { fetchMeteoVille } = require('../services/meteo.service');

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

// Utilisateur : rechercher la météo d'une ville via OpenWeatherMap (avec cache 30min)
exports.rechercherVille = async (req, res, next) => {
  try {
    const { ville } = req.params;
    if (!ville || ville.trim().length < 2) {
      return res.status(400).json({ message: 'Nom de ville invalide' });
    }
    const data = await fetchMeteoVille(ville.trim());
    res.json({
      ville: data.name,
      pays: data.sys?.country ?? '',
      temperature: data.main?.temp ?? null,
      description: data.weather?.[0]?.description ?? '',
      icone: data.weather?.[0]?.icon
        ? `https://openweathermap.org/img/wn/${data.weather[0].icon}@2x.png`
        : null,
      humidite: data.main?.humidity ?? null,
      vitesseVent: data.wind?.speed ?? null,
    });
  } catch (err) {
    if (err.response?.status === 404) {
      return res.status(404).json({ message: 'Ville introuvable' });
    }
    next(err);
  }
};

// Admin : publier une photo météo
exports.publierMeteoManuelle = async (req, res, next) => {
  try {
    // Supporte soit un fichier uploadé, soit une URL d'image distante
    const imageUrl = req.file
      ? `/uploads/${req.file.filename}`
      : (req.body.iconeUrl && req.body.iconeUrl.trim());
    if (!imageUrl) {
      return res.status(400).json({ message: 'Veuillez fournir une image' });
    }
    const meteo = await Meteo.create({
      zone: 'Météo',
      description: req.body.description || 'Photo météo',
      icone: imageUrl,
      iconeUrl: req.body.iconeUrl && req.body.iconeUrl.trim() ? req.body.iconeUrl.trim() : undefined,
      source: 'manuel',
    });
    res.status(201).json(meteo);
  } catch (err) { next(err); }
};
