# 🚀 Guide d'Installation AgriDigitale

## Prérequis

### Backend
- **Node.js** ≥ 18.x
- **npm** ≥ 9.x
- **MongoDB** (local ou Atlas)

### Frontend
- **Flutter** ≥ 3.10.x
- **Dart** ≥ 3.10.x
- **Android Studio** / **VS Code** avec extensions Flutter

---

## 📦 Installation Backend

### 1. Cloner le repository

```bash
git clone https://github.com/votre-utilisateur/AgriDigitale.git
cd AgriDigitale/backend
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer les variables d'environnement

Créer un fichier `.env` à la racine du dossier `backend` :

```env
# Serveur
PORT=5000

# MongoDB
MONGO_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/agridigitale

# JWT
JWT_SECRET=votre_secret_jwt_ici
JWT_EXPIRES_IN=7d
JWT_RESET_SECRET=votre_reset_secret_ici

# RSS
RSS_FEED_URL=https://agridigitale.net/feed

# Gmail API (pour envoi d'emails)
GMAIL_CLIENT_ID=votre_client_id
GMAIL_CLIENT_SECRET=votre_client_secret
GMAIL_REFRESH_TOKEN=votre_refresh_token
SMTP_USER=votre_email@gmail.com

# OpenWeatherMap (météo)
OPENWEATHER_API_KEY=votre_api_key
OPENWEATHER_VILLE=Lome,TG

# Resend (alternative emails)
RESEND_API_KEY=votre_clé_resend

# YouTube API (AGDTV)
YOUTUBE_API_KEY=votre_youtube_api_key
YOUTUBE_CHANNEL_ID=UCc-oD_vR9ilzlyeZKemRZ-w

# Firebase (notifications push)
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}

# Admin par défaut
ADMIN_EMAIL=admin@votre-domaine.com
ADMIN_PASS=votre_mot_de_passe_admin
ADMIN_NOM=Administrateur
```

### 4. Démarrer le serveur

```bash
# Mode développement (avec auto-reload)
npm run dev

# Mode production
npm start
```

Le serveur sera disponible sur `http://localhost:5000`

---

## 📱 Installation Frontend

### 1. Naviguer vers le dossier frontend

```bash
cd ../frontend/frontend
```

### 2. Installer les dépendances Flutter

```bash
flutter pub get
```

### 3. Configurer l'application

Modifier le fichier `lib/services/` pour pointer vers votre backend :

```dart
// Exemple dans auth_service.dart
static const String _baseUrl = 'http://localhost:5000/api';
// ou pour un déploiement :
// static const String _baseUrl = 'https://your-api.railway.app/api';
```

### 4. Configurer Firebase (notifications push)

1. Créer un projet Firebase sur https://console.firebase.google.com
2. Ajouter votre application Android/iOS
3. Télécharger `google-services.json` (Android) ou `GoogleService-Info.plist` (iOS)
4. Placer les fichiers dans les dossiers appropriés :
   - Android : `android/app/google-services.json`
   - iOS : `ios/Runner/GoogleService-Info.plist`

### 5. Lancer l'application

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

---

## 🌐 Déploiement

### Backend sur Railway

1. Créer un compte sur https://railway.app
2. Connecter votre repository GitHub
3. Ajouter les variables d'environnement dans les settings
4. Railway détectera automatiquement Node.js et déploiera

### Frontend sur Vercel (web)

```bash
cd frontend/frontend
flutter build web
```

Puis déployer le dossier `build/web` sur Vercel.

### Application Mobile

```bash
# APK Android
flutter build apk --release

# IPA iOS (nécessite un Mac)
flutter build ios --release
```

---

## 🧪 Tests

```bash
# Backend
cd backend
npm test

# Frontend
cd frontend/frontend
flutter test
```

---

## 📁 Structure du Projet

```
AgriDigitale/
├── backend/
│   ├── src/
│   │   ├── config/         # Configuration DB, Firebase
│   │   ├── controllers/    # Logique métier
│   │   ├── middlewares/     # Auth, admin, upload, erreurs
│   │   ├── models/         # Schémas Mongoose
│   │   ├── routes/         # Routes Express
│   │   └── services/       # Services (RSS, météo, email, etc.)
│   ├── .env                # Variables d'environnement
│   ├── package.json
│   └── server.js           # Point d'entrée
│
├── frontend/
│   └── frontend/
│       ├── lib/
│       │   ├── core/       # Thème, localisation, constantes
│       │   ├── models/     # Modèles Dart
│       │   ├── providers/  # State management (Provider)
│       │   ├── screens/    # Écrans Flutter
│       │   ├── services/   # Services API
│       │   └── widgets/    # Widgets réutilisables
│       ├── assets/         # Images, fonts
│       └── pubspec.yaml
│
├── DOC_API.md              # Documentation API
└── README.md
```

---

## 🔧 Commandes Utiles

### Backend

| Commande | Description |
|----------|-------------|
| `npm run dev` | Démarrer en mode développement |
| `npm start` | Démarrer en mode production |
| `node seed-admin.js` | Créer l'administrateur par défaut |

### Frontend

| Commande | Description |
|----------|-------------|
| `flutter pub get` | Installer les dépendances |
| `flutter run` | Lancer l'app |
| `flutter build apk` | Construire l'APK Android |
| `flutter build web` | Construire pour le web |
| `flutter clean` | Nettoyer le cache |
| `flutter analyze` | Analyser le code |
| `flutter format .` | Formater le code |

---

## ❌ Problèmes Courants

### Erreur MongoDB
```
MongooseServerSelectionError: connect ECONNREFUSED
```
**Solution :** Vérifier que MongoDB est lancé ou que l'URI est correcte.

### Erreur CORS
```
Access to fetch blocked by CORS policy
```
**Solution :** Vérifier la configuration CORS dans `app.js` et l'URL du frontend autorisée.

### Erreur Firebase
```
Firebase: No Firebase App has been created
```
**Solution :** Vérifier que `google-services.json` est bien placé et que Firebase est initialisé.

### Erreur Flutter
```
Error: Cannot run with sound null safety
```
**Solution :** Mettre à jour Flutter : `flutter upgrade`

---

## 📞 Support

Pour toute question, contacter :
- Email : devromarictec@gmail.com
- GitHub : https://github.com/votre-utilisateur/AgriDigitale
