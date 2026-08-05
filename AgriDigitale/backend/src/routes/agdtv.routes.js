//permet de lister les vidéos de la plateforme AgriDigitale TV

const express = require('express');
const router = express.Router();
const { listerVideos } = require('../controllers/agdtv.controller');
router.get('/', listerVideos);
module.exports = router;