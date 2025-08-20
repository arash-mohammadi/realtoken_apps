import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/managers/data_manager.dart';

/// Classe utilitaire pour faciliter le chargement des données depuis l'interface utilisateur
/// DataFetchUtils sert uniquement d'interface simplifiée vers DataManager
/// et ne contient aucune logique métier directe.
class DataFetchUtils {
  /// Charge les données avec mise à jour directe à partir des API
  /// À utiliser lors du premier chargement quand on veut des données fraîches
  static Future<void> loadData(BuildContext context) async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.loadWalletsAddresses();
    if (dataManager.evmAddresses.isNotEmpty) {
      // Utiliser la méthode centralisée de DataManager
      await dataManager.updateAllData(context);
    }
  }

  /// Charge d'abord les données depuis le cache puis les met à jour en arrière-plan
  /// À utiliser pour améliorer la réactivité de l'interface utilisateur
  static Future<void> loadDataWithCache(BuildContext context) async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.loadFromCacheThenUpdate(context);
  }

  /// Force le rafraîchissement de toutes les données (ignore le cache)
  /// À utiliser lors d'une action explicite de l'utilisateur (pull-to-refresh)
  static Future<void> refreshData(BuildContext context) async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.forceRefreshAllData(context);
  }
}
