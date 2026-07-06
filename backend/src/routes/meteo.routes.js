//permet de définir les routes pour les opérations liées aux données météo, telles que la consultation des données météo les plus récentes et la publication manuelle de données météo par un administrateur

const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/meteo.controller');

router.get('/', c.consulterMeteo);
router.post('/', proteger, estAdmin, c.publierMeteoManuelle);

module.exports = router;