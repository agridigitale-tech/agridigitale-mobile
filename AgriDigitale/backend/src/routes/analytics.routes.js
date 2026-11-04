// Routes de télémétrie & tableau de bord analytics
const express = require('express');
const router = express.Router();
const c = require('../controllers/analytics.controller');

// Enregistrement d'événements (public, appelé en tâche de fond par Flutter)
router.post('/track', c.track);

// Statistiques globales agrégées en JSON
router.get('/stats', c.getStats);

// Liste des utilisateurs / classement (qui passe le plus/moins de temps, recherche)
router.get('/users', c.getUsers);

// Fiche détaillée d'un utilisateur / appareil spécifique
router.get('/user/:deviceId', c.getUserDetail);

// Tableau de bord Web visuel accessible directement dans le navigateur
router.get('/dashboard', c.rendrePageWebDashboard);

module.exports = router;
