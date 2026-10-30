# Procédure de Génération du Bundle Android (.aab) pour Google Play Store

Ce document décrit le processus complet et optimisé pour générer l'Android App Bundle (`.aab`) signé, prêt pour la soumission sur la console Google Play Store.

---

## 1. Emplacements Clés du Projet

- **Projet Flutter actif** : `AgriDigitale/frontend/frontend`
- **Fichier de version principale** : `AgriDigitale/frontend/frontend/pubspec.yaml`
- **Fichier de version miroir** : `AgriDigitale/frontend/pubspec.yaml`
- **Clé de signature (Keystore)** : `/home/germain/agridigitale-upload.jks`
- **Configuration signature** : `AgriDigitale/frontend/frontend/android/key.properties`
- **Dossier de publication final** : `AgriDigitale/playstore-publication/`

---

## 2. Configuration de Signature (`key.properties`)

Le fichier `AgriDigitale/frontend/frontend/android/key.properties` contient :
```properties
storePassword=AgriDigitale2026@Key
keyPassword=AgriDigitale2026@Key
keyAlias=agridigitale-upload
storeFile=/home/germain/agridigitale-upload.jks
```

Dans `android/app/build.gradle.kts`, le bloc de signature est automatiquement configuré pour charger `key.properties` et signer le build `release`.

---

## 3. Étapes de Génération Rapide

### Étape 1 : Mettre à jour la version
Dans `AgriDigitale/frontend/frontend/pubspec.yaml` et `AgriDigitale/frontend/pubspec.yaml` :
```yaml
version: X.Y.Z+CODE
```
*(Exemple : `version: 2.0.2+23` où `2.0.2` est le versionName et `23` est le versionCode incrémenté).*

Dans `AgriDigitale/frontend/frontend/android/local.properties` (facultatif mais recommandé) :
```properties
flutter.versionName=X.Y.Z
flutter.versionCode=CODE
```

### Étape 2 : Préparer les dépendances
```bash
cd AgriDigitale/frontend/frontend
flutter pub get
```
*Note importante : S'assurer que `.dart_tool/package_config.json` est bien généré avant le build.*

### Étape 3 : Compiler le Bundle Release
```bash
cd AgriDigitale/frontend/frontend
flutter build appbundle --release
```
Le fichier généré est situé dans :
`AgriDigitale/frontend/frontend/build/app/outputs/bundle/release/app-release.aab`

### Étape 4 : Archiver dans le dossier de publication
```bash
cp AgriDigitale/frontend/frontend/build/app/outputs/bundle/release/app-release.aab \
   AgriDigitale/playstore-publication/AgriDigitale-vX.Y.Z+CODE.aab
```

---

## 4. Script Automatique

Un script d'automatisation est disponible à la racine : `AgriDigitale/build_aab.sh`.
Usage :
```bash
./AgriDigitale/build_aab.sh 2.0.2 23
```
Ce script effectue automatiquement la mise à jour des versions, le `pub get`, le build release et la copie dans `playstore-publication/`.
