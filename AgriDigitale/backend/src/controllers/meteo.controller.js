const fs = require('fs');
const path = require('path');
const Meteo = require('../models/Meteo');
const { fetchMeteoVille } = require('../services/meteo.service');

// Régions officielles du Togo avec conditions de référence pour le bulletin
const defaultRegionsTogo = [
  { code: 'savanes', nom: 'Savanes', chefLieu: 'Dapaong', condition: 'Ensoleillé & Très chaud', icone: 'soleil', tempMin: 24, tempMax: 37, pluie: false },
  { code: 'kara', nom: 'Kara', chefLieu: 'Kara', condition: 'Ciel peu nuageux', icone: 'eclaircie', tempMin: 23, tempMax: 36, pluie: false },
  { code: 'centrale', nom: 'Centrale', chefLieu: 'Sokodé', condition: 'Éclaircies & Nuages passagers', icone: 'nuage', tempMin: 22, tempMax: 35, pluie: false },
  { code: 'plateaux', nom: 'Plateaux', chefLieu: 'Atakpamé', condition: 'Orages & Pluies isolées', icone: 'orage', tempMin: 21, tempMax: 32, pluie: true },
  { code: 'maritime', nom: 'Maritime', chefLieu: 'Lomé', condition: 'Ciel nuageux & Risque orageux', icone: 'pluie', tempMin: 25, tempMax: 31, pluie: true },
];

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

// Utilisateur : consulter le dernier bulletin météo officiel avec données structurées
exports.consulterMeteo = async (req, res, next) => {
  try {
    const backendUrl = process.env.BACKEND_URL || 'https://agridigitale-mobile.onrender.com';
    const meteos = await Meteo.find({ source: 'manuel' }).sort({ dateMiseAJour: -1 }).limit(20);
    const valide = meteos.find(aImageValide);

    if (!valide) {
      return res.status(404).json({ message: 'Aucun bulletin météo disponible' });
    }

    const obj = valide.toObject();
    if (obj.iconeUrl && obj.iconeUrl.startsWith('http')) {
      obj.icone = obj.iconeUrl;
    } else if (obj.icone && obj.icone.startsWith('/api/')) {
      obj.iconeUrl = `${backendUrl}${obj.icone}`;
    }

    // Enrichissement synthétique et géographique pour l'affichage interactif moderne
    if (!obj.resumeMatin) {
      obj.resumeMatin = 'Au cours de cette matinée, on observe un ciel nuageux sur l\'ensemble du pays avec des brumes matinales locales.';
    }
    if (!obj.resumeApresMidi) {
      obj.resumeApresMidi = 'Dans l\'après-midi, des orages associés à quelques pluies localisées sont attendus dans la Maritime et les Plateaux.';
    }
    if (!obj.tempMin) obj.tempMin = 30;
    if (!obj.tempMax) obj.tempMax = 37;
    if (!obj.conseilAgricole) {
      obj.conseilAgricole = 'Maritime & Plateaux : Risque d\'orages l\'après-midi, vigilance pour les travaux de plein air et le séchage. Centrale & Nord : Excellente journée pour les récoltes et travaux du sol.';
    }
    if (!obj.regions || obj.regions.length === 0) {
      obj.regions = defaultRegionsTogo;
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
      description: req.body.description || 'Bulletin agro-météorologique officiel',
      source: 'manuel',
      donneesPhoto,
      mimeType,
      dateMiseAJour: new Date(),
      resumeMatin: req.body.resumeMatin || undefined,
      resumeApresMidi: req.body.resumeApresMidi || undefined,
      tempMin: req.body.tempMin ? Number(req.body.tempMin) : undefined,
      tempMax: req.body.tempMax ? Number(req.body.tempMax) : undefined,
      conseilAgricole: req.body.conseilAgricole || undefined,
      regions: req.body.regions ? (typeof req.body.regions === 'string' ? JSON.parse(req.body.regions) : req.body.regions) : undefined,
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
