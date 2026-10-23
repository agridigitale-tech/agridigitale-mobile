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

app.use(errorHandler); // toujours en dernier

module.exports = app;
