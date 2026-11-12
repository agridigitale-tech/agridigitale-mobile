# RÈGLES DE DÉVELOPPEMENT & SÉCURITÉ GOOGLE PLAY — AGRIDIGITALE

Ce document définit les règles impératives à respecter pour le projet mobile AgriDigitale, particulièrement avant toute génération de bundle Android (`.aab`) pour publication sur le Google Play Store.

---

## 1. Règles Strictes de Sécurité & Politiques Google Play

Avant de générer ou valider un `.aab`, vérifier **systématiquement** les points suivants :

### A. Permissions Sensibles & Stockage (Photo & Video Permissions Policy)
- **INTERDIT :** Ne JAMAIS ajouter ni autoriser les permissions d'accès large aux médias ou au stockage :
  - `android.permission.READ_MEDIA_IMAGES`
  - `android.permission.READ_MEDIA_VIDEO`
  - `android.permission.READ_EXTERNAL_STORAGE`
  - `android.permission.WRITE_EXTERNAL_STORAGE`
  - `android.permission.MANAGE_EXTERNAL_STORAGE`
- **OBLIGATION :** La sélection de photo (avatar, photos de produits admin) DOIT impérativement passer par le Photo Picker natif d'AndroidX (`ActivityResultContracts.PickVisualMedia`).
- Les balises `tools:node="remove"` doivent être conservées dans `AndroidManifest.xml` ainsi que le bloc de nettoyage post-evaluation dans `android/app/build.gradle.kts`.

### B. Géolocalisation & Services au Premier Plan (Règles 2026/2027)
- **INTERDIT :** Ne pas intégrer `geolocator` ou `geocoding` tant que la fonctionnalité n'est pas indispensable. La météo utilise la recherche Open-Meteo et la carte interactive SVG sans requérir le GPS matériel.
- **INTERDIT :** Ne JAMAIS déclarer `android:foregroundServiceType="location"` ou `android.permission.ACCESS_FINE_LOCATION` sans une déclaration formelle justifiée avec démonstration vidéo sous peine de rejet immédiat.

### C. Réseau Local & Contacts (Règles Google Play 29 oct. 2026)
- **INTERDIT :** Ne JAMAIS ajouter `NEARBY_WIFI_DEVICES` ou `WRITE_CONTACTS` / `READ_CONTACTS`. L'application ne gère pas d'objets connectés locaux ni de carnet d'adresses.

### D. Niveau d'API Cible (Target SDK)
- `targetSdkVersion` et `compileSdkVersion` doivent être >= 34 (actuellement configurés à 36).
- `minSdkVersion` est fixé à 24 (Android 7.0+).

### E. Trafic Réseau Chiffré (HTTPS)
- `android:usesCleartextTraffic="false"` DOIT être maintenu dans `android/app/src/main/AndroidManifest.xml`.
- Tout appel d'API vers le backend ou proxy d'images DOIT utiliser HTTPS (`https://agridigitale-mobile.onrender.com/api` et URL sécurisées).

### F. Suppression de Compte & Données Utilisateur
- Google Play exige obligatoirement une procédure de suppression de compte :
  - **In-App :** Écran Paramètres > "Supprimer mon compte" connecté à l'endpoint `DELETE /auth/supprimer-compte`.
  - **Lien Web :** La page `suppression_compte.html` hébergée sur le domaine web officiel.

### G. Politique de Confidentialité (Privacy Policy)
- Le lien vers la politique de confidentialité (`https://agridigitale.net/politique-de-confidentialite`) DOIT être accessible dans l'application (`Paramètres` et `À propos`) et rester actif (réponse HTTP 200).

### H. Télémétrie et Données (Data Safety)
- L'identifiant appareil doit rester un UUID v4 généré localement dans SharedPreferences.
- Ne JAMAIS collecter les identifiants matériels (IMEI, IMSI, adresse MAC, Android ID) sans déclaration explicite.

---

## 2. Procédure de Génération d'un Nouveau AAB

Pour générer une nouvelle version (ex: `2.1.2` build `26`) :

1. Lancer impérativement le script automatisé qui exécute l'audit de sécurité pré-build :
   ```bash
   ./AgriDigitale/build_aab.sh <versionName> <versionCode>
   ```
   *Exemple : `./AgriDigitale/build_aab.sh 2.1.2 26`*
2. Vérifier que l'audit de sécurité passe à 100% sans avertissement bloquant.
3. Le fichier final est archivé dans : `AgriDigitale/playstore-publication/AgriDigitale-v<versionName>+<versionCode>.aab`.
4. Vérifier que la signature RSA SHA384 (`agridigitale-upload`) est bien appliquée.
