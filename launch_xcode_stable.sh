#!/bin/bash
# Script pour lancer Xcode stable sur macOS beta
# Bypass les vérifications de compatibilité

echo "🚀 Lancement de Xcode stable sur macOS beta..."

# Variables d'environnement pour forcer la compatibilité
export SYSTEM_VERSION_COMPAT=1
export DYLD_FALLBACK_LIBRARY_PATH=/usr/lib

# Lancer Xcode avec les flags de compatibilité
exec /Applications/Xcode.app/Contents/MacOS/Xcode "$@" 