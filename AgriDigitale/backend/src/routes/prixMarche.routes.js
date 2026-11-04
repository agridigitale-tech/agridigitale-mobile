const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const upload = require('../middlewares/upload.middleware');
const c = require('../controllers/prixMarche.controller');

// Consultation des marchés et de leurs cours (accès public)
router.get('/', c.getMarches);

// ── CRUD Marchés (Admin) ──
router.post('/marche', proteger, estAdmin, c.creerMarche);
router.put('/marche/:id', proteger, estAdmin, c.modifierMarche);
router.delete('/marche/:id', proteger, estAdmin, c.supprimerMarche);

// ── CRUD Produits & Prix (Admin) ──
router.post('/upload-image', proteger, estAdmin, upload.single('image'), c.uploadImageProduit);
router.put('/', proteger, estAdmin, c.updatePrixProduit);
router.post('/produit', proteger, estAdmin, c.updatePrixProduit);
router.delete('/marche/:marcheId/produit/:nomProduit', proteger, estAdmin, c.supprimerProduit);

// Réinitialisation aux valeurs d'origine (réservé admin)
router.post('/reset', proteger, estAdmin, c.resetToDefaults);

module.exports = router;
