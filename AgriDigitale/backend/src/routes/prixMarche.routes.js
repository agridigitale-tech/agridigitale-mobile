const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/prixMarche.controller');

// Consultation des marchés et de leurs cours (accès public)
router.get('/', c.getMarches);

// Mise à jour d'un cours (réservé admin)
router.put('/', proteger, estAdmin, c.updatePrixProduit);

// Réinitialisation aux valeurs d'origine (réservé admin)
router.post('/reset', proteger, estAdmin, c.resetToDefaults);

module.exports = router;
