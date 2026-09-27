const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const { envoyerManuelle, getNonLues, listerNotifications, marquerLues, enregistrerToken } = require('../controllers/notification.controller');

// Utilisateur : enregistrer le token OneSignal
router.post('/token', proteger, enregistrerToken);

// Admin : envoyer une notification à tous
router.post('/manuelle', proteger, estAdmin, envoyerManuelle);

// Utilisateur : lister toutes ses notifications
router.get('/', proteger, listerNotifications);

// Utilisateur : compter les notifications non lues
router.get('/non-lues', proteger, getNonLues);

// Utilisateur : marquer toutes les notifications comme lues
router.post('/marquer-lues', proteger, marquerLues);

module.exports = router;
