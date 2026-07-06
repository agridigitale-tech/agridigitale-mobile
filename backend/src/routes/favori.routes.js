//permet de définir les routes pour la gestion des favoris, y compris l'ajout, la suppression et la liste des articles favoris

const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const c = require('../controllers/favori.controller');

router.post('/', proteger, c.ajouterFavori);
router.delete('/:articleId', proteger, c.retirerFavori);
router.get('/', proteger, c.listerFavoris);