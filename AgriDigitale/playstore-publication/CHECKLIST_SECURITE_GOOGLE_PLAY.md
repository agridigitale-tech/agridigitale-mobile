# Checklist de Sécurité & Conformité Google Play — AgriDigitale

Ce document résume l'audit de conformité à effectuer avant chaque publication sur le Google Play Store afin d'éviter tout rejet par les robots ou réviseurs Google.

---

## 1. Permissions Android & Fichiers

| Critère | Statut Exigé | Règle Google Play |
| :--- | :---: | :--- |
| **Stockage large (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`)** | ❌ **ABSENT** | Rejet automatique si présent. Obligation d'utiliser le Photo Picker natif AndroidX. |
| **Stockage externe legacy (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`)** | ❌ **ABSENT** | Interdit pour les apps ciblant Android 13+. |
| **Tous les fichiers (`MANAGE_EXTERNAL_STORAGE`)** | ❌ **ABSENT** | Réservé aux gestionnaires de fichiers et antivirus. |
| **Position GPS (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`)** | ❌ **ABSENT** | Rejet ou déclaration vidéo obligatoire (règles 2026/2027). La météo passe par recherche API de ville. |
| **Réseau Local (`NEARBY_WIFI_DEVICES`)** | ❌ **ABSENT** | Nouvelle règle du 29 oct 2026 : réservé aux apps IoT. |
| **Gestion Contacts (`WRITE_CONTACTS`, `READ_CONTACTS`)** | ❌ **ABSENT** | Nouvelle règle du 29 oct 2026 : déclaration obligatoire si présent. |
| **SMS & Appels (`READ_SMS`, `READ_CALL_LOG`)** | ❌ **ABSENT** | Interdit sauf pour applications d'appels/SMS par défaut. |
| **Notifications Push (`POST_NOTIFICATIONS`)** | ✅ **PRÉSENT** | Autorisation standard Android 13+ demandée au runtime. |
| **Caméra (`CAMERA`)** | ✅ **OPTIONNELLE** | `android.hardware.camera` en `required="false"` pour compatibilité tablettes et appareils sans capteur. |

---

## 2. Configuration Système & Réseau

| Critère | Statut Exigé | Valeur Actuelle |
| :--- | :---: | :--- |
| **Target SDK** | >= 34 | `36` (Android 15+) |
| **Compile SDK** | >= 34 | `36` |
| **Min SDK** | >= 21 | `24` (Android 7.0+) |
| **Cleartext Traffic (HTTP non chiffré)** | ❌ **DÉSACTIVÉ** | `android:usesCleartextTraffic="false"` |
| **Composants exportés (`android:exported`)** | ✅ **CONFORME** | Seule `MainActivity` a `exported="true"` avec filtres d'intent. |
| **Services au premier plan (`foregroundServiceType`)** | ❌ **AUCUN TYPE SENSIBLE** | Aucun type `location` ou `mediaPlayback` déclaré. |

---

## 3. Obligations Légales & Compte Développeur

- [x] **Suppression de compte intégrée :** Disponible dans `Paramètres > Supprimer mon compte`.
- [x] **Lien web de suppression :** Page `suppression_compte.html` disponible.
- [x] **Politique de confidentialité :** `https://agridigitale.net/politique-de-confidentialite` (Lien direct dans `À propos` et `Paramètres`).
- [x] **Signature Release :** Keystore `agridigitale-upload.jks` avec signature RSA SHA384.
- [ ] **Statut Professionnel Google Play (Play Console) :** Obligation novembre 2026 : vérifier que votre compte développeur est déclaré en « Professionnel / Commerçant » (Trader) dans les paramètres du compte Play Console.
