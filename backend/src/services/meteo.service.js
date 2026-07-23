// permet de mettre à jour les données météo dans la base de données en utilisant l'API OpenWeatherMap 

const axios = require('axios');
const Meteo = require('../models/Meteo');

const mettreAJourMeteo = async () => {
  try {
    const url = `https://api.openweathermap.org/data/2.5/weather`;
    const { data } = await axios.get(url, {
      params: {
        q: process.env.OPENWEATHER_VILLE,
        appid: process.env.OPENWEATHER_API_KEY,
        units: 'metric',
        lang: 'fr',
      },
    });

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

// Exportation de la fonction vers server.js (Toute planification superflue après cette ligne est supprimée)
module.exports = { mettreAJourMeteo };
