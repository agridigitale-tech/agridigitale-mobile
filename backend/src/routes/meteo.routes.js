// permet de définir les routes pour les opérations liées aux données météo, telles que la consultation des données météo les plus récentes et la publication manuelle de données météo par un administrateur

const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/meteo.controller');
const upload = require('../middlewares/upload.middleware');

// 1. Consultation publique pour l'application mobile
router.get('/', c.consulterMeteo);

// 2. Publication manuelle avec image locale (Réservé à l'ADMIN connecté)
// L'application mobile ou le panel d'admin devra envoyer le fichier sous la clé 'photoMeteo'
router.post('/', proteger, estAdmin, upload.single('photoMeteo'), c.publierMeteoManuelle);

module.exports = router;
