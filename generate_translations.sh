#!/bin/bash

# Script pour générer les fichiers de traduction

echo "Génération des fichiers de traduction..."
flutter pub run intl_utils:generate

if [ $? -eq 0 ]; then
  echo "✅ Génération réussie !"
  echo "Vous pouvez maintenant utiliser les nouvelles clés de traduction dans votre code."
else
  echo "❌ Erreur lors de la génération des fichiers de traduction."
  echo "Vérifiez que vous avez bien installé le package intl_utils :"
  echo "flutter pub add intl_utils --dev"
fi 