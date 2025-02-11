import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';

class DataFetchUtils {
  static Future<void> loadData(BuildContext context) async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.updateMainInformations();
    dataManager.updateSecondaryInformations(context);
    dataManager.fetchRentData(); //f Charger les données de loyer
    dataManager.fetchAndCalculateData(); // Charger les données du portefeuille
    dataManager.fetchPropertyData();
    dataManager.updatedDetailRentVariables();
    dataManager.fetchAndStoreAllTokens();
    dataManager.fetchAndStoreYamMarketData();
    dataManager.fetchAndStorePropertiesForSale();
    
  }

  static Future<void> refreshData(BuildContext context) async {
    // Forcer la mise à jour des données en appelant les méthodes de récupération avec forceFetch = true
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.updateMainInformations(forceFetch: true);
    await dataManager.updateSecondaryInformations(context, forceFetch: true);
    await dataManager.fetchRentData(forceFetch: true);
    await dataManager.fetchAndCalculateData(forceFetch: true);
            dataManager.fetchPropertyData();
    await dataManager.updatedDetailRentVariables(forceFetch: true);
    await dataManager.fetchAndStoreAllTokens();
    await dataManager.fetchAndStoreYamMarketData();
    await dataManager.fetchAndStorePropertiesForSale();
  }
}
