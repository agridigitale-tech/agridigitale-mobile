# Guide de développement — Application mobile AgriDigitale
### De la pré-programmation au déploiement

Ce guide part du principe que ta pré-programmation (cahier des charges, diagrammes de cas d'utilisation, diagramme de classes, DA01/DA02, DS01/DS02) est terminée et validée. On attaque maintenant le **développement**, dans l'ordre où tu dois réellement le faire.

---

## 0. Vue d'ensemble de l'architecture

```
┌─────────────────┐      HTTPS / REST API       ┌──────────────────────┐
│  App Flutter     │ ───────────────────────────▶│  Backend Node.js/Express │
│ (Android/iOS)    │◀─────────────────────────── │  + MongoDB              │
└─────────────────┘         JSON + JWT           └──────────────────────┘
                                                        │
                                                        ├─ Scheduler (node-cron)
                                                        │   → interroge agridigitale.net/feed
                                                        │   toutes les 15 min (rss-parser)
                                                        │
                                                        ├─ Firebase Cloud Messaging (push)
                                                        └─ API météo tierce (OpenWeather)
```

**Pourquoi commencer par le backend ?** Parce que Flutter va consommer une API qui n'existe pas encore. Si tu commences par Flutter, tu devras mocker les données puis tout recâbler plus tard. Le trajet le plus efficace est :

1. Backend (base de données → modèles → RSS service → auth → API REST)
2. Flutter (architecture → écrans → connexion à l'API réelle)
3. Notifications push
4. Tests + déploiement

---

## PHASE 1 — Mise en place de l'environnement

### 1.1 Outils à installer
- Node.js LTS (v20+) + npm
- MongoDB (local via Docker, ou MongoDB Atlas gratuit pour éviter d'installer en local)
- Flutter SDK (dernière version stable) + Android Studio (émulateur + SDK)
- VS Code avec extensions : Dart, Flutter, ESLint, MongoDB for VS Code
- Postman ou Insomnia (tester l'API avant de coder Flutter)
- Git + un dépôt GitHub (privé)

### 1.2 Structure du dépôt Git

```
agridigitale-mobile/
├── backend/          → API Node.js/Express
├── mobile/           → App Flutter
├── docs/             → tes diagrammes UML, cahier des charges (déjà faits)
└── README.md
```

Un seul dépôt monorepo est plus simple à gérer en binôme qu'un repo par personne, mais chacun travaille sur ses dossiers/modules avec des branches (`git checkout -b feature/auth-roma`, `feature/rss-binome`, etc.).

---

## PHASE 2 — Backend Node.js (fondations)

### 2.1 Initialisation

```bash
mkdir backend && cd backend
npm init -y
npm install express mongoose dotenv cors helmet morgan bcryptjs jsonwebtoken
npm install rss-parser node-cron
npm install --save-dev nodemon
```

### 2.2 Arborescence du backend

```
backend/
├── src/
│   ├── config/
│   │   └── db.js                 → connexion MongoDB
│   ├── models/
│   │   ├── Utilisateur.js
│   │   ├── Article.js
│   │   ├── Categorie.js
│   │   ├── Favori.js
│   │   ├── Notification.js
│   │   ├── Meteo.js
│   │   ├── Demande.js
│   │   ├── FeedRSS.js
│   │   └── Parametre.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── article.controller.js
│   │   ├── favori.controller.js
│   │   ├── meteo.controller.js
│   │   ├── demande.controller.js
│   │   └── admin.controller.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── article.routes.js
│   │   ├── favori.routes.js
│   │   ├── meteo.routes.js
│   │   ├── demande.routes.js
│   │   └── admin.routes.js
│   ├── middlewares/
│   │   ├── auth.middleware.js     → vérifie le JWT
│   │   └── admin.middleware.js    → vérifie le rôle admin
│   ├── services/
│   │   ├── rss.service.js         → parsing + dédup + scheduler
│   │   └── notification.service.js
│   └── app.js
├── .env
├── server.js
└── package.json
```

### 2.3 Connexion à la base de données — `src/config/db.js`

```js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connecté');
  } catch (err) {
    console.error('Erreur de connexion MongoDB :', err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
```

`.env` :
```
PORT=5000
MONGO_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/agridigitale
JWT_SECRET=une_longue_chaine_secrete
JWT_EXPIRES_IN=7d
RSS_FEED_URL=https://agridigitale.net/feed
```

### 2.4 Les modèles (Mongoose) — basés sur ton diagramme de classes

**`Utilisateur.js`**
```js
const mongoose = require('mongoose');

const utilisateurSchema = new mongoose.Schema({
  nom: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  motDePasse: { type: String, required: true }, // haché avec bcrypt
  photo: { type: String, default: null },
  role: { type: String, enum: ['utilisateur', 'administrateur'], default: 'utilisateur' },
  preferencesRubriques: [{ type: String }], // pour les notifications ciblées
  dateCreation: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Utilisateur', utilisateurSchema);
```

**`Article.js`**
```js
const mongoose = require('mongoose');

const articleSchema = new mongoose.Schema({
  guid: { type: String, required: true, unique: true }, // vient du flux RSS, évite les doublons
  titre: { type: String, required: true },
  contenu: { type: String },       // texte nettoyé (HTML retiré)
  resume: { type: String },
  image: { type: String },
  lienSource: { type: String },
  categorie: { type: String, index: true }, // Home, News, Business, Agritech...
  datePublication: { type: Date, required: true },
  dateRecuperation: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Article', articleSchema);
```

**`Favori.js`**
```js
const mongoose = require('mongoose');

const favoriSchema = new mongoose.Schema({
  utilisateur: { type: mongoose.Schema.Types.ObjectId, ref: 'Utilisateur', required: true },
  article: { type: mongoose.Schema.Types.ObjectId, ref: 'Article', required: true },
  dateAjout: { type: Date, default: Date.now }
});

favoriSchema.index({ utilisateur: 1, article: 1 }, { unique: true }); // évite les doublons

module.exports = mongoose.model('Favori', favoriSchema);
```

**`Demande.js`** (module Request)
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
  dateEnvoi: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Demande', demandeSchema);
```

**`Meteo.js`**
```js
const mongoose = require('mongoose');

const meteoSchema = new mongoose.Schema({
  titre: String,
  texte: String,
  zone: String,
  temperature: Number,
  image: String,
  datePublication: { type: Date, default: Date.now },
  actif: { type: Boolean, default: true } // un seul bulletin actif à la fois
});

module.exports = mongoose.model('Meteo', meteoSchema);
```

Fais de même pour `Categorie`, `Notification`, `FeedRSS`, `Parametre` en reprenant les attributs de ton diagramme de classes (DC03).

---

## PHASE 3 — Authentification (Module 1)

C'est ton module, donc je détaille bien : c'est la base de tout (JWT utilisé partout ensuite).

### 3.1 Middleware d'authentification — `auth.middleware.js`

```js
const jwt = require('jsonwebtoken');

const proteger = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Accès refusé, jeton manquant' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.utilisateurId = decoded.id;
    req.role = decoded.role;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Jeton invalide ou expiré' });
  }
};

module.exports = { proteger };
```

### 3.2 Contrôleur d'authentification — `auth.controller.js`

```js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Utilisateur = require('../models/Utilisateur');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

exports.inscrire = async (req, res) => {
  try {
    const { nom, email, motDePasse } = req.body;
    if (!nom || !email || !motDePasse) {
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
    }
    const existe = await Utilisateur.findOne({ email });
    if (existe) return res.status(409).json({ message: 'Cet e-mail est déjà utilisé' });

    const motDePasseHache = await bcrypt.hash(motDePasse, 10);
    const utilisateur = await Utilisateur.create({ nom, email, motDePasse: motDePasseHache });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.status(201).json({ token, utilisateur: { id: utilisateur._id, nom, email } });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur', error: err.message });
  }
};

exports.connecter = async (req, res) => {
  try {
    const { email, motDePasse } = req.body;
    const utilisateur = await Utilisateur.findOne({ email });
    if (!utilisateur) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const motDePasseValide = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
    if (!motDePasseValide) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.json({ token, utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email, role: utilisateur.role } });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur', error: err.message });
  }
};
```

Ceci correspond exactement à ton diagramme de séquence DS01 : saisie → validation format → requête POST → vérification → JWT → stockage local (côté Flutter) → redirection.

### 3.3 Routes — `auth.routes.js`

```js
const express = require('express');
const router = express.Router();
const { inscrire, connecter } = require('../controllers/auth.controller');

router.post('/inscription', inscrire);
router.post('/connexion', connecter);

module.exports = router;
```

---

## PHASE 4 — Service RSS (Module 2, le cœur du système)

C'est le module de ton binôme, mais tu dois comprendre comment il alimente ton fil d'actualités (Module 2 côté frontend).

### 4.1 Service de récupération — `rss.service.js`

```js
const Parser = require('rss-parser');
const cron = require('node-cron');
const Article = require('../models/Article');

const parser = new Parser({
  customFields: { item: ['category'] }
});

const nettoyerHTML = (html = '') =>
  html.replace(/<[^>]*>?/gm, '').replace(/&nbsp;/g, ' ').trim();

const recupererFlux = async () => {
  try {
    const feed = await parser.parseURL(process.env.RSS_FEED_URL);
    for (const item of feed.items) {
      const existe = await Article.findOne({ guid: item.guid });
      if (existe) continue; // déduplication

      await Article.create({
        guid: item.guid,
        titre: item.title,
        contenu: nettoyerHTML(item['content:encoded'] || item.content),
        resume: nettoyerHTML(item.contentSnippet || item.description),
        lienSource: item.link,
        categorie: item.categories ? item.categories[0] : 'Non classé',
        datePublication: new Date(item.pubDate)
      });
      // TODO : déclencher ici la notification push pour les nouveaux articles
    }
    console.log(`Flux RSS synchronisé : ${feed.items.length} éléments traités`);
  } catch (err) {
    console.error('Erreur récupération RSS :', err.message);
  }
};

const demarrerScheduler = () => {
  // toutes les 15 minutes, comme prévu dans le cahier des charges
  cron.schedule('*/15 * * * *', recupererFlux);
  recupererFlux(); // exécution immédiate au démarrage
};

module.exports = { demarrerScheduler, recupererFlux };
```

Ceci correspond à ton DA02 (Récupérer le flux RSS) et DS02 : interroger le flux → parser XML → nettoyer/dédupliquer → enregistrer → notifier.

### 4.2 Activer le scheduler dans `server.js`

```js
require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { demarrerScheduler } = require('./src/services/rss.service');

const PORT = process.env.PORT || 5000;

connectDB().then(() => {
  demarrerScheduler();
  app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));
});
```

---

## PHASE 5 — API REST des articles (ton module Home/Fil d'actualités)

### 5.1 Contrôleur — `article.controller.js`

```js
const Article = require('../models/Article');

exports.listerArticles = async (req, res) => {
  const { categorie, page = 1, limite = 10 } = req.query;
  const filtre = categorie ? { categorie } : {};

  const articles = await Article.find(filtre)
    .sort({ datePublication: -1 })
    .skip((page - 1) * limite)
    .limit(Number(limite));

  res.json(articles);
};

exports.detailArticle = async (req, res) => {
  const article = await Article.findById(req.params.id);
  if (!article) return res.status(404).json({ message: 'Article introuvable' });
  res.json(article);
};

exports.rechercherArticles = async (req, res) => {
  const { motCle } = req.query;
  const articles = await Article.find({
    $or: [
      { titre: { $regex: motCle, $options: 'i' } },
      { contenu: { $regex: motCle, $options: 'i' } }
    ]
  }).sort({ datePublication: -1 });
  res.json(articles);
};
```

### 5.2 Routes — `article.routes.js`

```js
const express = require('express');
const router = express.Router();
const { listerArticles, detailArticle, rechercherArticles } = require('../controllers/article.controller');

router.get('/', listerArticles);          // GET /api/articles?categorie=News&page=1
router.get('/recherche', rechercherArticles); // GET /api/articles/recherche?motCle=maïs
router.get('/:id', detailArticle);

module.exports = router;
```

### 5.3 Assemblage dans `app.js`

```js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/articles', require('./routes/article.routes'));
app.use('/api/favoris', require('./routes/favori.routes'));
app.use('/api/meteo', require('./routes/meteo.routes'));
app.use('/api/demandes', require('./routes/demande.routes'));
app.use('/api/admin', require('./routes/admin.routes'));

module.exports = app;
```

À ce stade, **teste tout avec Postman avant de toucher à Flutter**. C'est une étape non négociable : si l'API ne répond pas correctement ici, tu perdras du temps à déboguer côté Flutter en pensant que c'est ton code mobile qui a un bug.

---

## PHASE 6 — Favoris (ton module)

```js
// favori.controller.js
const Favori = require('../models/Favori');

exports.ajouterFavori = async (req, res) => {
  try {
    const favori = await Favori.create({ utilisateur: req.utilisateurId, article: req.body.articleId });
    res.status(201).json(favori);
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ message: 'Déjà en favoris' });
    res.status(500).json({ message: err.message });
  }
};

exports.retirerFavori = async (req, res) => {
  await Favori.deleteOne({ utilisateur: req.utilisateurId, article: req.params.articleId });
  res.status(204).send();
};

exports.listerFavoris = async (req, res) => {
  const favoris = await Favori.find({ utilisateur: req.utilisateurId }).populate('article');
  res.json(favoris.map(f => f.article));
};
```

Routes protégées par le middleware `proteger` :

```js
router.post('/', proteger, ajouterFavori);
router.delete('/:articleId', proteger, retirerFavori);
router.get('/', proteger, listerFavoris);
```

---

## PHASE 7 — Application Flutter

### 7.1 Création et dépendances

```bash
flutter create mobile
cd mobile
flutter pub add http dio flutter_secure_storage provider go_router
flutter pub add shared_preferences cached_network_image
flutter pub add firebase_core firebase_messaging
```

### 7.2 Arborescence recommandée (architecture par fonctionnalité)

```
lib/
├── main.dart
├── core/
│   ├── api_client.dart          → configuration Dio (base URL, intercepteur JWT)
│   ├── constants.dart
│   └── theme.dart
├── models/
│   ├── utilisateur.dart
│   ├── article.dart
│   └── meteo.dart
├── services/
│   ├── auth_service.dart
│   ├── article_service.dart
│   ├── favori_service.dart
│   └── notification_service.dart
├── providers/                    → gestion d'état (Provider)
│   ├── auth_provider.dart
│   ├── article_provider.dart
│   └── favori_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── article_detail_screen.dart
│   ├── weather/
│   ├── agdtv/
│   ├── favoris/
│   ├── request/
│   └── settings/
├── widgets/
│   ├── article_card.dart
│   └── bottom_nav_bar.dart
└── routes/
    └── app_router.dart
```

### 7.3 Client API centralisé — `core/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://ton-backend.onrender.com/api',
      connectTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Gestion centralisée des erreurs 401 → déconnexion automatique
        handler.next(error);
      },
    ));
  }
}
```

Ce fichier est important : c'est lui qui attache automatiquement le token JWT à chaque requête, tu n'as pas à le refaire dans chaque écran.

### 7.4 Modèle — `models/article.dart`

```dart
class Article {
  final String id;
  final String titre;
  final String resume;
  final String? image;
  final String categorie;
  final DateTime datePublication;

  Article({
    required this.id,
    required this.titre,
    required this.resume,
    this.image,
    required this.categorie,
    required this.datePublication,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'],
      titre: json['titre'],
      resume: json['resume'] ?? '',
      image: json['image'],
      categorie: json['categorie'] ?? '',
      datePublication: DateTime.parse(json['datePublication']),
    );
  }
}
```

### 7.5 Service Auth — `services/auth_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthService {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  Future<void> connecter(String email, String motDePasse) async {
    final reponse = await _dio.post('/auth/connexion', data: {
      'email': email,
      'motDePasse': motDePasse,
    });
    await _storage.write(key: 'jwt_token', value: reponse.data['token']);
  }

  Future<void> deconnecter() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> estConnecte() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
```

### 7.6 Écran de connexion — `screens/auth/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _authService = AuthService();
  bool _chargement = false;
  String? _erreur;

  Future<void> _seConnecter() async {
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _authService.connecter(_emailCtrl.text.trim(), _mdpCtrl.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _erreur = 'E-mail ou mot de passe incorrect');
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail')),
            TextField(controller: _mdpCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
            if (_erreur != null) Text(_erreur!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            _chargement
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _seConnecter, child: const Text('Se connecter')),
          ],
        ),
      ),
    );
  }
}
```

### 7.7 Service articles + écran d'accueil

```dart
// services/article_service.dart
import '../core/api_client.dart';
import '../models/article.dart';

class ArticleService {
  final _dio = ApiClient().dio;

  Future<List<Article>> listerArticles({String? categorie, int page = 1}) async {
    final reponse = await _dio.get('/articles', queryParameters: {
      if (categorie != null) 'categorie': categorie,
      'page': page,
    });
    return (reponse.data as List).map((e) => Article.fromJson(e)).toList();
  }
}
```

```dart
// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ArticleService();
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = _service.listerArticles();
  }

  Future<void> _actualiser() async {
    setState(() => _articlesFuture = _service.listerArticles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgriDigitale')),
      body: RefreshIndicator(
        onRefresh: _actualiser,
        child: FutureBuilder<List<Article>>(
          future: _articlesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Erreur de chargement'));
            }
            final articles = snapshot.data!;
            return ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(articles[i].titre),
                subtitle: Text(articles[i].resume, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pushNamed(context, '/article', arguments: articles[i].id),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

Ce pattern (Service → FutureBuilder → ListView + RefreshIndicator pour le pull-to-refresh) est celui que tu réutiliseras pour Favoris, Recherche, et AGDTV.

### 7.8 Navigation bas de page (5 onglets)

```dart
// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int indexActuel;
  final Function(int) onChange;
  const BottomNavBar({super.key, required this.indexActuel, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indexActuel,
      onTap: onChange,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Météo'),
        BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'AGDTV'),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Demande'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
      ],
    );
  }
}
```

---

## PHASE 8 — Notifications push (module partagé)

Côté backend, quand un nouvel article est enregistré, tu déclenches un envoi FCM ciblé selon les `preferencesRubriques` des utilisateurs. Côté Flutter :

```dart
// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialiser() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    // Envoyer ce token au backend pour l'associer à l'utilisateur
    FirebaseMessaging.onMessage.listen((message) {
      // Afficher une notification locale ou une bannière in-app
    });
  }
}
```

Il te faudra créer un projet Firebase, télécharger `google-services.json`, et l'ajouter à `android/app/`.

---

## PHASE 9 — Ordre de développement recommandé (semaine par semaine, ton côté)

| Semaine | Ce que tu développes |
|---|---|
| 1 | Backend : DB + modèles + auth complet (inscription/connexion/JWT), testé sur Postman |
| 2 | Backend : API articles (liste, détail, recherche) + Flutter : setup projet, ApiClient, écrans login/register |
| 3 | Flutter : écran Accueil (fil d'actualités) + détail article, connectés à l'API réelle |
| 4 | Favoris (backend + écran Flutter) + hors-ligne (cache local avec `shared_preferences` ou `sqflite`) |
| 5 | Paramètres (langue, thème sombre) + module Request (formulaire + API) |
| 6 | Notifications push + tests globaux + corrections de bugs |

---

## PHASE 10 — Tests et déploiement

1. **Backend** : déployer sur Render ou Railway (comme prévu au cahier des charges). Configurer les variables d'environnement sur la plateforme (ne jamais commiter `.env`).
2. **Base de données** : MongoDB Atlas (cluster gratuit M0 suffisant pour la démonstration).
3. **Flutter** : générer l'APK de test avec `flutter build apk --release`, l'installer sur un téléphone Android réel pour valider avant la soutenance.
4. **Tests manuels prioritaires** : inscription/connexion, chargement du fil au démarrage, pull-to-refresh, ajout/retrait de favoris, envoi d'une demande, réception d'une notification push après ajout d'un article côté RSS.

---

## Points de vigilance pour ton rapport de stage

- Documente chaque endpoint API (méthode, URL, paramètres, réponse) — ça devient l'annexe technique de ton rapport.
- Garde des captures d'écran à chaque étape clé (login, accueil, favoris) pour illustrer la section "Présentation de l'application".
- Note bien la frontière : toi = authentification, accueil/articles, favoris, paramètres, demandes ; ton binôme = RSS, météo admin, AGDTV, notifications serveur, back-office. Le code que je t'ai donné pour le service RSS sert à ta compréhension, mais dans le rapport, attribue-le clairement à ton binôme.
