//permet de gérer les routes liées aux notifications dans l'application AgriDigitale. Ces routes permettent d'envoyer des notifications manuelles aux utilisateurs de l'application. L'accès à ces routes est restreint aux administrateurs, garantissant que seules les personnes autorisées peuvent envoyer des notifications.

const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const { envoyerManuelle } = require('../controllers/notification.controller');

router.post('/manuelle', proteger, estAdmin, envoyerManuelle);

module.exports = router;