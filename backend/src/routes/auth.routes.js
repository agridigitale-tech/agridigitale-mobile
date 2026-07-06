const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const c = require('../controllers/auth.controller');

router.post('/inscription', c.inscrire);
router.post('/connexion', c.connecter);
router.get('/profil', proteger, c.profil);
router.put('/profil', proteger, c.modifierProfil);
router.post('/token-fcm', proteger, c.enregistrerTokenFCM);

module.exports = router;