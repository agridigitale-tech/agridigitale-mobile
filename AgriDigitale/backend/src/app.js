//permet de configurer l'application Express, y compris les middlewares de sécurité, de gestion des erreurs et les routes.

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middlewares/errorHandler.middleware');

const app = express();
app.set('trust proxy', 1);  // 1 = un seul proxy de confiance (Railway)
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    // Autorise les origines locales de développement (localhost et 127.0.0.1),
    // quel que soit le port : flutter run -d chrome peut servir l'app depuis
    // l'un ou l'autre selon la machine.
    const isLocal = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
    const isVercel = /\.vercel\.app$/.test(origin);
    const allowed = [
      'https://agridigitale-production.up.railway.app',
      'https://agridigitale-mobile.onrender.com',
      'https://agridigitale-backend.onrender.com',
      'https://agridigitale.net',
      'https://www.agridigitale.net',
    ];
    if (isLocal || isVercel || allowed.includes(origin)) return callback(null, true);
    return callback(null, false);
  },
  credentials: true,
}));
app.use((req, res, next) => {
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
});
app.use(morgan('dev'));
app.use(express.json());

// Routes de santé / ping (exemptées de rate limit pour Render, UptimeRobot et KeepAlive)
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'agridigitale-backend', uptime: Math.round(process.uptime()) });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'agridigitale-backend', timestamp: new Date().toISOString() });
});

// Proxy d'image (exempté du rate limit global pour éviter le blocage 429)
app.use('/api/proxy-image', require('./routes/proxy.routes'));

// Rate limiter global
const limiterGlobal = rateLimit({ windowMs: 15 * 60 * 1000, max: 300, standardHeaders: true, legacyHeaders: false });
app.use('/api/', limiterGlobal);

// Rate limiter strict pour auth
const limiterAuth = rateLimit({ windowMs: 15 * 60 * 1000, max: 50, message: { message: 'Trop de tentatives, réessayez dans 15 minutes' } });
app.use('/api/auth', limiterAuth);

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/articles', require('./routes/article.routes'));
app.use('/api/favoris', require('./routes/favori.routes'));
app.use('/api/meteo', require('./routes/meteo.routes'));
app.use('/api/agdtv', require('./routes/agdtv.routes'));
app.use('/api/demandes', require('./routes/demande.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
// Permet d'accéder aux images via http://localhost:5000/uploads/nom-de-la-photo.jpg
app.use('/api/bannieres', require('./routes/banniere.routes'));
app.use('/api/articles/:articleId/commentaires', require('./routes/commentaire.routes'));
app.use('/uploads', express.static('public/uploads'));

// Fallback de persistance : si un fichier n'est pas sur disque (redémarrage Render),
// le récupérer depuis MongoDB où il a été sauvegardé en base64
app.get('/uploads/:fichier', async (req, res, next) => {
  try {
    const fs = require('fs');
    const path = require('path');
    const nomFichier = req.params.fichier;
    const cheminFichier = path.join('public', 'uploads', nomFichier);

    if (fs.existsSync(cheminFichier)) {
      return res.sendFile(path.resolve(cheminFichier));
    }

    const Banniere = require('./models/Banniere');
    const b = await Banniere.findOne({
      $or: [
        { image: `/uploads/${nomFichier}` },
        { image: nomFichier },
      ],
      donneesImage: { $ne: null },
    });

    if (b && b.donneesImage) {
      const buffer = Buffer.from(b.donneesImage, 'base64');
      try {
        if (!fs.existsSync(path.join('public', 'uploads'))) {
          fs.mkdirSync(path.join('public', 'uploads'), { recursive: true });
        }
        fs.writeFileSync(cheminFichier, buffer);
      } catch (_) {}
      res.set('Content-Type', b.typeMime || 'image/jpeg');
      res.set('Cache-Control', 'public, max-age=86400');
      return res.send(buffer);
    }

    res.status(404).send('Image introuvable');
  } catch (err) {
    next(err);
  }
});

app.use(errorHandler); // toujours en dernier

module.exports = app;
