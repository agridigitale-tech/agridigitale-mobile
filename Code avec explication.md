# AgriDigitale — Guide complet de développement (version solo)
### Backend Node.js/Express + MongoDB + Flutter — Code optimal et expliqué, de A à Z

Ce document couvre **l'intégralité du projet**, puisque tu le portes seul désormais : authentification, fil d'actualités, RSS, météo, AGDTV, favoris hors-ligne, notifications push, formulaire de demande, paramètres, et back-office admin. Suis les phases dans l'ordre : chaque phase dépend de la précédente.

---

# PARTIE A — BACKEND (Node.js / Express / MongoDB)

## A.0 Pourquoi cet ordre

Un backend se construit toujours dans cet ordre logique, sinon tu codes des choses qui ne peuvent pas encore être testées :

```
1. Connexion DB
2. Modèles (structure des données)
3. Authentification (tout le reste en dépend : qui peut faire quoi)
4. Service RSS (remplit la base en articles réels)
5. API Articles (lit ce que le RSS a rempli)
6. Favoris, Météo, AGDTV, Demandes (modules métier)
7. Notifications (déclenchées par les nouveautés)
8. Back-office admin (supervise tout ce qui précède)
```

## A.1 Installation

```bash
mkdir agridigitale-backend && cd agridigitale-backend
npm init -y
npm install express mongoose dotenv cors helmet morgan bcryptjs jsonwebtoken
npm install rss-parser node-cron axios firebase-admin express-rate-limit express-validator
npm install --save-dev nodemon
```

**Pourquoi chaque paquet :**
- `express` : serveur HTTP et routage.
- `mongoose` : ODM pour MongoDB (modélisation, validation, requêtes).
- `dotenv` : variables d'environnement (clés API, secrets) hors du code.
- `cors` : autorise l'app Flutter à appeler ton API depuis un autre domaine/port.
- `helmet` : ajoute des en-têtes HTTP de sécurité par défaut.
- `morgan` : logs des requêtes (utile pour déboguer).
- `bcryptjs` : hachage des mots de passe (jamais stocker en clair).
- `jsonwebtoken` : génération/vérification des jetons JWT.
- `rss-parser` : parse le flux XML d'agridigitale.net/feed.
- `node-cron` : planifie la récupération automatique du flux.
- `axios` : appels à l'API météo tierce et à l'API YouTube.
- `firebase-admin` : envoi des notifications push depuis le serveur.
- `express-rate-limit` : limite les abus (ex. spam sur le formulaire de demande).
- `express-validator` : validation propre des données entrantes.

## A.2 Arborescence complète

```
agridigitale-backend/
├── src/
│   ├── config/
│   │   ├── db.js
│   │   └── firebase.js
│   ├── models/
│   │   ├── Utilisateur.js
│   │   ├── Article.js
│   │   ├── Favori.js
│   │   ├── Meteo.js
│   │   ├── VideoAGDTV.js
│   │   ├── Demande.js
│   │   ├── SourceRSS.js
│   │   └── Notification.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── article.controller.js
│   │   ├── favori.controller.js
│   │   ├── meteo.controller.js
│   │   ├── agdtv.controller.js
│   │   ├── demande.controller.js
│   │   ├── notification.controller.js
│   │   └── admin.controller.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── article.routes.js
│   │   ├── favori.routes.js
│   │   ├── meteo.routes.js
│   │   ├── agdtv.routes.js
│   │   ├── demande.routes.js
│   │   ├── notification.routes.js
│   │   └── admin.routes.js
│   ├── middlewares/
│   │   ├── auth.middleware.js
│   │   ├── admin.middleware.js
│   │   └── errorHandler.middleware.js
│   ├── services/
│   │   ├── rss.service.js
│   │   ├── meteo.service.js
│   │   ├── notification.service.js
│   │   └── agdtv.service.js
│   └── app.js
├── .env
├── server.js
└── package.json
```

## A.3 Configuration

**`.env`**
```
PORT=5000
MONGO_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/agridigitale
JWT_SECRET=change_moi_par_une_chaine_longue_et_aleatoire
JWT_EXPIRES_IN=7d
RSS_FEED_URL=https://agridigitale.net/feed
OPENWEATHER_API_KEY=ta_cle_openweather
OPENWEATHER_VILLE=Lome,TG
YOUTUBE_API_KEY=ta_cle_youtube
YOUTUBE_CHANNEL_ID=id_de_la_chaine_agdtv
FIREBASE_SERVICE_ACCOUNT=./firebase-service-account.json
```

**`src/config/db.js`**
```js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log(' MongoDB connecté');
  } catch (err) {
    console.error(' Erreur de connexion MongoDB :', err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
```

**`src/config/firebase.js`** — initialisation unique de Firebase Admin (pour les push)
```js
const admin = require('firebase-admin');
const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
```
> Tu récupères ce fichier JSON dans la console Firebase : Paramètres du projet → Comptes de service → Générer une nouvelle clé privée. **Ne le commite jamais sur Git** (ajoute-le à `.gitignore`).

## A.4 Les modèles (structure de données complète)

**`Utilisateur.js`**
```js
const mongoose = require('mongoose');

const utilisateurSchema = new mongoose.Schema({
  nom: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  motDePasse: { type: String, required: true, select: false }, // select:false = jamais renvoyé par défaut
  photo: { type: String, default: null },
  role: { type: String, enum: ['utilisateur', 'administrateur'], default: 'utilisateur' },
  preferencesRubriques: [{ type: String }],
  tokenFCM: { type: String, default: null }, // pour cibler les notifications push
  theme: { type: String, enum: ['clair', 'sombre'], default: 'clair' },
  langue: { type: String, default: 'fr' },
  actif: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Utilisateur', utilisateurSchema);
```
*`select: false` sur le mot de passe : bonne pratique, il ne sortira jamais d'une requête `find()` classique, seulement si tu le demandes explicitement avec `.select('+motDePasse')` (utile en connexion).*

**`Article.js`**
```js
const mongoose = require('mongoose');

const articleSchema = new mongoose.Schema({
  guid: { type: String, required: true, unique: true, index: true },
  titre: { type: String, required: true },
  contenu: { type: String },
  resume: { type: String },
  image: { type: String, default: null },
  lienSource: { type: String },
  categorie: { type: String, index: true, default: 'Non classé' },
  datePublication: { type: Date, required: true, index: true },
  vues: { type: Number, default: 0 }, // pour les stats admin
}, { timestamps: { createdAt: 'dateRecuperation', updatedAt: false } });

module.exports = mongoose.model('Article', articleSchema);
```

**`Favori.js`**
```js
const mongoose = require('mongoose');

const favoriSchema = new mongoose.Schema({
  utilisateur: { type: mongoose.Schema.Types.ObjectId, ref: 'Utilisateur', required: true },
  article: { type: mongoose.Schema.Types.ObjectId, ref: 'Article', required: true },
}, { timestamps: true });

favoriSchema.index({ utilisateur: 1, article: 1 }, { unique: true });

module.exports = mongoose.model('Favori', favoriSchema);
```

**`Meteo.js`**
```js
const mongoose = require('mongoose');

const meteoSchema = new mongoose.Schema({
  zone: { type: String, required: true },
  temperature: Number,
  description: String,
  icone: String,
  humidite: Number,
  vitesseVent: Number,
  source: { type: String, enum: ['api', 'manuel'], default: 'api' },
  dateMiseAJour: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Meteo', meteoSchema);
```

**`VideoAGDTV.js`**
```js
const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
  idYoutube: { type: String, required: true, unique: true },
  titre: String,
  vignette: String,
  datePublication: Date,
}, { timestamps: true });

module.exports = mongoose.model('VideoAGDTV', videoSchema);
```

**`Demande.js`**
```js
const mongoose = require('mongoose');

const demandeSchema = new mongoose.Schema({
  nom: { type: String, required: true },
  profession: String,
  adresse: String,
  email: String,
  telephone: String,
  categorie: String,
  message: { type: String, required: true },
  statut: { type: String, enum: ['Reçue', 'Traitée'], default: 'Reçue' },
}, { timestamps: { createdAt: 'dateEnvoi', updatedAt: false } });

module.exports = mongoose.model('Demande', demandeSchema);
```

**`SourceRSS.js`** (pour ton back-office : gérer plusieurs sources si besoin)
```js
const mongoose = require('mongoose');

const sourceSchema = new mongoose.Schema({
  url: { type: String, required: true, unique: true },
  categorie: String,
  actif: { type: Boolean, default: true },
});

module.exports = mongoose.model('SourceRSS', sourceSchema);
```

## A.5 Middlewares (sécurité et rôles)

**`auth.middleware.js`** — vérifie que le jeton JWT est valide
```js
const jwt = require('jsonwebtoken');

exports.proteger = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Accès refusé : jeton manquant' });
  }
  try {
    const decoded = jwt.verify(authHeader.split(' ')[1], process.env.JWT_SECRET);
    req.utilisateurId = decoded.id;
    req.role = decoded.role;
    next();
  } catch {
    return res.status(401).json({ message: 'Jeton invalide ou expiré' });
  }
};
```

**`admin.middleware.js`** — vérifie en plus que le rôle est administrateur
```js
exports.estAdmin = (req, res, next) => {
  if (req.role !== 'administrateur') {
    return res.status(403).json({ message: 'Accès réservé à l’administrateur' });
  }
  next();
};
```
> `proteger` répond à "qui es-tu ?", `estAdmin` répond à "as-tu le droit ?". On les chaîne toujours dans cet ordre sur les routes admin : `router.get('/stats', proteger, estAdmin, controleur)`.

**`errorHandler.middleware.js`** — centralise la gestion d'erreurs (évite de répéter des try/catch partout)
```js
module.exports = (err, req, res, next) => {
  console.error(err.stack);
  const statut = err.statusCode || 500;
  res.status(statut).json({ message: err.message || 'Erreur serveur interne' });
};
```

## A.6 Authentification (module central)

**`auth.controller.js`**
```js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Utilisateur = require('../models/Utilisateur');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

exports.inscrire = async (req, res, next) => {
  try {
    const { nom, email, motDePasse } = req.body;
    if (!nom || !email || !motDePasse) {
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
    }
    if (motDePasse.length < 6) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });
    }

    const existe = await Utilisateur.findOne({ email });
    if (existe) return res.status(409).json({ message: 'Cet e-mail est déjà utilisé' });

    const motDePasseHache = await bcrypt.hash(motDePasse, 10);
    const utilisateur = await Utilisateur.create({ nom, email, motDePasse: motDePasseHache });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.status(201).json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
  } catch (err) { next(err); }
};

exports.connecter = async (req, res, next) => {
  try {
    const { email, motDePasse } = req.body;
    const utilisateur = await Utilisateur.findOne({ email }).select('+motDePasse');
    if (!utilisateur) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const valide = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
    if (!valide) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
  } catch (err) { next(err); }
};

exports.profil = async (req, res, next) => {
  try {
    const utilisateur = await Utilisateur.findById(req.utilisateurId);
    res.json(utilisateur);
  } catch (err) { next(err); }
};

exports.modifierProfil = async (req, res, next) => {
  try {
    const { nom, photo, preferencesRubriques, theme, langue } = req.body;
    const utilisateur = await Utilisateur.findByIdAndUpdate(
      req.utilisateurId,
      { nom, photo, preferencesRubriques, theme, langue },
      { new: true, runValidators: true }
    );
    res.json(utilisateur);
  } catch (err) { next(err); }
};

exports.enregistrerTokenFCM = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: req.body.token });
    res.status(204).send();
  } catch (err) { next(err); }
};
```

**`auth.routes.js`**
```js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const c = require('../controllers/auth.controller');

router.post('/inscription', c.inscrire);
router.post('/connexion', c.connecter);
router.get('/profil', proteger, c.profil);
router.put('/profil', proteger, c.modifierProfil);
router.post('/token-fcm', proteger, c.enregistrerTokenFCM);

module.exports = router;
```

## A.7 Service RSS (alimente le fil d'actualités)

**`rss.service.js`**
```js
const Parser = require('rss-parser');
const cron = require('node-cron');
const Article = require('../models/Article');
const { notifierNouvelArticle } = require('./notification.service');

const parser = new Parser({ customFields: { item: ['category'] } });

const nettoyerHTML = (html = '') =>
  html.replace(/<[^>]*>?/gm, '').replace(/&nbsp;/g, ' ').trim();

const extraireImage = (item) => {
  const match = (item['content:encoded'] || '').match(/<img[^>]+src="([^">]+)"/);
  return match ? match[1] : null;
};

const recupererFlux = async () => {
  try {
    const feed = await parser.parseURL(process.env.RSS_FEED_URL);
    let nouveaux = 0;

    for (const item of feed.items) {
      const existe = await Article.findOne({ guid: item.guid });
      if (existe) continue;

      const article = await Article.create({
        guid: item.guid,
        titre: item.title,
        contenu: nettoyerHTML(item['content:encoded'] || item.content),
        resume: nettoyerHTML(item.contentSnippet || item.description),
        image: extraireImage(item),
        lienSource: item.link,
        categorie: item.categories?.[0] || 'Non classé',
        datePublication: new Date(item.pubDate),
      });

      nouveaux++;
      await notifierNouvelArticle(article); // push ciblé selon les préférences des utilisateurs
    }
    console.log(`🔄 Flux RSS synchronisé : ${nouveaux} nouveaux article(s) sur ${feed.items.length}`);
  } catch (err) {
    console.error('❌ Erreur récupération RSS :', err.message);
  }
};

const demarrerScheduler = () => {
  cron.schedule('*/15 * * * *', recupererFlux); // toutes les 15 minutes
  recupererFlux(); // exécution immédiate au démarrage du serveur
};

module.exports = { demarrerScheduler, recupererFlux };
```
*Pourquoi vérifier `existe` avant de créer : c'est la déduplication exigée par ton cahier des charges (le `guid` RSS est unique et sert de clé anti-doublon).*

## A.8 API Articles

**`article.controller.js`**
```js
const Article = require('../models/Article');

exports.listerArticles = async (req, res, next) => {
  try {
    const { categorie, page = 1, limite = 10 } = req.query;
    const filtre = categorie ? { categorie } : {};
    const articles = await Article.find(filtre)
      .sort({ datePublication: -1 })
      .skip((page - 1) * limite)
      .limit(Number(limite));
    res.json(articles);
  } catch (err) { next(err); }
};

exports.detailArticle = async (req, res, next) => {
  try {
    const article = await Article.findByIdAndUpdate(
      req.params.id,
      { $inc: { vues: 1 } }, // incrémente les vues pour les stats admin
      { new: true }
    );
    if (!article) return res.status(404).json({ message: 'Article introuvable' });
    res.json(article);
  } catch (err) { next(err); }
};

exports.rechercherArticles = async (req, res, next) => {
  try {
    const { motCle, categorie, dateDebut, dateFin } = req.query;
    const filtre = {};
    if (motCle) {
      filtre.$or = [
        { titre: { $regex: motCle, $options: 'i' } },
        { contenu: { $regex: motCle, $options: 'i' } },
      ];
    }
    if (categorie) filtre.categorie = categorie;
    if (dateDebut || dateFin) {
      filtre.datePublication = {};
      if (dateDebut) filtre.datePublication.$gte = new Date(dateDebut);
      if (dateFin) filtre.datePublication.$lte = new Date(dateFin);
    }
    const articles = await Article.find(filtre).sort({ datePublication: -1 });
    res.json(articles);
  } catch (err) { next(err); }
};
```

**`article.routes.js`**
```js
const express = require('express');
const router = express.Router();
const c = require('../controllers/article.controller');

router.get('/', c.listerArticles);
router.get('/recherche', c.rechercherArticles);
router.get('/:id', c.detailArticle);

module.exports = router;
```

## A.9 Favoris

**`favori.controller.js`**
```js
const Favori = require('../models/Favori');

exports.ajouterFavori = async (req, res, next) => {
  try {
    const favori = await Favori.create({ utilisateur: req.utilisateurId, article: req.body.articleId });
    res.status(201).json(favori);
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ message: 'Déjà en favoris' });
    next(err);
  }
};

exports.retirerFavori = async (req, res, next) => {
  try {
    await Favori.deleteOne({ utilisateur: req.utilisateurId, article: req.params.articleId });
    res.status(204).send();
  } catch (err) { next(err); }
};

exports.listerFavoris = async (req, res, next) => {
  try {
    const favoris = await Favori.find({ utilisateur: req.utilisateurId })
      .populate('article')
      .sort({ createdAt: -1 });
    res.json(favoris.map(f => f.article));
  } catch (err) { next(err); }
};
```

**`favori.routes.js`**
```js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const c = require('../controllers/favori.controller');

router.post('/', proteger, c.ajouterFavori);
router.delete('/:articleId', proteger, c.retirerFavori);
router.get('/', proteger, c.listerFavoris);

module.exports = router;
```

## A.10 Météo (remplace l'ancien contenu statique périmé)

**`meteo.service.js`** — récupère la météo réelle via OpenWeather
```js
const axios = require('axios');
const Meteo = require('../models/Meteo');

const mettreAJourMeteo = async () => {
  try {
    const url = `https://api.openweathermap.org/data/2.5/weather`;
    const { data } = await axios.get(url, {
      params: {
        q: process.env.OPENWEATHER_VILLE,
        appid: process.env.OPENWEATHER_API_KEY,
        units: 'metric',
        lang: 'fr',
      },
    });

    await Meteo.findOneAndUpdate(
      { zone: process.env.OPENWEATHER_VILLE },
      {
        temperature: data.main.temp,
        description: data.weather[0].description,
        icone: data.weather[0].icon,
        humidite: data.main.humidity,
        vitesseVent: data.wind.speed,
        source: 'api',
        dateMiseAJour: new Date(),
      },
      { upsert: true, new: true }
    );
    console.log('  Météo mise à jour');
  } catch (err) {
    console.error(' Erreur météo :', err.message);
  }
};

module.exports = { mettreAJourMeteo };
```
Ajoute son propre planning dans le scheduler global (toutes les heures suffit pour la météo) :
```js
cron.schedule('0 * * * *', mettreAJourMeteo);
```

**`meteo.controller.js`**
```js
const Meteo = require('../models/Meteo');

exports.consulterMeteo = async (req, res, next) => {
  try {
    const meteo = await Meteo.findOne().sort({ dateMiseAJour: -1 });
    if (!meteo) return res.status(404).json({ message: 'Aucune donnée météo disponible' });
    res.json(meteo);
  } catch (err) { next(err); }
};

// Cas de secours si l'admin veut publier manuellement (API externe indisponible)
exports.publierMeteoManuelle = async (req, res, next) => {
  try {
    const { zone, temperature, description, icone } = req.body;
    const meteo = await Meteo.create({ zone, temperature, description, icone, source: 'manuel' });
    res.status(201).json(meteo);
  } catch (err) { next(err); }
};
```

**`meteo.routes.js`**
```js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/meteo.controller');

router.get('/', c.consulterMeteo);
router.post('/', proteger, estAdmin, c.publierMeteoManuelle);

module.exports = router;s
```

## A.11 AGDTV (vidéos YouTube)

**`agdtv.service.js`**
```js
const axios = require('axios');
const VideoAGDTV = require('../models/VideoAGDTV');

const synchroniserVideos = async () => {
  try {
    const { data } = await axios.get('https://www.googleapis.com/youtube/v3/search', {
      params: {
        key: process.env.YOUTUBE_API_KEY,
        channelId: process.env.YOUTUBE_CHANNEL_ID,
        part: 'snippet',
        order: 'date',
        maxResults: 15,
        type: 'video',
      },
    });

    for (const item of data.items) {
      await VideoAGDTV.findOneAndUpdate(
        { idYoutube: item.id.videoId },
        {
          titre: item.snippet.title,
          vignette: item.snippet.thumbnails.high.url,
          datePublication: item.snippet.publishedAt,
        },
        { upsert: true }
      );
    }
    console.log(' Vidéos AGDTV synchronisées');
  } catch (err) {
    console.error(' Erreur AGDTV :', err.message);
  }
};

module.exports = { synchroniserVideos };
```
Planning : `cron.schedule('0 */3 * * *', synchroniserVideos);` (toutes les 3 heures, les vidéos changent moins souvent que les articles).

**`agdtv.controller.js`**
```js
const VideoAGDTV = require('../models/VideoAGDTV');

exports.listerVideos = async (req, res, next) => {
  try {
    const videos = await VideoAGDTV.find().sort({ datePublication: -1 });
    res.json(videos);
  } catch (err) { next(err); }
};
```

**`agdtv.routes.js`**
```js
const express = require('express');
const router = express.Router();
const { listerVideos } = require('../controllers/agdtv.controller');
router.get('/', listerVideos);
module.exports = router;
```

## A.12 Formulaire de demande (Request)

**`demande.controller.js`**
```js
const Demande = require('../models/Demande');

exports.envoyerDemande = async (req, res, next) => {
  try {
    const { nom, message } = req.body;
    if (!nom || !message) {
      return res.status(400).json({ message: 'Le nom et le message sont obligatoires' });
    }
    const demande = await Demande.create(req.body);
    res.status(201).json({ message: 'Demande envoyée avec succès', demande });
  } catch (err) { next(err); }
};

// réservé à l'admin
exports.listerDemandes = async (req, res, next) => {
  try {
    const demandes = await Demande.find().sort({ dateEnvoi: -1 });
    res.json(demandes);
  } catch (err) { next(err); }
};

exports.traiterDemande = async (req, res, next) => {
  try {
    const demande = await Demande.findByIdAndUpdate(req.params.id, { statut: 'Traitée' }, { new: true });
    res.json(demande);
  } catch (err) { next(err); }
};
```

**`demande.routes.js`** — avec limitation anti-spam (3 demandes/heure/IP)
```js
const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/demande.controller');

const limiteurDemandes = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: { message: 'Trop de demandes envoyées. Réessayez plus tard.' },
});

router.post('/', limiteurDemandes, c.envoyerDemande);
router.get('/', proteger, estAdmin, c.listerDemandes);
router.put('/:id/traiter', proteger, estAdmin, c.traiterDemande);

module.exports = router;
```

## A.13 Notifications push (FCM)

**`notification.service.js`**
```js
const admin = require('../config/firebase');
const Utilisateur = require('../models/Utilisateur');

const notifierNouvelArticle = async (article) => {
  try {
    // Ne notifie que les utilisateurs ayant choisi cette rubrique (ou qui n'ont pas de préférence = tous)
    const utilisateurs = await Utilisateur.find({
      tokenFCM: { $ne: null },
      $or: [
        { preferencesRubriques: { $size: 0 } },
        { preferencesRubriques: article.categorie },
      ],
    });

    const tokens = utilisateurs.map(u => u.tokenFCM).filter(Boolean);
    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: 'AgriDigitale',
        body: article.titre,
      },
      data: { articleId: article._id.toString(), type: 'nouvel_article' },
    });
    console.log(` Notification envoyée à ${tokens.length} utilisateur(s)`);
  } catch (err) {
    console.error(' Erreur notification :', err.message);
  }
};

const envoyerNotificationManuelle = async (titre, message, tokens) => {
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: titre, body: message },
  });
};

module.exports = { notifierNouvelArticle, envoyerNotificationManuelle };
```

**`notification.controller.js`** — envoi manuel par l'admin
```js
const Utilisateur = require('../models/Utilisateur');
const { envoyerNotificationManuelle } = require('../services/notification.service');

exports.envoyerManuelle = async (req, res, next) => {
  try {
    const { titre, message } = req.body;
    const utilisateurs = await Utilisateur.find({ tokenFCM: { $ne: null } });
    const tokens = utilisateurs.map(u => u.tokenFCM);
    await envoyerNotificationManuelle(titre, message, tokens);
    res.json({ message: `Notification envoyée à ${tokens.length} utilisateur(s)` });
  } catch (err) { next(err); }
};
```

**`notification.routes.js`**
```js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const { envoyerManuelle } = require('../controllers/notification.controller');

router.post('/manuelle', proteger, estAdmin, envoyerManuelle);

module.exports = router;
```

## A.14 Back-office admin (statistiques + gestion)

**`admin.controller.js`**
```js
const Article = require('../models/Article');
const Utilisateur = require('../models/Utilisateur');
const Demande = require('../models/Demande');

exports.statistiques = async (req, res, next) => {
  try {
    const [totalArticles, totalUtilisateurs, demandesEnAttente, articlesParCategorie] = await Promise.all([
      Article.countDocuments(),
      Utilisateur.countDocuments(),
      Demande.countDocuments({ statut: 'Reçue' }),
      Article.aggregate([{ $group: { _id: '$categorie', total: { $sum: 1 } } }]),
    ]);
    const articlesPlusLus = await Article.find().sort({ vues: -1 }).limit(5);

    res.json({ totalArticles, totalUtilisateurs, demandesEnAttente, articlesParCategorie, articlesPlusLus });
  } catch (err) { next(err); }
};

exports.listerUtilisateurs = async (req, res, next) => {
  try {
    const utilisateurs = await Utilisateur.find().select('-tokenFCM');
    res.json(utilisateurs);
  } catch (err) { next(err); }
};

exports.desactiverUtilisateur = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.params.id, { actif: false });
    res.status(204).send();
  } catch (err) { next(err); }
};
```

**`admin.routes.js`**
```js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middlewares/auth.middleware');
const { estAdmin } = require('../middlewares/admin.middleware');
const c = require('../controllers/admin.controller');

router.get('/statistiques', proteger, estAdmin, c.statistiques);
router.get('/utilisateurs', proteger, estAdmin, c.listerUtilisateurs);
router.put('/utilisateurs/:id/desactiver', proteger, estAdmin, c.desactiverUtilisateur);

module.exports = router;
```

## A.15 Assemblage final

**`src/app.js`**
```js
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

app.use(errorHandler); // toujours en dernier

module.exports = app;
```

**`server.js`**
```js
require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { demarrerScheduler } = require('./src/services/rss.service');
const { mettreAJourMeteo } = require('./src/services/meteo.service');
const { synchroniserVideos } = require('./src/services/agdtv.service');
const cron = require('node-cron');

const PORT = process.env.PORT || 5000;

connectDB().then(() => {
  demarrerScheduler();                              // RSS toutes les 15 min
  cron.schedule('0 * * * *', mettreAJourMeteo);      // météo toutes les heures
  cron.schedule('0 */3 * * *', synchroniserVideos);  // AGDTV toutes les 3h
  mettreAJourMeteo();
  synchroniserVideos();

  app.listen(PORT, () => console.log(`🚀 Serveur démarré sur le port ${PORT}`));
});
```

**Étape de vérification obligatoire avant Flutter :** teste chaque endpoint avec Postman/Insomnia. Un backend non testé = des heures perdues côté Flutter à chercher un bug qui n'existe pas côté mobile.

---

# PARTIE B — APPLICATION FLUTTER

## B.1 Installation

```bash
flutter create agridigitale_mobile
cd agridigitale_mobile
flutter pub add dio flutter_secure_storage provider
flutter pub add sqflite path_provider connectivity_plus
flutter pub add firebase_core firebase_messaging
flutter pub add cached_network_image intl url_launcher
flutter pub add shared_preferences
```

**Pourquoi chaque paquet :**
- `dio` : client HTTP plus puissant que `http` (intercepteurs, timeouts, annulation).
- `flutter_secure_storage` : stockage chiffré du JWT (jamais dans `shared_preferences` en clair pour un token sensible).
- `provider` : gestion d'état simple et suffisante pour ce projet.
- `sqflite` + `path_provider` : base locale SQLite pour les favoris hors-ligne.
- `connectivity_plus` : détecter si le téléphone est hors-ligne (afficher le cache local).
- `firebase_core` + `firebase_messaging` : notifications push.
- `cached_network_image` : cache automatique des images d'articles (performance + data mobile).
- `intl` : formatage des dates en français.
- `url_launcher` : ouvrir les vidéos YouTube ou liens sources.
- `shared_preferences` : préférences simples non sensibles (thème, langue).

## B.2 Arborescence complète

```
lib/
├── main.dart
├── core/
│   ├── api_client.dart
│   ├── constants.dart
│   ├── theme.dart
│   └── db_helper.dart              → SQLite pour le cache hors-ligne
├── models/
│   ├── utilisateur.dart
│   ├── article.dart
│   ├── meteo.dart
│   └── video_agdtv.dart
├── services/
│   ├── auth_service.dart
│   ├── article_service.dart
│   ├── favori_service.dart
│   ├── meteo_service.dart
│   ├── agdtv_service.dart
│   ├── demande_service.dart
│   └── notification_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   └── favori_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── article_detail_screen.dart
│   │   └── search_screen.dart
│   ├── weathgr/weather_screen.dart
│   ├── agdtv/agdtv_screen.dart
│   ├── favoris/favoris_screen.dart
│   ├── request/request_screen.dart
│   ├── settings/settings_screen.dart
│   └── main_navigation_screen.dart
└── widgets/
    ├── article_card.dart
    └── etat_erreur.dart            → widget réutilisable pour les erreurs réseau
```

## B.3 Cœur du réseau — `core/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://ton-backend.onrender.com/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token'); // session expirée : déconnexion propre
        }
        handler.next(error);
      },
    ));
  }
}
```
*Ce fichier est un singleton (`factory` + instance unique) : toute l'app utilise la même configuration réseau, un seul endroit à modifier si l'URL du backend change.*

## B.4 Base locale SQLite (favoris hors-ligne) — `core/db_helper.dart`

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'agridigitale.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE favoris_cache (
          id TEXT PRIMARY KEY,
          titre TEXT,
          resume TEXT,
          image TEXT,
          categorie TEXT,
          datePublication TEXT
        )
      '''),
    );
  }

  Future<void> sauvegarderFavori(Map<String, dynamic> article) async {
    final db = await database;
    await db.insert('favoris_cache', article, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> supprimerFavori(String id) async {
    final db = await database;
    await db.delete('favoris_cache', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listerFavorisLocaux() async {
    final db = await database;
    return db.query('favoris_cache');
  }
}
```

## B.5 Modèles

```dart
// models/article.dart
class Article {
  final String id, titre, resume, categorie;
  final String? image, contenu, lienSource;
  final DateTime datePublication;

  Article({
    required this.id, required this.titre, required this.resume,
    required this.categorie, this.image, this.contenu, this.lienSource,
    required this.datePublication,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['_id'],
    titre: json['titre'],
    resume: json['resume'] ?? '',
    categorie: json['categorie'] ?? 'Non classé',
    image: json['image'],
    contenu: json['contenu'],
    lienSource: json['lienSource'],
    datePublication: DateTime.parse(json['datePublication']),
  );

  // pour le cache SQLite (voir db_helper.dart)
  Map<String, dynamic> toSqlite() => {
    'id': id, 'titre': titre, 'resume': resume,
    'image': image, 'categorie': categorie,
    'datePublication': datePublication.toIso8601String(),
  };

  factory Article.fromSqlite(Map<String, dynamic> row) => Article(
    id: row['id'], titre: row['titre'], resume: row['resume'],
    categorie: row['categorie'], image: row['image'],
    datePublication: DateTime.parse(row['datePublication']),
  );
}
```

```dart
// models/meteo.dart
class Meteo {
  final String zone, description, icone;
  final double temperature;
  final int humidite;

  Meteo({required this.zone, required this.description, required this.icone,
         required this.temperature, required this.humidite});

  factory Meteo.fromJson(Map<String, dynamic> json) => Meteo(
    zone: json['zone'], description: json['description'], icone: json['icone'],
    temperature: (json['temperature'] as num).toDouble(),
    humidite: json['humidite'] ?? 0,
  );
}
```

```dart
// models/video_agdtv.dart
class VideoAGDTV {
  final String idYoutube, titre, vignette;
  VideoAGDTV({required this.idYoutube, required this.titre, required this.vignette});

  factory VideoAGDTV.fromJson(Map<String, dynamic> json) => VideoAGDTV(
    idYoutube: json['idYoutube'], titre: json['titre'], vignette: json['vignette'],
  );

  String get urlYoutube => 'https://www.youtube.com/watch?v=$idYoutube';
}
```

## B.6 Services (couche d'accès à l'API)

```dart
// services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthService {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  Future<void> inscrire(String nom, String email, String motDePasse) async {
    final rep = await _dio.post('/auth/inscription', data: {
      'nom': nom, 'email': email, 'motDePasse': motDePasse,
    });
    await _storage.write(key: 'jwt_token', value: rep.data['token']);
  }

  Future<void> connecter(String email, String motDePasse) async {
    final rep = await _dio.post('/auth/connexion', data: {
      'email': email, 'motDePasse': motDePasse,
    });
    await _storage.write(key: 'jwt_token', value: rep.data['token']);
  }

  Future<void> deconnecter() async => _storage.delete(key: 'jwt_token');

  Future<bool> estConnecte() async => (await _storage.read(key: 'jwt_token')) != null;
}
```

```dart
// services/article_service.dart
import '../core/api_client.dart';
import '../models/article.dart';

class ArticleService {
  final _dio = ApiClient().dio;

  Future<List<Article>> lister({String? categorie, int page = 1}) async {
    final rep = await _dio.get('/articles', queryParameters: {
      if (categorie != null) 'categorie': categorie,
      'page': page,
    });
    return (rep.data as List).map((e) => Article.fromJson(e)).toList();
  }

  Future<Article> detail(String id) async {
    final rep = await _dio.get('/articles/$id');
    return Article.fromJson(rep.data);
  }

  Future<List<Article>> rechercher(String motCle) async {
    final rep = await _dio.get('/articles/recherche', queryParameters: {'motCle': motCle});
    return (rep.data as List).map((e) => Article.fromJson(e)).toList();
  }
}
```

```dart
// services/favori_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/api_client.dart';
import '../core/db_helper.dart';
import '../models/article.dart';

class FavoriService {
  final _dio = ApiClient().dio;
  final _db = DBHelper();

  Future<void> ajouter(Article article) async {
    await _dio.post('/favoris', data: {'articleId': article.id});
    await _db.sauvegarderFavori(article.toSqlite()); // copie locale pour le hors-ligne
  }

  Future<void> retirer(String articleId) async {
    await _dio.delete('/favoris/$articleId');
    await _db.supprimerFavori(articleId);
  }

  Future<List<Article>> lister() async {
    final connectivite = await Connectivity().checkConnectivity();
    if (connectivite.contains(ConnectivityResult.none)) {
      // hors-ligne : on lit le cache local SQLite
      final rows = await _db.listerFavorisLocaux();
      return rows.map((r) => Article.fromSqlite(r)).toList();
    }
    // en ligne : on lit le serveur (source de vérité) et on resynchronise le cache
    final rep = await _dio.get('/favoris');
    final articles = (rep.data as List).map((e) => Article.fromJson(e)).toList();
    for (final a in articles) {
      await _db.sauvegarderFavori(a.toSqlite());
    }
    return articles;
  }
}
```

```dart
// services/meteo_service.dart
import '../core/api_client.dart';
import '../models/meteo.dart';

class MeteoService {
  final _dio = ApiClient().dio;
  Future<Meteo> consulter() async {
    final rep = await _dio.get('/meteo');
    return Meteo.fromJson(rep.data);
  }
}
```

```dart
// services/agdtv_service.dart
import '../core/api_client.dart';
import '../models/video_agdtv.dart';

class AgdtvService {
  final _dio = ApiClient().dio;
  Future<List<VideoAGDTV>> lister() async {
    final rep = await _dio.get('/agdtv');
    return (rep.data as List).map((e) => VideoAGDTV.fromJson(e)).toList();
  }
}
```

```dart
// services/demande_service.dart
import '../core/api_client.dart';

class DemandeService {
  final _dio = ApiClient().dio;
  Future<void> envoyer(Map<String, dynamic> donnees) async {
    await _dio.post('/demandes', data: donnees);
  }
}
```

```dart
// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api_client.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _dio = ApiClient().dio;

  Future<void> initialiser() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _dio.post('/auth/token-fcm', data: {'token': token});
    }
    FirebaseMessaging.onMessage.listen((message) {
      // Affiche une bannière in-app ou déclenche un rafraîchissement du fil
    });
  }
}
```

## B.7 Providers (état global partagé)

```dart
// providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  bool connecte = false;

  Future<void> verifierSession() async {
    connecte = await _service.estConnecte();
    notifyListeners();
  }

  Future<void> connecter(String email, String mdp) async {
    await _service.connecter(email, mdp);
    connecte = true;
    notifyListeners();
  }

  Future<void> deconnecter() async {
    await _service.deconnecter();
    connecte = false;
    notifyListeners();
  }
}
```

```dart
// providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getString('theme') == 'sombre') ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> basculer() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _mode == ThemeMode.dark ? 'sombre' : 'clair');
    notifyListeners();
  }
}
```

## B.8 `main.dart` (point d'entrée)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MonApp());
}

class MonApp extends StatelessWidget {
  const MonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..verifierSession()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..charger()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'AgriDigitale',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.clair,
          darkTheme: AppTheme.sombre,
          themeMode: themeProvider.mode,
          home: const PointEntree(),
        ),
      ),
    );
  }
}

class PointEntree extends StatelessWidget {
  const PointEntree({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.connecte) {
      NotificationService().initialiser(); // enregistre le token FCM une fois connecté
      return const MainNavigationScreen();
    }
    return const LoginScreen();
  }
}
```

**`core/theme.dart`**
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get clair => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    useMaterial3: true,
  );

  static ThemeData get sombre => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    useMaterial3: true,
  );
}
```

## B.9 Navigation principale (5 onglets)

```dart
// screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'weather/weather_screen.dart';
import 'agdtv/agdtv_screen.dart';
import 'request/request_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;

  final _ecrans = const [
    HomeScreen(), WeatherScreen(), AgdtvScreen(), RequestScreen(), SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans), // conserve l'état de chaque onglet
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Météo'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'AGDTV'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Demande'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
```
*`IndexedStack` plutôt que `Navigator` classique : chaque onglet garde son état (scroll, données chargées) même quand tu changes d'onglet — meilleure expérience utilisateur.*

## B.10 Écrans d'authentification

```dart
// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await context.read<AuthProvider>().connecter(_emailCtrl.text.trim(), _mdpCtrl.text);
    } catch (_) {
      setState(() => _erreur = 'E-mail ou mot de passe incorrect');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('AgriDigitale', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mdpCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                _chargement
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: _seConnecter, child: const Text('Se connecter')),
                      ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Créer un compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _service = AuthService();
  bool _chargement = false;
  String? _erreur;

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _service.inscrire(_nomCtrl.text.trim(), _emailCtrl.text.trim(), _mdpCtrl.text);
      await context.read<AuthProvider>().verifierSession();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erreur = "Cet e-mail est peut-être déjà utilisé");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null),
              TextFormField(controller: _mdpCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe'),
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null),
              if (_erreur != null) Text(_erreur!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              _chargement
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _sInscrire, child: const Text("S'inscrire")),
            ],
          ),
        ),
      ),
    );
  }
}
```

## B.11 Accueil, détail, recherche

```dart
// widgets/article_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const ArticleCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: article.image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: article.image!, width: 64, height: 64, fit: BoxFit.cover,
                  placeholder: (_, __) => const CircularProgressIndicator(),
                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
                ),
              )
            : const Icon(Icons.article, size: 48),
        title: Text(article.titre, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${article.categorie} · ${DateFormat('dd/MM/yyyy').format(article.datePublication)}',
        ),
      ),
    );
  }
}
```

```dart
// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import 'article_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ArticleService();
  late Future<List<Article>> _future;
  String? _categorieActive;

  final _categories = ['Toutes', 'News', 'Business', 'Agritech'];

  @override
  void initState() {
    super.initState();
    _future = _service.lister();
  }

  void _filtrerParCategorie(String cat) {
    setState(() {
      _categorieActive = cat == 'Toutes' ? null : cat;
      _future = _service.lister(categorie: _categorieActive);
    });
  }

  Future<void> _actualiser() async {
    setState(() => _future = _service.lister(categorie: _categorieActive));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriDigitale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c),
                  selected: (_categorieActive ?? 'Toutes') == c,
                  onSelected: (_) => _filtrerParCategorie(c),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _actualiser,
              child: FutureBuilder<List<Article>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(children: const [
                      Padding(padding: EdgeInsets.all(32),
                        child: Center(child: Text('Impossible de charger les articles. Tirez pour réessayer.'))),
                    ]);
                  }
                  final articles = snapshot.data!;
                  if (articles.isEmpty) {
                    return ListView(children: const [
                      Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun article pour le moment'))),
                    ]);
                  }
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, i) => ArticleCard(
                      article: articles[i],
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: articles[i].id))),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart
// screens/home/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/article_service.dart';
import '../../services/favori_service.dart';
import '../../models/article.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});
  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _articleService = ArticleService();
  final _favoriService = FavoriService();
  late Future<Article> _future;
  bool _favoriTraite = false;

  @override
  void initState() {
    super.initState();
    _future = _articleService.detail(widget.articleId);
  }

  Future<void> _basculerFavori(Article article) async {
    setState(() => _favoriTraite = true);
    try {
      await _favoriService.ajouter(article);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté aux favoris')));
    } catch (_) {
      // déjà en favoris ou erreur réseau : on ignore silencieusement ici, gérable via un état plus fin
    } finally {
      if (mounted) setState(() => _favoriTraite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Article>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final article = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: article.image != null
                      ? CachedNetworkImage(imageUrl: article.image!, fit: BoxFit.cover)
                      : Container(color: Colors.green.shade100),
                ),
                actions: [
                  IconButton(
                    icon: _favoriTraite
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.favorite_border),
                    onPressed: _favoriTraite ? null : () => _basculerFavori(article),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.titre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(article.contenu ?? article.resume, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 20),
                      if (article.lienSource != null)
                        TextButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Voir la source originale'),
                          onPressed: () => launchUrl(Uri.parse(article.lienSource!)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

```dart
// screens/home/search_screen.dart
import 'package:flutter/material.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import 'article_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = ArticleService();
  final _controller = TextEditingController();
  List<Article> _resultats = [];
  bool _chargement = false;

  Future<void> _rechercher(String motCle) async {
    if (motCle.trim().isEmpty) { setState(() => _resultats = []); return; }
    setState(() => _chargement = true);
    try {
      final resultats = await _service.rechercher(motCle.trim());
      setState(() => _resultats = resultats);
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Rechercher un article...', border: InputBorder.none),
          onSubmitted: _rechercher,
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _resultats.length,
              itemBuilder: (context, i) => ArticleCard(
                article: _resultats[i],
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: _resultats[i].id))),
              ),
            ),
    );
  }
}
```

## B.12 Météo, AGDTV, Favoris

```dart
// screens/weather/weather_screen.dart
import 'package:flutter/material.dart';
import '../../services/meteo_service.dart';
import '../../models/meteo.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service = MeteoService();
  late Future<Meteo> _future;

  @override
  void initState() { super.initState(); _future = _service.consulter(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Météo')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _service.consulter()),
        child: FutureBuilder<Meteo>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final m = snapshot.data!;
            return ListView(
              children: [
                const SizedBox(height: 40),
                Center(child: Image.network('https://openweathermap.org/img/wn/${m.icone}@4x.png')),
                Center(child: Text('${m.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold))),
                Center(child: Text(m.description, style: const TextStyle(fontSize: 18))),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Column(children: [const Icon(Icons.water_drop), Text('${m.humidite}%')]),
                    Column(children: [const Icon(Icons.location_on), Text(m.zone)]),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

```dart
// screens/agdtv/agdtv_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/agdtv_service.dart';
import '../../models/video_agdtv.dart';

class AgdtvScreen extends StatefulWidget {
  const AgdtvScreen({super.key});
  @override
  State<AgdtvScreen> createState() => _AgdtvScreenState();
}

class _AgdtvScreenState extends State<AgdtvScreen> {
  final _service = AgdtvService();
  late Future<List<VideoAGDTV>> _future;

  @override
  void initState() { super.initState(); _future = _service.lister(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AGDTV')),
      body: FutureBuilder<List<VideoAGDTV>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final videos = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.9),
            itemCount: videos.length,
            itemBuilder: (context, i) {
              final v = videos[i];
              return GestureDetector(
                onTap: () => launchUrl(Uri.parse(v.urlYoutube), mode: LaunchMode.externalApplication),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.network(v.vignette, fit: BoxFit.cover, width: double.infinity))),
                    Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(v.titre, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

```dart
// screens/favoris/favoris_screen.dart
import 'package:flutter/material.dart';
import '../../services/favori_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../home/article_detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});
  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _service = FavoriService();
  late Future<List<Article>> _future;

  @override
  void initState() { super.initState(); _future = _service.lister(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final favoris = snapshot.data!;
          if (favoris.isEmpty) return const Center(child: Text('Aucun favori pour le moment'));
          return ListView.builder(
            itemCount: favoris.length,
            itemBuilder: (context, i) => Dismissible(
              key: Key(favoris[i].id),
              onDismissed: (_) => _service.retirer(favoris[i].id),
              background: Container(color: Colors.red, alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
              child: ArticleCard(
                article: favoris[i],
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: favoris[i].id))),
              ),
            ),
          );
        },
      ),
    );
  }
}
```
*Note : ajoute `FavorisScreen` comme 6ᵉ onglet ou accessible depuis les paramètres/l'accueil selon ta maquette finale.*

## B.13 Demande (Request) et Paramètres

```dart
// screens/request/request_screen.dart
import 'package:flutter/material.dart';
import '../../services/demande_service.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});
  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DemandeService();
  final _nom = TextEditingController(), _profession = TextEditingController(),
        _adresse = TextEditingController(), _email = TextEditingController(),
        _telephone = TextEditingController(), _message = TextEditingController();
  String? _categorie;
  bool _envoi = false;

  final _categories = ['Suggestion', 'Réclamation', 'Partenariat', 'Autre'];

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await _service.envoyer({
        'nom': _nom.text, 'profession': _profession.text, 'adresse': _adresse.text,
        'email': _email.text, 'telephone': _telephone.text,
        'categorie': _categorie, 'message': _message.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée avec succès')));
        _formKey.currentState!.reset();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'envoi. Réessayez.")));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faire une demande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) => v!.isEmpty ? 'Champ obligatoire' : null),
            TextFormField(controller: _profession, decoration: const InputDecoration(labelText: 'Profession')),
            TextFormField(controller: _adresse, decoration: const InputDecoration(labelText: 'Adresse')),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail')),
            TextFormField(controller: _telephone, decoration: const InputDecoration(labelText: 'Téléphone')),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categorie = v),
            ),
            TextFormField(controller: _message, maxLines: 4, decoration: const InputDecoration(labelText: 'Message'),
              validator: (v) => v!.isEmpty ? 'Champ obligatoire' : null),
            const SizedBox(height: 20),
            _envoi
                ? const CircularProgressIndicator()
                : SizedBox(width: double.infinity,
                    child: ElevatedButton(onPressed: _envoyer, child: const Text('Envoyer'))),
          ]),
        ),
      ),
    );
  }
}
```

```dart
// screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Thème sombre'),
            value: themeProvider.mode == ThemeMode.dark,
            onChanged: (_) => themeProvider.basculer(),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue'),
            subtitle: const Text('Français'),
            onTap: () {}, // à étendre si multilingue nécessaire
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos d’AgriDigitale'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () => context.read<AuthProvider>().deconnecter(),
          ),
        ],
      ),
    );
  }
}
```

---

# PARTIE C — CHECKLIST FINALE AVANT SOUTENANCE

1. **Backend** : les 8 routes principales répondent sur Postman (`auth`, `articles`, `favoris`, `meteo`, `agdtv`, `demandes`, `notifications`, `admin`).
2. **RSS** : le scheduler tourne, les articles arrivent sans doublon (vérifie en base que `guid` est bien unique).
3. **Flutter** : connexion/inscription fonctionnent avec l'API réelle (pas de mock).
4. **Favoris hors-ligne** : coupe le Wi-Fi, l'écran Favoris affiche quand même le cache SQLite.
5. **Push** : ajoute un article manuellement en base, vérifie la réception de la notification sur un téléphone réel (l'émulateur ne reçoit pas toujours les push Firebase correctement).
6. **Déploiement** : backend sur Render/Railway avec variables d'environnement configurées, MongoDB Atlas en production, APK signé généré (`flutter build apk --release`).
7. **Documentation** : chaque endpoint listé avec méthode/paramètres/réponse en annexe de ton rapport.

Ce document couvre l'ensemble du projet tel que défini dans ton cahier des charges. Développe module par module, teste chaque étape avant de passer à la suivante, et garde ce fichier comme référence tout au long du stage.