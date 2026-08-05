const express = require('express');
const router = express.Router();
const {
  inscrire, connecter, profil, modifierProfil, enregistrerTokenFCM,
  motDePasseOublie, reinitialiserMotDePasse,
  envoyerOTP, verifierOTPetReset,
} = require('../controllers/auth.controller');
const { proteger } = require('../middlewares/auth.middleware');

router.post('/inscription', inscrire);
router.post('/connexion', connecter);
router.get('/profil', proteger, profil);
router.put('/profil', proteger, modifierProfil);
router.post('/token-fcm', proteger, enregistrerTokenFCM);

// Ancien système (deep link) — conservé
router.post('/forgot-password', motDePasseOublie);
router.post('/reset-password', reinitialiserMotDePasse);

// Nouveau système OTP
router.post('/send-otp', envoyerOTP);
router.post('/verify-otp', verifierOTPetReset);

module.exports = router;
