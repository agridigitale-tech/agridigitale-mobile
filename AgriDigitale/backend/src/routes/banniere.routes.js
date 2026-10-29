const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const upload = require('../middlewares/upload.middleware');
const c = require('../controllers/banniere.controller');

router.get('/', c.listerBannieres);
router.get('/admin', proteger, estAdmin, c.listerToutesBannieres);
router.post('/', proteger, estAdmin, upload.single('image'), c.creerBanniere);
router.put('/:id', proteger, estAdmin, c.modifierBanniere);
router.patch('/:id/booster', proteger, estAdmin, c.toggleBooster);
router.delete('/:id', proteger, estAdmin, c.supprimerBanniere);

module.exports = router;