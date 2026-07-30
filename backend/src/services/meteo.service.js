// permet de mettre à jour les données météo dans la base de données en utilisant l'API OpenWeatherMap

const axios = require('axios');
const Meteo = require('../models/Meteo');

// Cache mémoire : { ville: { data, expiresAt } }
const _cache = {};
const CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes

const fetchMeteoVille = async (ville) => {
  const now = Date.now();
  if (_cache[ville] && _cache[ville].expiresAt > now) {
    return _cache[ville].data;
  }
  const { data } = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
    params: {
      q: ville,
      appid: process.env.OPENWEATHER_API_KEY,
      units: 'metric',
      lang: 'fr',
    },
  });
  _cache[ville] = { data, expiresAt: now + CACHE_TTL_MS };
  return data;
};

const mettreAJourMeteo = async () => {
  try {
    const data = await fetchMeteoVille(process.env.OPENWEATHER_VILLE);
    await Meteo.findOneAndUpdate(
      { zone: process.env.OPENWEATHER_VILLE },
      {
        temperature: data.main.temp,
        description: data.weather[0].description,
        icone: data.weather[0].icon,
        humidite: data.main.humidity,
        vitesseVent: data.wind.speed,
        source: 'api',
        dateMiseAJour: new Date(),
      },
      { upsert: true, new: true }
    );
    console.log('  Météo mise à jour');
  } catch (err) {
    console.error(' Erreur météo :', err.message);
  }
};

module.exports = { mettreAJourMeteo, fetchMeteoVille };
