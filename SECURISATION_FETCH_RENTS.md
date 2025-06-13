# Sécurisation des Fetch de Loyers - Logique Mardi

## Vue d'ensemble

Implémentation d'une logique robuste pour sécuriser les fetch de données de loyers (`fetchRentData` et `fetchDetailedRentDataForAllWallets`) afin qu'ils ne se lancent que **le mardi de chaque nouvelle semaine**.

## Règles de Sécurisation

### 🗓️ **Règle Principale : Mardi Uniquement**
- Les fetch de loyers ne peuvent se lancer que **le mardi** (jour 2 de la semaine)
- **Une seule tentative par semaine** maximum
- La semaine commence le **lundi à 00h00**

### 🔓 **Exceptions Autorisées**

#### 1. **Pas de Cache Initial**
```dart
if (lastFetchTime == null && lastSuccessfulFetch == null) {
  // Fetch autorisé à tout moment si aucun cache
  return true;
}
```

#### 2. **Force Fetch**
```dart
if (forceFetch) {
  // Bypass toutes les restrictions
  return true;
}
```

#### 3. **Erreur 429 Récente**
```dart
if (last429Time != null && now.difference(last429) < Duration(minutes: 5)) {
  // Attendre 5 minutes après une erreur 429
  return false;
}
```

## Logique Détaillée

### A. **fetchRentData** (Données Agrégées)

#### Vérifications dans l'ordre :
1. **Force Fetch** → Autorisé
2. **Erreur 429 récente** → Bloqué 5 minutes
3. **Pas de cache du tout** → Autorisé à tout moment
4. **Fetch réussi cette semaine** → Bloqué
5. **Pas mardi** → Bloqué
6. **Mardi + pas de succès cette semaine** → Autorisé

#### Timestamps utilisés :
- `lastRentFetchTime` : Dernière tentative (succès ou échec)
- `lastSuccessfulRentFetch` : Dernier succès uniquement
- `lastRent429Time` : Dernière erreur 429

### B. **fetchDetailedRentDataForAllWallets** (Données par Wallet)

#### Vérifications spécifiques :
1. **Force Fetch** → Autorisé
2. **Pas de cache détaillé** → Vérifie tous les wallets, autorisé si aucun cache
3. **Fetch réussi cette semaine** → Bloqué
4. **Pas mardi** → Bloqué
5. **Mardi + pas de succès cette semaine** → Autorisé

#### Timestamps utilisés :
- `lastSuccessfulDetailedRentFetch` : Dernier succès global
- `cachedDetailedRentData_{wallet}` : Cache par wallet
- `lastDetailedRentFetchTime_{wallet}` : Tentative par wallet

## Calcul de la Semaine

```dart
// Calculer le début de la semaine actuelle (lundi 00h00)
final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
final DateTime startOfCurrentWeekMidnight = DateTime(
  startOfCurrentWeek.year, 
  startOfCurrentWeek.month, 
  startOfCurrentWeek.day
);

// Vérifier si le dernier succès est dans la semaine actuelle
if (lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
  // Déjà fait cette semaine
  return false;
}
```

## Gestion des Succès et Échecs

### ✅ **Marquage du Succès**
```dart
// Seulement si des données ont été récupérées
if (mergedRentData.isNotEmpty) {
  await box.put('lastRentFetchTime', now.toIso8601String());
  await box.put('lastSuccessfulRentFetch', now.toIso8601String());
}
```

### ❌ **Gestion des Échecs**
- Les échecs ne marquent **PAS** le succès
- Permet une nouvelle tentative le mardi suivant
- Les erreurs 429 bloquent temporairement (5 minutes)

## Scénarios d'Usage

### 📅 **Scénario 1 : Premier Lancement**
- **Situation** : Aucun cache, n'importe quel jour
- **Résultat** : ✅ Fetch autorisé
- **Raison** : Pas de données, utilisateur doit voir quelque chose

### 📅 **Scénario 2 : Mardi, Pas de Succès Cette Semaine**
- **Situation** : Mardi, dernier succès semaine précédente
- **Résultat** : ✅ Fetch autorisé
- **Raison** : Nouvelle semaine, mise à jour nécessaire

### 📅 **Scénario 3 : Mardi, Succès Déjà Cette Semaine**
- **Situation** : Mardi, succès lundi ou mardi de cette semaine
- **Résultat** : ❌ Fetch bloqué
- **Raison** : Données déjà à jour pour cette semaine

### 📅 **Scénario 4 : Mercredi-Lundi**
- **Situation** : N'importe quel jour sauf mardi
- **Résultat** : ❌ Fetch bloqué
- **Raison** : Attendre le prochain mardi

### 📅 **Scénario 5 : Erreur 429**
- **Situation** : Erreur 429 reçue il y a 3 minutes
- **Résultat** : ❌ Fetch bloqué temporairement
- **Raison** : Rate limiting, attendre 5 minutes

## Logs de Debug

### 🔍 **Messages de Debug Explicites**
```dart
"✅ Pas de cache, fetch autorisé à tout moment"
"🛑 Fetch déjà réussi cette semaine (2024-01-15T10:30:00.000Z)"
"🛑 Pas mardi, fetch non autorisé (jour 3)"
"✅ Mardi et pas de fetch réussi cette semaine, fetch autorisé"
"⚠️ 429 reçu récemment, attente de 5 minutes avant nouvelle requête"
```

### 📊 **Informations de Suivi**
- Jour de la semaine actuel
- Date du dernier succès
- Début de la semaine actuelle
- Statut des erreurs 429

## Avantages de Cette Approche

### 🎯 **Respect des Contraintes Métier**
- **Une seule mise à jour par semaine** comme requis
- **Jour fixe** (mardi) pour la cohérence
- **Pas de spam** des APIs externes

### 🛡️ **Robustesse**
- **Gestion des échecs** sans bloquer la semaine suivante
- **Protection contre les erreurs 429**
- **Fallback sur cache** en cas de problème

### 📱 **Expérience Utilisateur**
- **Premier lancement** : Données immédiates
- **Usage normal** : Mise à jour hebdomadaire transparente
- **Hors ligne** : Cache persistant disponible

### 🔧 **Maintenabilité**
- **Logs explicites** pour le debugging
- **Logique centralisée** dans shouldUpdate
- **Timestamps séparés** pour succès/tentatives

## Compatibilité

Cette logique est **100% compatible** avec :
- Le système de cache existant
- Les méthodes `_fetchWithCache`
- Le `DataManager` et ses appels
- Les paramètres `forceFetch`

La sécurisation est **transparente** et n'affecte pas le reste de l'application. 