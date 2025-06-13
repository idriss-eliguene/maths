#!/bin/bash

set -e

echo "🔧 Correction CocoaPods & ffi_c…"

# Vérification de Ruby et architecture
echo "💡 Ruby version: $(ruby -v)"
echo "💡 Architecture: $(arch)"

# Installation / réparation de ffi
echo "📦 Installation de la gem ffi en mode x86_64…"
sudo arch -x86_64 gem install ffi -- --enable-system-libffi

# Nettoyage du projet Flutter
echo "🧹 Nettoyage du projet Flutter…"
flutter clean
flutter pub get

# Réinstallation des Pods
cd ios
echo "📦 Suppression des anciens Pods et Podfile.lock…"
rm -rf Pods Podfile.lock

echo "📦 Réinstallation des Pods (x86_64)…"
arch -x86_64 pod install

cd ..
echo "✅ Réinstallation terminée. Tu peux maintenant lancer : flutter run"

