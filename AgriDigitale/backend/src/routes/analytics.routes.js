// Routes de télémétrie & tableau de bord analytics
const express = require('express');
const router = express.Router();
const c = require('../controllers/analytics.controller');

// Enregistrement d'événements (public, appelé en tâche de fond par Flutter)
router.post('/track', c.track);

// Statistiques agrégées en JSON (pour le front-end ou tableau de bord)
router.get('/stats', c.getStats);

// Tableau de bord Web visuel accessible directement dans le navigateur
router.get('/dashboard', c.rendrePageWebDashboard);

module.exports = router;
