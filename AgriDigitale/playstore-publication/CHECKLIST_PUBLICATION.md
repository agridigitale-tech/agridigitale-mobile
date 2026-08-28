# Checklist de publication — Google Play Store

App : **AgriDigitale** · Package : `com.agridigitale.app` · Version : `1.0.0+1`

---

## ✅ Déjà fait (préparé dans le projet)

| Élément | État |
|---|---|
| AAB signé de production | `frontend/frontend/build/app/outputs/bundle/release/app-release.aab` (46,9 Mo) |
| Keystore d'upload | `android/app/keystore/upload-keystore.jks` (alias `upload`, validité 10 000 jours) |
| Signature release configurée | `android/key.properties` + `build.gradle.kts` |
| `google-services.json` corrigé (package `com.agridigitale.app`) | `android/app/google-services.json` |
| Ancien `com/example/frontend/MainActivity.kt` supprimé | ✔ |
| Icônes launcher générées depuis `logo-B.png` (Android + iOS) | ✔ |
| Permissions inutiles (localisation) retirées du manifest | ✔ |
| Deep link `agridigitale://reset-password` enregistré | ✔ (déjà dans le manifest) |

## 🔐 À faire IMMÉDIATEMENT (sécurité)

1. **Sauvegarde le keystore** `android/app/keystore/upload-keystore.jks` dans un endroit sûr
   (cloud privé + disque externe). **S'il est perdu, tu ne pourras plus jamais mettre à jour l'app**
   avec le même package. Note le mot de passe : il est dans `android/key.properties`
   (`AgriDigitale2026!`) — change-le si tu veux :
   ```
   & "D:\Program Files\Java\jdk-24\bin\keytool.exe" -storepasswd -keystore android\app\keystore\upload-keystore.jks -alias upload
   ```
2. Vérifie que `key.properties`, `*.jks`, `*.keystore` ne sont jamais commités
   (déjà exclus par `android/.gitignore` ✔).

---

## 🏪 Étapes dans la Play Console (play.google.com/console)

### Étape 0 — Compte développeur
- Créer un compte développeur Google Play (**25 USD**, paiement unique).
- Compléter le profil : nom du développeur « AGRIDIGITALE », e-mail, adresse.

### Étape 1 — Créer l'application
1. « Créer une application » → Nom : **AgriDigitale**
   - Langue par défaut : Français (France)
   - Type : **Application** / Gratuit ou payant : **Gratuit**
2. Déclarations initiales (cocher tout) :
   - Application conforme aux Règles du programme
   - Pas de contenu publicitaire tiers (les bannières sont tes propres pubs → réponds selon ton cas ; si les bannières promeuvent tes services uniquement, répondre NON aux annonces tierces)
   - Ciblage : 13+ ans

### Étape 2 — Fiche Play Store (Présence sur le Play Store → Fiche principale)
Utilise `textes_play_store.md` :

| Asset | Spécification | Où le trouver |
|---|---|---|
| Icône app 512×512 px PNG 32 bits | obligatoire | Générer depuis `logo-B.png` |
| Image de mise en avant 1024×500 px | obligatoire | À créer (bannière avec logo + slogan) |
| Captures téléphone **min. 2, max. 8** (16:9 ou 9:16, 320–3840 px) | obligatoire | Screenshots réels de l'app (Accueil, Détail article, Météo, AGDTV, Favoris, Paramètres) |
| Captures tablette 7" et 10" (min. 2 chacune) | recommandé | Optionnel au départ |
| Description courte (80 car.) et complète (4000 car.) | obligatoire | `textes_play_store.md` |

> 💡 Pour les captures : lance l'app (`flutter run --release`), prends des captures avec
> `Win+Shift+S` sur un émulateur, ou utilise `adb exec-out screencap -p > capture.png`.
> Outil gratuit pour les images marketing : https://screenshots.pro ou Canva.

### Étape 3 — Contenu de l'app (questionnaires)
1. **Confidentialité** : coller l'URL publique où tu as hébergé `privacy_policy.html`
   (ex. https://agridigitale.com/politique-confidentialite.html).
   ⚠️ Obligatoire : l'URL doit être accessible publiquement.
2. **Suppression de compte (obligatoire depuis 2024)** : dans le formulaire « Sécurité des données »,
   Google demande un **lien de suppression de compte**. Coller l'URL publique où tu as hébergé
   `suppression_compte.html` (ex. https://agridigitale.com/suppression-compte.html).
   ✔ La suppression est aussi possible **dans l'app** : Paramètres → « Supprimer mon compte »
   (endpoint `DELETE /api/auth/supprimer-compte` ajouté au backend). Cocher que les deux voies existent.
3. **Accès à l'app** : « Toutes les fonctionnalités sont disponibles sans restrictions »
   (pas besoin de compte pour lire les articles). Cocher oui si certaines parties exigent un compte.
4. **Annonces** : indiquer si l'app contient des annonces (bannières internes = pas d'ads SDK → généralement « Non »).
5. **Classification du contenu** : remplir le questionnaire IARC (~5 min, tout est non violent → classement Tout public).
6. **Public cible** : 13+ (cocher 13-15, 16-17, 18+ ; NE PAS cibler les enfants → pas d'obligation "Designed for Families").
7. **Collecte de données — Formulaire « Sécurité des données »** — réponses adaptées à cette app :
   - Collectez-vous des données ? **Oui**
   - Données collectées :
     - *Infos personnelles* → Nom (nom complet), E-mail → **Fonction : Compte** → Non facultatif → Chiffrées en transit ✔ → Bouton suppression ✔
     - *Identifiants d'appareil* → Identifiant d'app (jeton FCM) → **Fonction : Messagerie push** → Facultatif → Chiffrées ✔ → Suppression : Non
     - *Contenu utilisateur* (commentaires, demandes : téléphone inclus) → **Fonction : Fonctionnalités de l'app** → Chiffrées ✔ → Bouton suppression ✔
   - Toutes les autres catégories (localisation, données financières, santé, photos… ) : **Non collectées**
7. **Gouvernementales / Santé / Financières** : Non.

> 📌 Rappel déploiement : le nouveau endpoint `DELETE /api/auth/supprimer-compte` doit être
> **redéployé sur Render** avant la soumission, et les deux pages HTML hébergées en ligne.

### Étape 4 — Publier la version
1. Production → Créer une version
2. **Google Play App Signing** : accepter (Google gère la clé de prod ; ta clé locale = clé d'upload)
3. Uploader `app-release.aab`
4. Notes de version :
   ```
   Première version 🎉
   • Actualités agricoles en continu (Togo, Afrique, Monde)
   • Météo agricole et météo par ville
   • Vidéos AGDTV
   • Favoris hors ligne, commentaires, notifications push
   ```
5. Pays disponibles : ajoute au minimum **Togo** + pays cibles (Afrique de l'Ouest, France…)
6. Examiner puis **Envoyer pour validation**

⏱️ Validation : de quelques heures à 7 jours (première soumission souvent 24–48 h).

---

## 📱 Tests avant envoi (recommandé)

```powershell
# Installer la version release sur un téléphone branché (test réel)
flutter build apk --release
flutter install --release
```
Vérifie :
- [ ] Connexion / inscription / mot de passe oublié (e-mail reçu ?)
- [ ] Notifications push reçues quand l'app est fermée (envoie une notif via l'écran admin)
- [ ] Deep link reset password : clique le lien de l'e-mail sur le téléphone
- [ ] Images articles + bannières s'affichent
- [ ] Vidéo AGDTV se lance
- [ ] Mode avion : cache articles/favoris fonctionne

## 🔄 Pour les prochaines mises à jour

1. Dans `pubspec.yaml` : augmenter la version, ex. `1.0.1+2` (le `+N` = versionCode, toujours croissant)
2. `flutter build appbundle --release`
3. Uploader le nouvel AAB dans la Play Console avec les notes de mise à jour

## ⚠️ Points de vigilance connus

- **URL backend** : ✔ confirmée — `agridigitale-backend.onrender.com/api` (Render), cohérente avec `constants.dart` et `api_client.dart`
- Le lien Play Store codé en dur dans `settings_screen.dart:53` utilise `?id=com.agridigitale.app` ✔ cohérent avec le package.
- `usesCleartextTraffic="true"` est actif (non bloquant pour Play Store, mais à désactiver un jour si toutes tes sources sont HTTPS).
