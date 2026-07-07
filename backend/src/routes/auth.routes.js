const express = require('express');
const router = express.Router();
const { inscrire, connecter, profil, modifierProfil, enregistrerTokenFCM } = require('../controllers/auth.controller');

// Ces lignes vous afficheront directement dans la console si l'une des fonctions est introuvable
router.post('/inscription', inscrire);
router.post('/connexion', connecter);
router.get('/profil', profil);
router.put('/profil', modifierProfil);
router.post('/token-fcm', enregistrerTokenFCM);



module.exports = router;