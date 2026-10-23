const fs = require('fs');
const path = require('path');
const Meteo = require('../models/Meteo');
const { fetchMeteoVille } = require('../services/meteo.service');

// Vérifie si un enregistrement météo dispose d'une image réellement accessible
const aImageValide = (m) => {
  if (m.iconeUrl && m.iconeUrl.startsWith('http')) return true;
  if (m.icone && m.icone.startsWith('http')) return true;
  if (m.icone && m.icone.startsWith('data:image')) return true;
  if (m.icone && m.icone.startsWith('/api/meteo/')) return true;
  if (m.icone && m.icone.startsWith('/uploads/')) {
    const localPath = path.join(__dirname, '../../public', m.icone);
    return fs.existsSync(localPath);
  }
  return false;
};

// Utilisateur : consulter la dernière photo météo valide publiée
exports.consulterMeteo = async (req, res, next) => {
  try {
    const backendUrl = process.env.BACKEND_URL || 'https://agridigitale-mobile.onrender.com';
    const meteos = await Meteo.find({ source: 'manuel' }).sort({ dateMiseAJour: -1 }).limit(20);
    const valide = meteos.find(aImageValide);

    if (!valide) {
      return res.status(404).json({ message: 'Aucune photo météo disponible' });
    }

    const obj = valide.toObject();
    if (obj.iconeUrl && obj.iconeUrl.startsWith('http')) {
      obj.icone = obj.iconeUrl;
    } else if (obj.icone && obj.icone.startsWith('/api/')) {
      obj.iconeUrl = `${backendUrl}${obj.icone}`;
    }
    res.json(obj);
  } catch (err) { next(err); }
};

// Utilisateur : lister toutes les photos météo valides (archives)
exports.archiverMeteo = async (req, res, next) => {
  try {
    const backendUrl = process.env.BACKEND_URL || 'https://agridigitale-mobile.onrender.com';
    const archives = await Meteo.find({ source: 'manuel' }).sort({ dateMiseAJour: -1 });
    const valides = archives.filter(aImageValide).map((m) => {
      const obj = m.toObject();
      if (obj.iconeUrl && obj.iconeUrl.startsWith('http')) {
        obj.icone = obj.iconeUrl;
      } else if (obj.icone && obj.icone.startsWith('/api/')) {
        obj.iconeUrl = `${backendUrl}${obj.icone}`;
      }
      return obj;
    });
    res.json(valides);
  } catch (err) { next(err); }
};

// Servir la photo météo binaire stockée de façon permanente dans MongoDB Atlas
exports.servirPhoto = async (req, res, next) => {
  try {
    const m = await Meteo.findById(req.params.id).select('+donneesPhoto');
    if (!m || !m.donneesPhoto) {
      return res.status(404).send('Photo météo introuvable');
    }
    res.set('Content-Type', m.mimeType || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=86400');
    res.send(m.donneesPhoto);
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

// Admin : publier une photo météo avec persistance permanente dans MongoDB
exports.publierMeteoManuelle = async (req, res, next) => {
  try {
    const backendUrl = process.env.BACKEND_URL || 'https://agridigitale-mobile.onrender.com';
    let donneesPhoto = null;
    let mimeType = 'image/jpeg';
    let imageUrl = '';
    let iconeUrl = '';

    if (req.file) {
      if (req.file.buffer) {
        donneesPhoto = req.file.buffer;
      } else if (req.file.path && fs.existsSync(req.file.path)) {
        donneesPhoto = fs.readFileSync(req.file.path);
      }
      mimeType = req.file.mimetype || 'image/jpeg';
    } else if (req.body.iconeUrl && req.body.iconeUrl.trim()) {
      imageUrl = req.body.iconeUrl.trim();
      iconeUrl = imageUrl;
    }

    if (!donneesPhoto && !imageUrl) {
      return res.status(400).json({ message: 'Veuillez fournir une image' });
    }

    const meteo = new Meteo({
      zone: 'Météo',
      description: req.body.description || 'Photo météo',
      source: 'manuel',
      donneesPhoto,
      mimeType,
      dateMiseAJour: new Date(),
    });

    if (donneesPhoto) {
      meteo.icone = `/api/meteo/${meteo._id}/photo`;
      meteo.iconeUrl = `${backendUrl}/api/meteo/${meteo._id}/photo`;
    } else {
      meteo.icone = imageUrl;
      meteo.iconeUrl = iconeUrl;
    }

    await meteo.save();
    res.status(201).json(meteo);
  } catch (err) { next(err); }
};
