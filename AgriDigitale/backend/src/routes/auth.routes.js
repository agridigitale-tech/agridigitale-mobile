const express = require('express');
const router = express.Router();
const {
  inscrire, connecter, profil, modifierProfil, enregistrerTokenFCM, supprimerCompte,
  motDePasseOublie,
  envoyerLienReset, reinitialiserMotDePasse,
} = require('../controllers/auth.controller');
const { proteger } = require('../middlewares/auth.middleware');

router.post('/inscription', inscrire);
router.post('/connexion', connecter);
router.get('/profil', proteger, profil);
router.put('/profil', proteger, modifierProfil);
router.post('/token-fcm', proteger, enregistrerTokenFCM);
router.delete('/supprimer-compte', proteger, supprimerCompte);

// Réinitialisation par lien deep link
router.post('/forgot-password', envoyerLienReset);
router.post('/reset-password', reinitialiserMotDePasse);
// Page de redirection HTTPS → deep link agridigitale://
router.get('/reset-password', (req, res) => {
  const token = req.query.token || '';
  if (!token) return res.status(400).send('Token manquant');
  const deepLink = `agridigitale://reset-password?token=${encodeURIComponent(token)}`;
  res.send(`<!DOCTYPE html><html><head><meta charset="utf-8"><title>AgriDigitale</title>
<meta http-equiv="refresh" content="0;url=${deepLink}">
<style>body{font-family:Arial,sans-serif;text-align:center;padding:60px 20px;background:#f9f9f9}
h2{color:#2e7d32}a{color:#2e7d32;font-size:18px;font-weight:bold}</style></head>
<body><h2>AgriDigitale</h2><p>Redirection vers l'application...</p>
<p>Si l'app ne s'ouvre pas automatiquement :<br><br>
<a href="${deepLink}">Cliquez ici pour ouvrir l'application</a></p>
<script>window.location.href="${deepLink}";</script></body></html>`);
});

module.exports = router;
