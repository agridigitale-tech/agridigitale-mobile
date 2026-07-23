//permet de proxy les images pour éviter les problèmes de CORS

const express = require('express');
const axios = require('axios');
const router = express.Router();

// GET /api/proxy-image?url=https://...
router.get('/', async (req, res) => {
  const { url } = req.query;
  if (!url) return res.status(400).json({ message: 'url manquante' });

  try {
    const decoded = decodeURIComponent(url);
    // Sécurité : n'autoriser que les images agridigitale.com et agridigitale.net
    if (!decoded.startsWith('https://agridigitale.com') &&
        !decoded.startsWith('https://agridigitale.net') &&
        !decoded.startsWith('http://agridigitale.com') &&
        !decoded.startsWith('http://agridigitale.net')) {
      return res.status(403).json({ message: 'Domaine non autorisé' });
    }

    const response = await axios.get(decoded, {
      responseType: 'stream',
      timeout: 10000,
      headers: { 'User-Agent': 'Mozilla/5.0' },
    });

    res.setHeader('Content-Type', response.headers['content-type'] || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=86400'); // cache 24h
    res.setHeader('Access-Control-Allow-Origin', '*');
    response.data.pipe(res);
  } catch (err) {
    res.status(502).json({ message: 'Impossible de charger l\'image' });
  }
});

module.exports = router;
