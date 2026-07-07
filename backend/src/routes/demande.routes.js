//permet de gérer les routes liées aux demandes des utilisateurs (contact, support, etc.)

const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/demande.controller');

const limiteurDemandes = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: { message: 'Trop de demandes envoyées. Réessayez plus tard.' },
});

router.post('/', limiteurDemandes, c.envoyerDemande);
router.get('/', proteger, estAdmin, c.listerDemandes);
router.put('/:id/traiter', proteger, estAdmin, c.traiterDemande);

module.exports = router;