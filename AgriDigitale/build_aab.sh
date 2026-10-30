#!/bin/bash
set -e

# ==============================================================================
# Script de génération automatique de l'AAB pour Google Play Store
# Usage: ./build_aab.sh [versionName] [versionCode]
# Exemple: ./build_aab.sh 2.0.2 23
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$SCRIPT_DIR/frontend/frontend"
FRONTEND_MIRROR="$SCRIPT_DIR/frontend"
OUTPUT_DIR="$SCRIPT_DIR/playstore-publication"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <versionName> <versionCode>"
  echo "Exemple: $0 2.0.2 23"
  exit 1
fi

VERSION_NAME="$1"
VERSION_CODE="$2"
FULL_VERSION="${VERSION_NAME}+${VERSION_CODE}"

echo "=========================================="
echo " Préparation de la release $FULL_VERSION"
echo "=========================================="

# 1. Mise à jour des pubspec.yaml
sed -i -E "s/^version: .+/version: $FULL_VERSION/" "$FRONTEND_DIR/pubspec.yaml"
sed -i -E "s/^version: .+/version: $FULL_VERSION/" "$FRONTEND_MIRROR/pubspec.yaml"

# 2. Mise à jour de local.properties si existant
if [ -f "$FRONTEND_DIR/android/local.properties" ]; then
  sed -i -E "s/^flutter\.versionName=.+/flutter.versionName=$VERSION_NAME/" "$FRONTEND_DIR/android/local.properties"
  sed -i -E "s/^flutter\.versionCode=.+/flutter.versionCode=$VERSION_CODE/" "$FRONTEND_DIR/android/local.properties"
fi

# 3. Récupération des dépendances
echo "--> flutter pub get..."
cd "$FRONTEND_DIR"
flutter pub get

# 4. Compilation Release AAB
echo "--> Compilation de l'AAB release..."
flutter build appbundle --release

# 5. Copie vers le dossier de publication
TARGET_AAB="$OUTPUT_DIR/AgriDigitale-v${FULL_VERSION}.aab"
cp "$FRONTEND_DIR/build/app/outputs/bundle/release/app-release.aab" "$TARGET_AAB"

echo "=========================================="
echo " ✓ AAB généré avec succès !"
echo " Emplacement: $TARGET_AAB"
echo " Taille: $(du -h "$TARGET_AAB" | cut -f1)"
echo "=========================================="
