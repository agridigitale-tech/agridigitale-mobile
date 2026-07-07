//permet de démarrer le serveur backend, de se connecter à la base de données et de lancer les tâches planifiées pour la récupération des flux RSS, la mise à jour de la météo et la synchronisation des vidéos AGDTV.

require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { demarrerScheduler } = require('./src/services/rss.service');
const { mettreAJourMeteo } = require('./src/services/meteo.service');
const { synchroniserVideos } = require('./src/services/agdtv.service');
const cron = require('node-cron');

const PORT = process.env.PORT || 5000;

connectDB().then(() => {
  demarrerScheduler();                              // RSS toutes les 15 min
  cron.schedule('0 * * * *', mettreAJourMeteo);      // météo toutes les heures
  cron.schedule('0 */3 * * *', synchroniserVideos);  // AGDTV toutes les 3h
  mettreAJourMeteo();
  synchroniserVideos();

  app.listen(PORT, () => console.log(`🚀 Serveur démarré sur le port ${PORT}`));
});