//permet de configurer l'application Express, y compris les middlewares de sécurité, de gestion des erreurs et les routes.

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const errorHandler = require('./middlewares/errorHandler.middleware');

const app = express();
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/articles', require('./routes/article.routes'));
app.use('/api/favoris', require('./routes/favori.routes'));
app.use('/api/meteo', require('./routes/meteo.routes'));
app.use('/api/agdtv', require('./routes/agdtv.routes'));
app.use('/api/demandes', require('./routes/demande.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
// Permet d'accéder aux images via http://localhost:5000/uploads/nom-de-la-photo.jpg
app.use('/uploads', express.static('public/uploads'));

app.use(errorHandler); // toujours en dernier

module.exports = app;