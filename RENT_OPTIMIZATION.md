# Optimisations des loyers dans l'application RealTokens

## Améliorations apportées

1. Ajout de calculateRentSummaries() qui pré-calcule les loyers cumulés par token
2. Modification de getRentDetailsForToken() pour utiliser les données pré-calculées
3. Ajout de saveRentHistory() et loadRentHistory() pour sauvegarder/charger l'historique des loyers
4. Intégration avec les méthodes updateSecondaryInformations et updateMainInformations

Ces modifications permettent d'améliorer les performances en évitant de recalculer les loyers pour chaque token à chaque fois.

## Structure des données

- rentData: liste des loyers cumulés par token
- detailedRentData: historique des loyers par date et par token

## Installation

Assurer que la boîte Hive 'rentHistory' est bien initialisée dans main.dart et correctement gérée dans les sauvegardes/restaurations Google Drive.

