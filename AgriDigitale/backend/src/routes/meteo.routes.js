const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/meteo.controller');
const upload = require('../middlewares/upload.middleware');

router.get('/', c.consulterMeteo);
router.get('/archives', c.archiverMeteo);
router.get('/:id/photo', c.servirPhoto);
router.get('/ville/:ville', c.rechercherVille);
router.post('/', proteger, estAdmin, upload.single('photoMeteo'), c.publierMeteoManuelle);

module.exports = router;
