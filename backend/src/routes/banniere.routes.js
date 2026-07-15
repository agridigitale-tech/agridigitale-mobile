// src/routes/banniere.routes.js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/banniere.controller');

// Route publique pour le carousel
router.get('/', c.listerBannieres);

// Routes admin
router.post('/', proteger, estAdmin, c.creerBanniere);
router.delete('/:id', proteger, estAdmin, c.supprimerBanniere);

module.exports = router;