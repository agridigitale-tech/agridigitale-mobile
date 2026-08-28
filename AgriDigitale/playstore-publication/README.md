# AgriDigitale — Préparation publication Google Play Store

> Compte rendu complet des travaux réalisés par l'assistant (session du 24 août 2026).

---

## 1. Lecture et analyse complète du projet

### Backend (`AgriDigitale/backend`) — API Node.js/Express déployée sur Render (`agridigitale-backend.onrender.com`)
- **Stack** : Express 5.x, Mongoose 9.x, MongoDB Atlas, JWT + bcryptjs, helmet, rate-limit
- **Synchronisations automatiques** (node-cron) :
  - Flux RSS `agridigitale.net/feed` → MongoDB toutes les **15 min**
  - Météo OpenWeatherMap toutes les **heures**
  - Vidéos YouTube AGDTV toutes les **3 h**
- **Modules lus intégralement** : `app.js`, `server.js`, `.env`, les 12 modèles Mongoose, les 11 fichiers de routes, les 10 contrôleurs, tous les services (rss, meteo, agdtv, notification, emailTemplate) et middlewares (auth, admin, upload, errorHandler)
- **Fonctionnalités clés** : auth avec OTP + reset par deep link `agridigitale://reset-password`, articles RSS, favoris, commentaires, demandes (rate-limit 3/h), bannières, météo (+ archives), notifications FCM, panneau admin (stats, utilisateurs), proxy images CORS

### Frontend (`AgriDigitale/frontend/frontend`) — Flutter (le vrai projet ; `frontend/lib` n'existe pas)
- **58 fichiers Dart lus** : main.dart, providers (auth, thème, langue, notifications), services (Dio singleton + SQLite cache offline), écrans (Accueil, Détail article, Recherche, Notifications, Auth complète, Météo, Archives météo, AGDTV, Favoris, Demande, Paramètres, Admin ×6), widgets (cards, carousel bannières, auth gate)
- **Navigation** : 6 onglets + bouton « Panneau administrateur » si rôle admin
- **Hors ligne** : SQLite (articles TTL 6h, météo TTL 2h, favoris) désactivé sur web

### Configuration Android inspectée — problèmes détectés
| # | Problème | Impact |
|---|---|---|
| 1 | `android/app/google-services.json` contenait le package `com.example.frontend` au lieu de `com.agridigitale.app` | Build release impossible |
| 2 | Ancien `MainActivity.kt` orphelin dans `kotlin/com/example/frontend/` | Code mort |
| 3 | Aucun keystore → signature **debug** dans `build.gradle.kts` | Refus du Play Store |
| 4 | Permissions `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` déclarées mais jamais utilisées dans le code | Signalement Google Play + formulaire Sécurité des données compliqué |
| 5 | Dossiers mipmap vides avant régénération | Risque d'échec de resource linking |

---

## 2. Corrections appliquées

1. ✅ **google-services.json corrigé** : copie de la version avec le bon package
   `com.agridigitale.app` depuis `android/app/src/google-services.json`
2. ✅ **Suppression** de `android/app/src/main/kotlin/com/example/frontend/` (l'ancien MainActivity)
3. ✅ **Retrait des permissions GPS inutiles** dans `AndroidManifest.xml`
   (aucun appel Geolocator dans tout `lib/`)
4. ✅ Manifest déjà correct : deep link `agridigitale://reset-password`, service FCM,
   récepteurs flutter_local_notifications, icône/couleur de notification

## 3. Signature de production créée

- 🔑 **Keystore généré** : `android/app/keystore/upload-keystore.jks`
  - Alias : `upload` · RSA 2048 · validité 10 000 jours (~27 ans)
  - DN : `CN=AgriDigitale, O=AGRIDIGITALE, L=Lome, C=TG`
  - Mot de passe : voir `android/key.properties` (`AgriDigitale2026!`)
  - ⚠️ **À sauvegarder hors du projet impérativement** (perte = plus aucune mise à jour possible)
- 📄 **`android/key.properties` créé** (storePassword, keyPassword, keyAlias, storeFile)
- ⚙️ **`android/app/build.gradle.kts` mis à jour** :
  - Chargement de `key.properties` en tête de fichier
  - Bloc `signingConfigs { release }` ajouté
  - `buildTypes.release.signingConfig` passe de debug → release
- 🛡️ Vérifié : `android/.gitignore` exclut déjà `key.properties`, `*.jks`, `*.keystore`

## 4. Build de production

```powershell
flutter pub get                    # dépendances résolues
dart run flutter_launcher_icons    # icônes Android+iOS régénérées depuis logo-B.png
flutter build appbundle --release  # ✅ réussi en ~8 min
```

📦 **Artefact final signé** :
```
frontend/frontend/build/app/outputs/bundle/release/app-release.aab   (46,9 Mo)
```
Version : `1.0.0+1` · Package : `com.agridigitale.app`

## 5. Documents de publication créés (dossier `playstore-publication/`)

| Fichier | Contenu |
|---|---|
| `CHECKLIST_PUBLICATION.md` | Guide pas-à-pas Play Console : compte développeur (25 USD), création de l'app, fiche store, questionnaires IARC/classification, réponses exactes du formulaire **Sécurité des données**, upload AAB, pays, tests pré-envoi, procédure des mises à jour |
| `textes_play_store.md` | Nom (30 car.), description courte (69/80 car.), description complète (~1600/4000 car.), coordonnées de contact |
| `privacy_policy.html` | Politique de confidentialité complète prête à héberger en ligne (obligatoire Google) — mise à jour avec la section « Suppression de votre compte » |
| `suppression_compte.html` | **Page web de suppression de compte** (obligation Google Play 2024) : instructions in-app + bouton e-mail prérempli. Son URL va dans le champ « Lien de suppression de compte » de la Play Console |

## 5bis. Suppression de compte in-app (conformité Google Play) — ajoutée

- **Backend** : nouveau endpoint `DELETE /api/auth/supprimer-compte` (`auth.controller.js`, route dans
  `auth.routes.js`) — protégé par JWT, refuse les comptes admin, purge en cascade :
  favoris + commentaires + notifications + le compte lui-même. ⚠️ À **redéployer sur Render**.
- **Frontend** :
  - `constants.dart` : `apiAuthDeleteAccount`
  - `auth_service.dart` : méthode `supprimerCompte()` (appelle l'API puis déconnecte localement)
  - `settings_screen.dart` : ligne rouge **« Supprimer mon compte »** sous la déconnexion,
    avec boîte de dialogue de confirmation et SnackBar de résultat — validé par `flutter analyze`
- L'AAB doit être **recompilé** après ces changements : `flutter build appbundle --release`

## 6. Ce qu'il reste à faire (côté humain)

1. 💾 Sauvegarder le keystore `.jks` + noter le mot de passe
2. 💳 Créer le compte développeur Google Play (**25 USD**)
3. 🌐 Héberger `privacy_policy.html` **et** `suppression_compte.html` sur des URLs publiques
4. 📸 Prendre 2 à 8 captures d'écran de l'app + créer l'image 1024×500
5. 🚀 Redéployer le backend Render (nouvel endpoint)
6. 🏪 Suivre `CHECKLIST_PUBLICATION.md` et uploader l'AAB
7. ⏱️ Attendre la validation Google (24–48 h généralement)

## 7. Points de vigilance relevés (non bloquants)

- ⚠️ Le `.env` backend contient des secrets en clair versionnés — à déplacer vers les variables d'environnement Render
- `usesCleartextTraffic="true"` actif (autorisé par Play, mais HTTPS partout serait mieux)
- Fichiers parasites à la racine backend : `console.error(e.message)`, `mkdir`, `update_content.js`, `fix_contenu.js`
