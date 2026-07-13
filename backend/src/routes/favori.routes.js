// permet de définir les routes pour la gestion des favoris, y compris l'ajout, la suppression et la liste des articles favoris

const express = require('express');
const router = express.Router();
const favoriController = require('../controllers/favori.controller');
// 1. ÉTAPE MANQUANTE : Importer le middleware d'authentification
const { proteger } = require('../middlewares/auth.middleware');

// 2. ÉTAPE MANQUANTE : Ajouter "proteger" sur chaque ligne pour activer le décodage du jeton
router.post('/', proteger, favoriController.ajouterFavori);
router.get('/', proteger, favoriController.listerFavoris);
router.delete('/:articleId', proteger, favoriController.retirerFavori);

module.exports = router;
