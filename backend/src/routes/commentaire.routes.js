const express = require('express');
const router = express.Router({ mergeParams: true });
const c = require('../controllers/commentaire.controller');
const { proteger } = require('../middlewares/auth.middleware');

router.get('/', c.listerCommentaires);
router.post('/', proteger, c.ajouterCommentaire);
router.delete('/:id', proteger, c.supprimerCommentaire);

module.exports = router;
