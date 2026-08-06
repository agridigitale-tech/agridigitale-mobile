const express = require('express');
const router = express.Router();
const {
  inscrire, connecter, profil, modifierProfil, enregistrerTokenFCM,
  motDePasseOublie,
  envoyerLienReset, reinitialiserMotDePasse,
} = require('../controllers/auth.controller');
const { proteger } = require('../middlewares/auth.middleware');

router.post('/inscription', inscrire);
router.post('/connexion', connecter);
router.get('/profil', proteger, profil);
router.put('/profil', proteger, modifierProfil);
router.post('/token-fcm', proteger, enregistrerTokenFCM);

// Réinitialisation par lien deep link
router.post('/forgot-password', envoyerLienReset);
router.post('/reset-password', reinitialiserMotDePasse);

module.exports = router;
