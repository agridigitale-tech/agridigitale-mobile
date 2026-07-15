//permet de définir les routes pour les articles, y compris la liste des articles, la recherche d'articles et le détail d'un article

const express = require('express');
const router = express.Router();
const c = require('../controllers/article.controller');

router.get('/', c.listerArticles);
router.get('/recherche', c.rechercherArticles);
router.get('/categories', c.listerCategories);
router.get('/:id', c.detailArticle);

module.exports = router;