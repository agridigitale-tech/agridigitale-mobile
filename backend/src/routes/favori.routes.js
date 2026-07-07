//permet de définir les routes pour la gestion des favoris, y compris l'ajout, la suppression et la liste des articles favoris

const express = require('express');
const router = express.Router();
const favoriController = require('../controllers/favori.controller');

// Points d'accès de l'API alignés avec votre contrôleur
router.post('/', favoriController.ajouterFavori);
router.get('/', favoriController.listerFavoris);
router.delete('/:articleId', favoriController.retirerFavori); // Utilise retirerFavori

module.exports = router;
