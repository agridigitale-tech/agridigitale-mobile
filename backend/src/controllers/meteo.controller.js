//permet de gérer les requêtes liées aux données météo, telles que la consultation des données météo les plus récentes et la publication manuelle de données météo en cas d'indisponibilité de l'API externe

const Meteo = require('../models/Meteo');

exports.consulterMeteo = async (req, res, next) => {
  try {
    const meteo = await Meteo.findOne().sort({ dateMiseAJour: -1 });
    if (!meteo) return res.status(404).json({ message: 'Aucune donnée météo disponible' });
    res.json(meteo);
  } catch (err) { next(err); }
};

// Cas de secours si l'admin veut publier manuellement (API externe indisponible)
exports.publierMeteoManuelle = async (req, res, next) => {
  try {
    const { zone, temperature, description, icone } = req.body;
    const meteo = await Meteo.create({ zone, temperature, description, icone, source: 'manuel' });
    res.status(201).json(meteo);
  } catch (err) { next(err); }
};