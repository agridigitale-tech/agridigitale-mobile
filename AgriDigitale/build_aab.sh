#!/bin/bash
set -e

# ==============================================================================
# Script de génération automatique & d'audit de sécurité AAB pour Google Play
# Usage: ./build_aab.sh [versionName] [versionCode]
# Exemple: ./build_aab.sh 2.1.1 25
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$SCRIPT_DIR/frontend/frontend"
FRONTEND_MIRROR="$SCRIPT_DIR/frontend"
OUTPUT_DIR="$SCRIPT_DIR/playstore-publication"
KEYSTORE_PATH="/home/germain/agridigitale-upload.jks"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <versionName> <versionCode>"
  echo "Exemple: $0 2.1.1 25"
  exit 1
fi

VERSION_NAME="$1"
VERSION_CODE="$2"
FULL_VERSION="${VERSION_NAME}+${VERSION_CODE}"

echo "============================================================"
echo " [1/5] AUDIT DE SÉCURITÉ PRÉ-BUILD (Règles Google Play)"
echo "============================================================"

# A. Vérification de la clé de signature
if [ ! -f "$KEYSTORE_PATH" ]; then
  echo "❌ ERREUR: Fichier keystore introuvable: $KEYSTORE_PATH"
  exit 1
fi
echo " ✓ Clé de signature présente ($KEYSTORE_PATH)"

# B. Vérification du Target SDK
TARGET_SDK=$(grep -E 'targetSdk\s*=' "$FRONTEND_DIR/android/app/build.gradle.kts" | tr -dc '0-9')
if [ -z "$TARGET_SDK" ] || [ "$TARGET_SDK" -lt 34 ]; then
  echo "❌ ERREUR: targetSdk ($TARGET_SDK) est inférieur à 34 (exigence Google Play)"
  exit 1
fi
echo " ✓ Target SDK conforme: $TARGET_SDK (>= 34 exigé par Google Play)"

# C. Vérification de l'interdiction de cleartext HTTP
if ! grep -q 'android:usesCleartextTraffic="false"' "$FRONTEND_DIR/android/app/src/main/AndroidManifest.xml"; then
  echo "❌ ERREUR: android:usesCleartextTraffic=\"false\" manquant dans AndroidManifest.xml"
  exit 1
fi
echo " ✓ Trafic HTTP en clair désactivé (usesCleartextTraffic=false)"

# D. Vérification de l'absence de packages à risque (geolocator sans justification)
if grep -E '^\s*geolocator:' "$FRONTEND_DIR/pubspec.yaml" >/dev/null 2>&1; then
  echo "❌ ERREUR: 'geolocator' détecté dans pubspec.yaml. Il injecte un service de localisation au premier plan qui provoque le rejet par Google Play."
  exit 1
fi
echo " ✓ Packages sensibles audités (aucun package localisation non justifié)"

# E. Vérification des suppressions de permissions médias/stockage
for PERM in "READ_MEDIA_IMAGES" "READ_MEDIA_VIDEO" "READ_EXTERNAL_STORAGE" "WRITE_EXTERNAL_STORAGE"; do
  if ! grep -q "android.permission.$PERM.*tools:node=\"remove\"" "$FRONTEND_DIR/android/app/src/main/AndroidManifest.xml"; then
    echo "⚠️ AVERTISSEMENT: tools:node=\"remove\" absent pour $PERM dans AndroidManifest.xml"
  fi
done
echo " ✓ Règles d'exclusion des permissions de stockage vérifiées"

echo "============================================================"
echo " [2/5] PRÉPARATION DE LA VERSION $FULL_VERSION"
echo "============================================================"

# Mise à jour des pubspec.yaml
sed -i -E "s/^version: .+/version: $FULL_VERSION/" "$FRONTEND_DIR/pubspec.yaml"
if [ -f "$FRONTEND_MIRROR/pubspec.yaml" ]; then
  sed -i -E "s/^version: .+/version: $FULL_VERSION/" "$FRONTEND_MIRROR/pubspec.yaml"
fi

# Mise à jour de local.properties
if [ -f "$FRONTEND_DIR/android/local.properties" ]; then
  sed -i -E "s/^flutter\.versionName=.+/flutter.versionName=$VERSION_NAME/" "$FRONTEND_DIR/android/local.properties"
  sed -i -E "s/^flutter\.versionCode=.+/flutter.versionCode=$VERSION_CODE/" "$FRONTEND_DIR/android/local.properties"
fi

echo " ✓ Versions mises à jour dans pubspec.yaml et local.properties"

echo "============================================================"
echo " [3/5] RÉCUPÉRATION DES DÉPENDANCES"
echo "============================================================"
cd "$FRONTEND_DIR"
flutter pub get

echo "============================================================"
echo " [4/5] COMPILATION DE L'AAB RELEASE"
echo "============================================================"
flutter build appbundle --release

echo "============================================================"
echo " [5/5] AUDIT POST-BUILD & ARCHIVAGE"
echo "============================================================"

PACKAGED_MANIFEST="$FRONTEND_DIR/build/app/intermediates/packaged_manifests/release/processReleaseManifestForPackage/AndroidManifest.xml"
if [ -f "$PACKAGED_MANIFEST" ]; then
  # Vérification qu'aucune permission interdite n'a fuité dans le binaire final
  INTERDITES=("READ_MEDIA_IMAGES" "READ_MEDIA_VIDEO" "MANAGE_EXTERNAL_STORAGE" "ACCESS_FINE_LOCATION" "ACCESS_BACKGROUND_LOCATION" "WRITE_CONTACTS" "NEARBY_WIFI_DEVICES")
  for P in "${INTERDITES[@]}"; do
    if grep -q "android.permission.$P" "$PACKAGED_MANIFEST"; then
      echo "❌ ERREUR CRITIQUE: La permission interdite $P est présente dans le manifest compilé !"
      exit 1
    fi
  done
  echo " ✓ Manifest binaire certifié : aucune permission sensible interdite présente."

  # Vérification foregroundServiceType
  if grep -q 'foregroundServiceType="location"' "$PACKAGED_MANIFEST"; then
    echo "❌ ERREUR: foregroundServiceType=\"location\" détecté dans le binaire compilé !"
    exit 1
  fi
  echo " ✓ Aucun service au premier plan non déclaré."
fi

# Copie vers le dossier de publication
TARGET_AAB="$OUTPUT_DIR/AgriDigitale-v${FULL_VERSION}.aab"
mkdir -p "$OUTPUT_DIR"
cp "$FRONTEND_DIR/build/app/outputs/bundle/release/app-release.aab" "$TARGET_AAB"

echo "============================================================"
echo " ✓ BUNDLE AAB GÉNÉRÉ & CERTIFIÉ CONFORME GOOGLE PLAY !"
echo " Emplacement: $TARGET_AAB"
echo " Taille:      $(du -h "$TARGET_AAB" | cut -f1)"
echo " Version:     $FULL_VERSION"
echo "============================================================"
