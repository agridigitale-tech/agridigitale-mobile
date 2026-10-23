//permet de démarrer le serveur backend, de se connecter à la base de données et de lancer les tâches planifiées pour la récupération des flux RSS, la mise à jour de la météo et la synchronisation des vidéos AGDTV.

require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { demarrerScheduler } = require('./src/services/rss.service');
const { mettreAJourMeteo } = require('./src/services/meteo.service');
const { synchroniserVideos } = require('./src/services/agdtv.service');
const cron = require('node-cron');
const axios = require('axios');

const PORT = process.env.PORT || 5000;

connectDB().then(() => {
  demarrerScheduler();                              // RSS toutes les 5 min (scheduler interne)
  cron.schedule('0 * * * *', mettreAJourMeteo);      // météo toutes les heures
  cron.schedule('0 */3 * * *', synchroniserVideos);  // AGDTV toutes les 3h
  // Délai de 5s au démarrage pour laisser le réseau s'initialiser
  setTimeout(() => { mettreAJourMeteo(); synchroniserVideos(); }, 5000);

  // Auto-ping Keep-Alive toutes les 5 min pour empêcher Render de s'endormir
  const backendUrl = process.env.BACKEND_URL || 'https://agridigitale-mobile.onrender.com';
  cron.schedule('*/5 * * * *', async () => {
    try {
      const res = await axios.get(`${backendUrl}/api/health`, { timeout: 10000 });
      console.log(`[KeepAlive] Ping réussi (${res.status}) vers ${backendUrl}`);
    } catch (err) {
      console.warn(`[KeepAlive] Ping échoué : ${err.message}`);
    }
  });

  //  CORRECTION : Écouter sur toutes les interfaces réseau (0.0.0.0)
  // au lieu de seulement localhost
  const os = require('os');
  const interfaces = os.networkInterfaces();
  let localIp = '0.0.0.0';
  for (const iface of Object.values(interfaces)) {
    for (const alias of iface) {
      if (alias.family === 'IPv4' && !alias.internal) {
        localIp = alias.address;
      }
    }
  }
  app.listen(PORT, '0.0.0.0', () => {
    console.log(` Serveur démarré sur le port ${PORT}`);
    console.log(` Accessible localement : http://localhost:${PORT}`);
    console.log(` Accessible depuis le réseau : http://${localIp}:${PORT}`);
    console.log(` IP détectée automatiquement : ${localIp}`);
  });
});