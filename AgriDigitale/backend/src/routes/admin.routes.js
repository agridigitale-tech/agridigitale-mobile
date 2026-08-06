//permet de définir les routes réservées à l'administrateur, telles que la récupération des statistiques et la gestion des utilisateurs.

const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/admin.controller');

router.get('/statistiques', proteger, estAdmin, c.statistiques);
router.get('/utilisateurs', proteger, estAdmin, c.listerUtilisateurs);
router.put('/utilisateurs/:id/desactiver', proteger, estAdmin, c.desactiverUtilisateur);


module.exports = router;