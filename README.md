# 🌾 AgriDigitale

Application mobile complète pour l'entreprise AgriDigitale - Plateforme d'information agricole avec actualités, météo, vidéos et communauté.

---

## 📋 Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Technologies](#-technologies)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Documentation](#-documentation)
- [Déploiement](#-déploiement)
- [Contribution](#-contribution)
- [Licence](#-licence)

---

## ✨ Fonctionnalités

### Utilisateur
- **Authentification** - Inscription, connexion, réinitialisation mot de passe
- **Articles** - Actualités agricoles avec catégories et recherche
- **Favoris** - Sauvegarder les articles préférés
- **Commentaires** - Interagir sur les articles
- **Météo** - Prévisions météo en temps réel
- **AGDTV** - Lecteur de vidéos YouTube intégré
- **Notifications Push** - Alertes en temps réel via Firebase
- **Profil** - Gestion du profil et préférences
- **Mode Sombre/Clair** - Thème personnalisable
- **Multilangue** - Français et Anglais

### Administrateur
- **Dashboard** - Statistiques globales
- **Gestion Utilisateurs** - Promouvoir, rétrograder, désactiver
- **Bannières** - Gérer les publicités et promotions
- **Notifications** - Envoyer des alertes à tous les utilisateurs
- **Météo Manuelle** - Publier des prévisions personnalisées
- **Demandes** - Gérer les messages de support

---

## 🛠️ Technologies

### Backend
| Technologie | Version | Usage |
|-------------|---------|-------|
| Node.js | ≥ 18.x | Runtime |
| Express | 5.x | Framework web |
| MongoDB | - | Base de données |
| Mongoose | 9.x | ODM MongoDB |
| JWT | - | Authentification |
| Firebase Admin | 14.x | Notifications push |
| Node-cron | - | Tâches planifiées |

### Frontend
| Technologie | Version | Usage |
|-------------|---------|-------|
| Flutter | ≥ 3.10 | Framework mobile |
| Dart | ≥ 3.10 | Langage |
| Provider | - | State management |
| Firebase Messaging | 15.x | Notifications push |
| HTTP | 1.x | Client API |

---

## 🏗️ Architecture

```
AgriDigitale/
├── backend/                    # API REST
│   ├── src/
│   │   ├── config/            # Configuration
│   │   ├── controllers/       # Logique métier
│   │   ├── middlewares/       # Auth, sécurité
│   │   ├── models/           # Schémas MongoDB
│   │   ├── routes/           # Endpoints API
│   │   └── services/         # Services (RSS, météo...)
│   └── server.js             # Point d'entrée
│
├── frontend/
│   └── frontend/             # App Flutter
│       └── lib/
│           ├── core/         # Thème, constantes
│           ├── models/       # Modèles Dart
│           ├── providers/    # State management
│           ├── screens/      # Écrans
│           ├── services/     # Services API
│           └── widgets/      # Widgets réutilisables
│
├── DOC_API.md                # Documentation API
└── GUIDE_INSTALLATION.md     # Guide d'installation
```

---

## 🚀 Installation

### Prérequis
- Node.js ≥ 18.x
- Flutter ≥ 3.10.x
- MongoDB (local ou Atlas)

### Backend

```bash
# Cloner le repository
git clone https://github.com/votre-utilisateur/AgriDigitale.git
cd AgriDigitale/backend

# Installer les dépendances
npm install

# Configurer les variables d'environnement
cp .env.example .env
# Éditer le fichier .env avec vos informations

# Démarrer le serveur
npm run dev
```

### Frontend

```bash
# Naviguer vers le dossier frontend
cd ../frontend/frontend

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

📖 **Guide détaillé :** [GUIDE_INSTALLATION.md](GUIDE_INSTALLATION.md)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [DOC_API.md](AgriDigitale/DOC_API.md) | Documentation complète de l'API REST |
| [GUIDE_INSTALLATION.md](GUIDE_INSTALLATION.md) | Guide d'installation et configuration |

### Points d'entrée API

| Endpoint | Description |
|----------|-------------|
| `POST /api/auth/inscription` | Créer un compte |
| `POST /api/auth/connexion` | Se connecter |
| `GET /api/articles` | Lister les articles |
| `GET /api/meteo` | Consulter la météo |
| `GET /api/agdtv` | Lister les vidéos |

🔗 **URL de production :** `https://agridigitale-production.up.railway.app`

---

## 🌐 Déploiement

### Backend (Railway)
1. Connecter votre repository GitHub à Railway
2. Ajouter les variables d'environnement
3. Déployer automatiquement

### Frontend Web (Vercel)
```bash
flutter build web
# Déployer le dossier build/web sur Vercel
```

### App Mobile
```bash
# Android
flutter build apk --release

# iOS (nécessite Mac)
flutter build ios --release
```

---

## 🔒 Sécurité

- ✅ Mots de passe hashés avec bcrypt
- ✅ Authentification JWT avec expiration
- ✅ Rate limiting sur les endpoints sensibles
- ✅ CORS configuré
- ✅ Variables d'environnement pour les secrets
- ✅ Helmet pour les headers de sécurité

---

## 📊 Fonctionnalités Techniques

| Fonctionnalité | Implémentation |
|----------------|----------------|
| RSS Auto-update | Toutes les 15 minutes via node-cron |
| Météo | OpenWeatherMap API + cache |
| Vidéos | YouTube Data API v3 |
| Notifications | Firebase Cloud Messaging |
| Emails | Gmail API + Resend |
| Images | Proxy CORS + cache 24h |

---

## 👥 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit (`git commit -m 'Ajouter nouvelle fonctionnalité'`)
4. Push (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

---

## 📞 Contact

- **Email :** devromarictec@gmail.com
- **Site :** https://agridigitale.net

---

## 📄 Licence

Ce projet est privé. Tous droits réservés.
