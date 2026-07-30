const express = require('express');
const router = express.Router();
const { inscrire, connecter, profil, modifierProfil, enregistrerTokenFCM, motDePasseOublie, reinitialiserMotDePasse } = require('../controllers/auth.controller');
const { proteger } = require('../middlewares/auth.middleware');

router.post('/inscription', inscrire);
router.post('/connexion', connecter);
router.get('/profil', proteger, profil);
router.put('/profil', proteger, modifierProfil);
router.post('/token-fcm', proteger, enregistrerTokenFCM);
router.post('/forgot-password', motDePasseOublie);
router.post('/reset-password', reinitialiserMotDePasse);

module.exports = router;