import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/models/healthandltv_record.dart';
import 'package:realtokens/models/rented_record.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/balance_record.dart';
import '../models/roi_record.dart';
import '../models/apy_record.dart';
import 'archive_manager.dart';
import 'package:realtokens/managers/apy_manager.dart';
import 'package:flutter/foundation.dart';

class DataManager extends ChangeNotifier {
  List<String> evmAddresses = [];
  double totalWalletValue = 0;
  double roiGlobalValue = 0;
  double netGlobalApy = 0;
  double walletValue = 0;
  double rmmValue = 0;
  Map<String, double> perWalletRmmValues = {};
  double rwaHoldingsValue = 0;
  int rentedUnits = 0;
  int totalUnits = 0;
  double initialTotalValue = 0.0;
  double yamTotalValue = 0.0;
  double totalTokens = 0.0;
  double walletTokensSums = 0.0;
  double rmmTokensSums = 0.0;
  double averageAnnualYield = 0;
  double dailyRent = 0;
  double weeklyRent = 0;
  double monthlyRent = 0;
  double yearlyRent = 0;
  Map<String, List<String>> userIdToAddresses = {};
  double totalUsdcDepositBalance = 0;
  double totalUsdcBorrowBalance = 0;
  double totalXdaiDepositBalance = 0;
  double totalXdaiBorrowBalance = 0;
  double gnosisUsdcBalance = 0;
  double gnosisXdaiBalance = 0;
  int totalRealtTokens = 0;
  double totalRealtInvestment = 0.0;
  double netRealtRentYear = 0.0;
  double realtInitialPrice = 0.0;
  double realtActualPrice = 0.0;
  int totalRealtUnits = 0;
  int rentedRealtUnits = 0;
  double averageRealtAnnualYield = 0.0;
  double usdcDepositApy = 0.0;
  double usdcBorrowApy = 0.0;
  double xdaiDepositApy = 0.0;
  double xdaiBorrowApy = 0.0;
  double apyAverage = 0.0;
  double healthFactor = 0.0;
  double ltv = 0.0;
  int walletTokenCount = 0;
  int rmmTokenCount = 0;
  int totalTokenCount = 0;
  int duplicateTokenCount = 0;
  bool isLoadingMain = true;
  bool isLoadingSecondary = true;
  bool isLoadingTransactions = true;
  List<Map<String, dynamic>> rentData = [];
  List<Map<String, dynamic>> detailedRentData = [];
  List<Map<String, dynamic>> propertyData = [];
  List<Map<String, dynamic>> rmmBalances = [];
  List<Map<String, dynamic>> perWalletBalances = [];
  
  // Nouvelle structure de données pour les statistiques détaillées des wallets
  List<Map<String, dynamic>> walletStats = [];
  
  List<Map<String, dynamic>> _allTokens =
      []; // Liste privée pour tous les tokens
  List<Map<String, dynamic>> get allTokens => _allTokens;
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> get portfolio => _portfolio;
  List<Map<String, dynamic>> _recentUpdates = [];
  List<Map<String, dynamic>> get recentUpdates => _recentUpdates;
  List<Map<String, dynamic>> walletTokens = [];
  List<Map<String, dynamic>> realTokens = [];
  List<Map<String, dynamic>> tempRentData = [];
  List<BalanceRecord> balanceHistory = [];
  List<BalanceRecord> walletBalanceHistory = [];
  List<RoiRecord> roiHistory = [];
  List<ApyRecord> apyHistory = [];
  List<HealthAndLtvRecord> healthAndLtvHistory = [];
  List<RentedRecord> rentedHistory = [];
  Map<String, double> customInitPrices = {};
  List<Map<String, dynamic>> propertiesForSale = [];
  List<Map<String, dynamic>> propertiesForSaleFetched = [];
  List<Map<String, dynamic>> yamMarketFetched = [];
  List<Map<String, dynamic>> yamWalletsTransactionsFetched = [];
  List<Map<String, dynamic>> yamMarketData = [];
  List<Map<String, dynamic>> yamMarket = [];
  List<Map<String, dynamic>> yamHistory = [];
  List<Map<String, dynamic>> transactionsHistory = [];
  Map<String, List<Map<String, dynamic>>> transactionsByToken = {};
  List<Map<String, dynamic>> whitelistTokens = [];

  var customInitPricesBox = Hive.box('CustomInitPrices');

  DateTime? lastArchiveTime; // Variable pour stocker le dernier archivage
  DateTime? _lastUpdated; // Stocker la dernière mise à jour
  final Duration _updateCooldown =
      Duration(minutes: 5); // Délai minimal avant la prochaine mise à jour
  final ArchiveManager _archiveManager;

  // Remplacer les propriétés APY du DataManager par une instance de ApyManager
  final ApyManager apyManager;
  
  // Supprimer les propriétés suivantes du DataManager car elles sont maintenant dans ApyManager :
  // depositApyUsdc, depositApyXdai, borrowApyUsdc, borrowApyXdai, initialInvestment
  
  // ... existing code ...

  DataManager({
    required ArchiveManager archiveManager,
    required ApyManager apyManager,
  }) : _archiveManager = archiveManager,
       apyManager = apyManager {
    loadCustomInitPrices(); // Charger les prix personnalisés lors de l'initialisation
    _loadApyReactivityPreference(); // Charger la préférence de réactivité APY
    
    // Initialiser l'ArchiveManager avec une référence à cette instance
    _archiveManager.setDataManager(this);
  }

  /// Charge la préférence de réactivité APY depuis SharedPreferences
  Future<void> _loadApyReactivityPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double reactivity = prefs.getDouble('apyReactivity') ?? 0.2;
      
      // Appliquer la valeur de réactivité aux paramètres de l'ApyManager
      adjustApyReactivity(reactivity);
      
      debugPrint("✅ Préférence de réactivité APY chargée: $reactivity");
    } catch (e) {
      debugPrint("❌ Erreur lors du chargement de la préférence de réactivité APY: $e");
    }
  }

  Future<void> loadWalletsAddresses({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
// Charger les adresses
    evmAddresses = prefs.getStringList('evmAddresses') ?? [];
  }

  Future<void> updateMainInformations({bool forceFetch = false}) async {
    var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache

    // Vérifier si une mise à jour est nécessaire
    if (!forceFetch &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _updateCooldown) {
      debugPrint("⏳ Mise à jour ignorée : déjà effectuée récemment.");
      return;
    }

    _lastUpdated = DateTime.now();
    debugPrint("🔄 Début de la mise à jour des informations principales...");

    // Fonction générique pour fetch + cache
    Future<void> fetchData({
      required Future<List<dynamic>> Function() apiCall,
      required String cacheKey,
      required void Function(List<Map<String, dynamic>>) updateVariable,
      required String debugName,
    }) async {
      try {
        var data = await apiCall();
        if (data.isNotEmpty) {
          debugPrint("✅ Mise à jour des données $debugName.");
          box.put(cacheKey, json.encode(data));
          updateVariable(List<Map<String, dynamic>>.from(data));
        } else {
          debugPrint(
              "⚠️ Pas de nouvelles données $debugName, chargement du cache...");
          var cachedData = box.get(cacheKey);
          if (cachedData != null) {
            updateVariable(
                List<Map<String, dynamic>>.from(json.decode(cachedData)));
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint("❌ Erreur lors de la mise à jour $debugName : $e");
      }
    }

    // Exécution des mises à jour en parallèle
    await Future.wait([
      fetchData(
          apiCall: () => ApiService.fetchWalletTokens(forceFetch: forceFetch),
          cacheKey: 'cachedTokenData_tokens',
          updateVariable: (data) => walletTokens = data,
          debugName: "Tokens"),

      fetchData(
          apiCall: () => ApiService.fetchRealTokens(forceFetch: forceFetch),
          cacheKey: 'cachedRealTokens',
          updateVariable: (data) => realTokens = data,
          debugName: "RealTokens"),
      fetchData(
          apiCall: () => ApiService.fetchRmmBalances(forceFetch: forceFetch),
          cacheKey: 'rmmBalances',
          updateVariable: (data) {
            rmmBalances = data;
            fetchRmmBalances();
          },
          debugName: "RMM Balances"),
      fetchData(
          apiCall: () => ApiService.fetchRentData(forceFetch: forceFetch),
          cacheKey: 'tempRentData',
          updateVariable: (data) => tempRentData = data,
          debugName: "Loyer temporaire"),
      fetchData(
          apiCall: () => ApiService.fetchPropertiesForSale(),
          cacheKey: 'cachedPropertiesForSaleData',
          updateVariable: (data) => propertiesForSaleFetched = data,
          debugName: "Propriétés en vente"),
      // Ajout de l'appel pour récupérer les tokens whitelistés pour chaque wallet
      fetchData(
          apiCall: () =>
              ApiService.fetchWhitelistTokens(forceFetch: forceFetch),
          cacheKey: 'cachedWhitelistTokens',
          updateVariable: (data) => whitelistTokens = data,
          debugName: "Whitelist")
    ]);

    // Charger les historiques
    loadWalletBalanceHistory();
    loadRentedHistory();
    loadRoiHistory();
    loadApyHistory();
    loadHealthAndLtvHistory();
    isLoadingMain = false;
  }

  Future<void> updateSecondaryInformations(BuildContext context,
      {bool forceFetch = false}) async {
    var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache

    // Fonction générique pour fetch + cache
    Future<void> fetchData({
      required Future<List<dynamic>> Function() apiCall,
      required String cacheKey,
      required void Function(List<Map<String, dynamic>>) updateVariable,
      required String debugName,
    }) async {
      try {
        var data = await apiCall();
        if (data.isNotEmpty) {
          debugPrint("✅ Mise à jour des données $debugName.");
          box.put(cacheKey, json.encode(data));
          updateVariable(List<Map<String, dynamic>>.from(data));
        } else {
          debugPrint(
              "⚠️ Pas de nouvelles données $debugName, chargement du cache...");
          var cachedData = box.get(cacheKey);
          if (cachedData != null) {
            updateVariable(
                List<Map<String, dynamic>>.from(json.decode(cachedData)));
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint("❌ Erreur lors de la mise à jour $debugName : $e");
      }
    }

    // Exécution des mises à jour en parallèle
    await Future.wait([
      fetchData(
          apiCall: () =>
              ApiService.fetchYamWalletsTransactions(forceFetch: forceFetch),
          cacheKey: 'cachedWalletsTransactions',
          updateVariable: (data) => yamWalletsTransactionsFetched = data,
          debugName: "YAM Wallets Transactions"),
      fetchData(
          apiCall: () => ApiService.fetchYamMarket(forceFetch: forceFetch),
          cacheKey: 'cachedYamMarket',
          updateVariable: (data) => yamMarketFetched = data,
          debugName: "YAM Market"),
      fetchData(
          apiCall: () => ApiService.fetchTokenVolumes(forceFetch: forceFetch),
          cacheKey: 'yamHistory',
          updateVariable: (data) {
            rmmBalances = data;
            fetchYamHistory();
          },
          debugName: "YAM Volumes History"),
      fetchData(
      apiCall: () => ApiService.fetchTransactionsHistory(forceFetch: forceFetch),
      cacheKey: 'transactionsHistory',
      updateVariable: (data) async {
        transactionsHistory = data;
        await processTransactionsHistory(context, transactionsHistory, yamWalletsTransactionsFetched);
      },
      debugName: "Transactions History"
    ),
    ]);

    isLoadingSecondary = false;
  }

  /// Charge l'historique des balances de portefeuille depuis Hive
  Future<void> loadWalletBalanceHistory() async {
    try {
      var box = Hive.box('balanceHistory');
      List<dynamic>? balanceHistoryJson = box.get(
          'balanceHistory_totalWalletValue'); // Récupérer les données sauvegardées

      // Convertir chaque élément JSON en objet BalanceRecord et l'ajouter à walletBalanceHistory
      walletBalanceHistory = balanceHistoryJson != null
          ? balanceHistoryJson
              .map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson)))
              .toList()
          : [];

      // Si l'historique est vide, on ajoute la valeur actuelle
      if (walletBalanceHistory.isEmpty) {
        walletBalanceHistory.add(BalanceRecord(
            balance: totalWalletValue, 
            timestamp: DateTime.now(),
            tokenType: 'totalWalletValue'));
        saveWalletBalanceHistory();
      }

      // Assigner à balanceHistory (utilisée pour les calculs d'APY) aussi
      balanceHistory = List.from(walletBalanceHistory);
      
      // Calculer l'APY après chargement de l'historique si nous avons suffisamment de données
      if (balanceHistory.length >= 2) {
        try {
          // Calcul de l'APY déplacé vers calculateApyValues
          // On appellera cette fonction plutôt que de refaire le calcul ici
          calculateApyValues();
          debugPrint("✅ APY calculé à partir de l'historique chargé: $netGlobalApy%");
        } catch (e) {
          debugPrint("❌ Erreur lors du calcul initial de l'APY: $e");
        }
      } else {
        debugPrint("⚠️ Historique insuffisant pour calculer l'APY: ${balanceHistory.length} enregistrement(s) disponible(s) (minimum requis: 2)");
      }

      debugPrint(
          "✅ Historique de balance du portefeuille chargé: ${walletBalanceHistory.length} entrées");
    } catch (e) {
      debugPrint("❌ Erreur lors du chargement de l'historique de balance: $e");
    }
  }

  Future<void> loadRentedHistory() async {
    try {
      var box = Hive.box('rentedArchive'); // Ouvrir la boîte Hive
      List<dynamic>? rentedHistoryJson =
          box.get('rented_history'); // Récupérer les données sauvegardées

      rentedHistory = rentedHistoryJson!.map((recordJson) {
        return RentedRecord.fromJson(Map<String, dynamic>.from(recordJson));
      }).toList();

      notifyListeners(); // Notifier les listeners après la mise à jour

      debugPrint(
          '✅ Données de l\'historique du portefeuille chargées avec succès.');
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement des données de l\'historique du portefeuille : $e');
    }
  }

  Future<void> loadRoiHistory() async {
    try {
      var box = Hive.box('roiValueArchive'); // Ouvrir la boîte Hive
      List<dynamic>? roiHistoryJson =
          box.get('roi_history'); // Récupérer les données sauvegardées

      roiHistory = roiHistoryJson!.map((recordJson) {
        return RoiRecord.fromJson(Map<String, dynamic>.from(recordJson));
      }).toList();

      notifyListeners(); // Notifier les listeners après la mise à jour

      debugPrint('Données de l\'historique du ROI chargées avec succès.');
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement des données de l\'historique du ROI : $e');
    }
  }

  Future<void> loadApyHistory() async {
    try {
      var box = Hive.box('apyValueArchive'); // Ouvrir la boîte Hive
      List<dynamic>? apyHistoryJson =
          box.get('apy_history'); // Récupérer les données sauvegardées

      // Charger l'historique
      apyHistory = apyHistoryJson!.map((recordJson) {
        return ApyRecord.fromJson(Map<String, dynamic>.from(recordJson));
      }).toList();

      notifyListeners(); // Notifier les listeners après la mise à jour

      debugPrint('Données de l\'historique APY chargées avec succès.');
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement des données de l\'historique APY : $e');
    }
  }

  Future<void> loadHealthAndLtvHistory() async {
    try {
      var box = Hive.box('HealthAndLtvValueArchive'); // Ouvrir la boîte Hive
      List<dynamic>? healthAndLtvHistoryJson =
          box.get('healthAndLtv_history'); // Récupérer les données sauvegardées

      // Charger l'historique
      healthAndLtvHistory = healthAndLtvHistoryJson!.map((recordJson) {
        return HealthAndLtvRecord.fromJson(
            Map<String, dynamic>.from(recordJson));
      }).toList();

      notifyListeners(); // Notifier les listeners après la mise à jour

      debugPrint('Données de l\'historique healthAndLtv chargées avec succès.');
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement des données de l\'historique healthAndLtv : $e');
    }
  }

  // Sauvegarde l'historique des balances dans Hive
  Future<void> saveWalletBalanceHistory() async {
    debugPrint("🔄 Sauvegarde de l'historique des balances du portefeuille (${walletBalanceHistory.length} enregistrements)");
    
    try {
      var box = Hive.box('walletValueArchive');
      
      // Convertir les données en format JSON
      List<Map<String, dynamic>> balanceHistoryJson =
          walletBalanceHistory.map((record) => record.toJson()).toList();
      
      // Sauvegarder dans Hive
      await box.put('balanceHistory_totalWalletValue', balanceHistoryJson);
      
      // S'assurer que les données dans balanceHistory sont aussi à jour
      balanceHistory = List.from(walletBalanceHistory);
      
      // Mise à jour également dans la boîte 'balanceHistory' pour assurer la cohérence
      var boxBalance = Hive.box('balanceHistory');
      await boxBalance.put('balanceHistory_totalWalletValue', balanceHistoryJson);
      
      debugPrint("✅ Sauvegarde terminée - ${walletBalanceHistory.length} enregistrements");
      
      notifyListeners(); // Notifier les listeners de tout changement
    } catch (e) {
      debugPrint("❌ Erreur lors de la sauvegarde de l'historique: $e");
    }
  }

  Future<void> saveRentedHistory() async {
    var box = Hive.box('rentedArchive');
    List<Map<String, dynamic>> rentedHistoryJson =
        rentedHistory.map((record) => record.toJson()).toList();
    await box.put('rented_history', rentedHistoryJson);
    notifyListeners(); // Notifier les listeners de tout changement
  }

  Future<void> updatedDetailRentVariables({bool forceFetch = false}) async {
    var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache

    try {
      // Mise à jour des détails de loyer détaillés
      var detailedRentDataResult =
          await ApiService.fetchDetailedRentDataForAllWallets();
      if (detailedRentDataResult.isNotEmpty) {
        debugPrint(
            "Mise à jour des détails de loyer avec de nouvelles valeurs.");
        box.put('detailedRentData', json.encode(detailedRentDataResult));
        detailedRentData = detailedRentDataResult.cast<Map<String, dynamic>>();
        notifyListeners(); // Notifier les listeners après la mise à jour
      } else {
        debugPrint("⚠️ Les détails de loyer sont vides, pas de mise à jour.");
      }
    } catch (error) {
      debugPrint("❌ Erreur lors de la récupération des données: $error");
    }
  }

  // Méthode pour ajouter des adresses à un userId
  void addAddressesForUserId(String userId, List<String> addresses) {
    if (userIdToAddresses.containsKey(userId)) {
      userIdToAddresses[userId]!.addAll(addresses);
    } else {
      userIdToAddresses[userId] = addresses;
    }
    saveUserIdToAddresses(); // Sauvegarder après modification
    notifyListeners();
  }

  // Sauvegarder la Map des userIds et adresses dans SharedPreferences
  Future<void> saveUserIdToAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdToAddressesJson = userIdToAddresses.map((userId, addresses) {
      return MapEntry(
          userId, jsonEncode(addresses)); // Encoder les adresses en JSON
    });

    prefs.setString('userIdToAddresses', jsonEncode(userIdToAddressesJson));
  }

  // Charger les userIds et leurs adresses depuis SharedPreferences
  Future<void> loadUserIdToAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('userIdToAddresses');

    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      userIdToAddresses = decodedMap.map((userId, encodedAddresses) {
        final addresses = List<String>.from(jsonDecode(encodedAddresses));
        return MapEntry(userId, addresses);
      });
    }
    notifyListeners();
  }

  // Supprimer une adresse spécifique
  void removeAddressForUserId(String userId, String address) {
    if (userIdToAddresses.containsKey(userId)) {
      userIdToAddresses[userId]!.remove(address);
      if (userIdToAddresses[userId]!.isEmpty) {
        userIdToAddresses
            .remove(userId); // Supprimer le userId si plus d'adresses
      }
      saveUserIdToAddresses(); // Sauvegarder après suppression
      notifyListeners();
    }
  }

  // Supprimer un userId et toutes ses adresses
  void removeUserId(String userId) {
    userIdToAddresses.remove(userId);
    saveUserIdToAddresses(); // Sauvegarder après suppression
    notifyListeners();
  }

  // Méthode pour récupérer les adresses associées à un userId
  List<String>? getAddressesForUserId(String userId) {
    return userIdToAddresses[userId];
  }

  // Méthode pour obtenir tous les userIds
  List<String> getAllUserIds() {
    return userIdToAddresses.keys.toList();
  }

  Future<void> fetchAndStoreAllTokens() async {
    var box = Hive.box('realTokens');

    // Variables temporaires pour calculer les nouvelles valeurs
    int tempTotalTokens = 0;
    double tempTotalInvestment = 0.0;
    double tempNetRentYear = 0.0;
    double tempInitialPrice = 0.0;
    double tempActualPrice = 0.0;
    int tempTotalUnits = 0;
    int tempRentedUnits = 0;
    double tempAnnualYieldSum = 0.0;
    int yieldCount = 0;

    final cachedRealTokens = box.get('cachedRealTokens');
    if (cachedRealTokens != null) {
      realTokens =
          List<Map<String, dynamic>>.from(json.decode(cachedRealTokens));
      debugPrint("Données RealTokens en cache utilisées.");
    }
    List<Map<String, dynamic>> allTokensList = [];

    // Si des tokens existent, les ajouter à la liste des tokens
    if (realTokens.isNotEmpty) {
      _recentUpdates = _extractRecentUpdates(realTokens);
      for (var realToken in realTokens.cast<Map<String, dynamic>>()) {
        // Vérification: Ne pas ajouter si totalTokens est 0 ou si fullName commence par "OLD-"
        // Récupérer la valeur customisée de initPrice si elle existe
        final tokenContractAddress = realToken['uuid'].toLowerCase() ??
            ''; // Utiliser l'adresse du contrat du token

        if (realToken['totalTokens'] != null &&
            realToken['totalTokens'] > 0 &&
            realToken['fullName'] != null &&
            !realToken['fullName'].startsWith('OLD-') &&
            realToken['uuid'].toLowerCase() !=
                Parameters.rwaTokenAddress.toLowerCase()) {
          double? customInitPrice = customInitPrices[tokenContractAddress];
          double initPrice = customInitPrice ??
              (realToken['historic']['init_price'] as num?)?.toDouble() ??
              0.0;

          String fullName = realToken['fullName'];
          List<String> parts = fullName.split(',');
          String country = parts.length == 4 ? parts[3].trim() : 'USA';
          List<String> parts2 = fullName.split(',');
          String regionCode =
              parts2.length >= 3 ? parts[2].trim().substring(0, 2) : 'unknown';
          List<String> parts3 = fullName.split(',');
          String city = parts3.length >= 2 ? parts[1].trim() : 'Unknown';

          allTokensList.add({
            'uuid': tokenContractAddress,
            'shortName': realToken['shortName'],
            'fullName': realToken['fullName'],
            'country': country,
            'regionCode': regionCode,
            'city': city,
            'imageLink': realToken['imageLink'],
            'lat': realToken['coordinate']['lat'],
            'lng': realToken['coordinate']['lng'],
            'totalTokens': realToken['totalTokens'],
            'tokenPrice': realToken['tokenPrice'],
            'totalValue': realToken['totalInvestment'],
            'amount': 0.0,
            'annualPercentageYield': realToken['annualPercentageYield'],
            'dailyIncome':
                realToken['netRentDayPerToken'] * realToken['totalTokens'],
            'monthlyIncome':
                realToken['netRentMonthPerToken'] * realToken['totalTokens'],
            'yearlyIncome':
                realToken['netRentYearPerToken'] * realToken['totalTokens'],
            'initialLaunchDate': realToken['initialLaunchDate']?['date'],
            'totalInvestment': realToken['totalInvestment'],
            'underlyingAssetPrice': realToken['underlyingAssetPrice'] ?? 0.0,
            'initialMaintenanceReserve': realToken['initialMaintenanceReserve'],
            'rentalType': realToken['rentalType'],
            'rentStartDate': realToken['rentStartDate']?['date'],
            'rentedUnits': realToken['rentedUnits'],
            'totalUnits': realToken['totalUnits'],
            'grossRentMonth': realToken['grossRentMonth'],
            'netRentMonth': realToken['netRentMonth'],
            'constructionYear': realToken['constructionYear'],
            'propertyStories': realToken['propertyStories'],
            'lotSize': realToken['lotSize'],
            'squareFeet': realToken['squareFeet'],
            'marketplaceLink': realToken['marketplaceLink'],
            'propertyType': realToken['propertyType'],
            'historic': realToken['historic'],
            'ethereumContract': realToken['ethereumContract'],
            'gnosisContract': realToken['gnosisContract'],
            'initPrice': initPrice,
            'totalRentReceived': 0.0,
            'initialTotalValue': initPrice,
            'propertyMaintenanceMonthly':
                realToken['propertyMaintenanceMonthly'],
            'propertyManagement': realToken['propertyManagement'],
            'realtPlatform': realToken['realtPlatform'],
            'insurance': realToken['insurance'],
            'propertyTaxes': realToken['propertyTaxes'],
            'realtListingFee': realToken['realtListingFee'],
            'renovationReserve': realToken['renovationReserve'],
            'miscellaneousCosts': realToken['miscellaneousCosts'],
            'section8paid': realToken['section8paid'] ?? 0.0,

            'yamTotalVolume': 0.0, // Ajout de la valeur Yam calculée
            'yamAverageValue': 0.0, // Ajout de la valeur moyenne Yam calculée
            'transactions': []
          });

          tempTotalTokens += 1; // Conversion explicite en int
          tempTotalInvestment += realToken['totalInvestment'] ?? 0.0;
          tempNetRentYear += realToken['netRentYearPerToken'] *
              (realToken['totalTokens'] as num).toInt();
          tempTotalUnits += (realToken['totalUnits'] as num?)?.toInt() ??
              0; // Conversion en int avec vérification
          tempRentedUnits += (realToken['rentedUnits'] as num?)?.toInt() ?? 0;
          // Gérer le cas où tokenPrice est soit un num soit une liste
          dynamic tokenPriceData = realToken['tokenPrice'];
          double? tokenPrice;
          int totalTokens = (realToken['totalTokens'] as num).toInt();

          if (tokenPriceData is List && tokenPriceData.isNotEmpty) {
            tokenPrice = (tokenPriceData.first as num)
                .toDouble(); // Utiliser le premier élément de la liste
          } else if (tokenPriceData is num) {
            tokenPrice = tokenPriceData
                .toDouble(); // Utiliser directement si c'est un num
          }

          tempInitialPrice += initPrice * totalTokens;

          if (tokenPrice != null) {
            tempActualPrice += tokenPrice * totalTokens;
          }

          // Calcul du rendement annuel
          if (realToken['annualPercentageYield'] != null) {
            tempAnnualYieldSum += realToken['annualPercentageYield'];
            yieldCount++;
          }
        }
      }
    }

    // Mettre à jour la liste des tokens
    _allTokens = allTokensList;
    debugPrint(
        "Tokens récupérés: ${allTokensList.length}"); // Vérifiez que vous obtenez bien des tokens

    // Mise à jour des variables partagées
    totalRealtTokens = tempTotalTokens; //en retire le RWA token dans le calcul
    totalRealtInvestment = tempTotalInvestment;
    realtInitialPrice = tempInitialPrice;
    realtActualPrice = tempActualPrice;
    netRealtRentYear = tempNetRentYear;
    totalRealtUnits = tempTotalUnits;
    rentedRealtUnits = tempRentedUnits;
    averageRealtAnnualYield =
        yieldCount > 0 ? tempAnnualYieldSum / yieldCount : 0.0;

    _archiveManager
        .archiveRentedValue(rentedRealtUnits / totalRealtUnits * 100);

    // Notifie les widgets que les données ont changé
    notifyListeners();
  }

  // Méthode pour récupérer et calculer les données pour le Dashboard et Portfolio
  Future<void> fetchAndCalculateData({bool forceFetch = false}) async {
    debugPrint("🔄 Début de la récupération des données de tokens...");

    var box = Hive.box('realTokens');
    initialTotalValue = 0.0;
    yamTotalValue = 0.0;

    // Charger les données en cache si disponibles
    final cachedTokens = box.get('cachedTokenData_tokens');
    if (cachedTokens != null) {
      walletTokens = List<Map<String, dynamic>>.from(json.decode(cachedTokens));
      debugPrint("✅ Données Tokens en cache utilisées.");
    }

    if (walletTokens.isEmpty) {
      debugPrint("⚠️ Aucun token récupéré depuis l'API.");
    } else {
      debugPrint("Nombre de tokens récupérés: ${walletTokens.length}");
    }

    // Variables temporaires de calcul global
    double walletValueSum = 0.0;
    double rmmValueSum = 0.0;
    double rwaValue = 0.0;
    double walletTokensSum = 0.0;
    double rmmTokensSum = 0.0;
    double annualYieldSum = 0.0;
    double dailyRentSum = 0.0;
    double monthlyRentSum = 0.0;
    double yearlyRentSum = 0.0;
    int yieldCount = 0;
    List<Map<String, dynamic>> newPortfolio = [];

    // Réinitialisation des compteurs globaux
    walletTokenCount = 0;
    rmmTokenCount = 0;
    rentedUnits = 0;
    totalUnits = 0;

    // Sets pour stocker les tokens et adresses uniques
    Set<String> uniqueWalletTokens = {};
    Set<String> uniqueRmmTokens = {};
    Set<String> uniqueRentedUnitAddresses = {};
    Set<String> uniqueTotalUnitAddresses = {};

    // Fonction locale pour parser le fullName
    Map<String, String> parseFullName(String fullName) {
      final parts = fullName.split(',');
      final country = parts.length == 4 ? parts[3].trim() : 'USA';
      final regionCode =
          parts.length >= 3 ? parts[2].trim().substring(0, 2) : 'unknown';
      final city = parts.length >= 2 ? parts[1].trim() : 'Unknown City';
      return {
        'country': country,
        'regionCode': regionCode,
        'city': city,
      };
    }

    // Fonction locale pour mettre à jour les compteurs d'unités (pour éviter le comptage en double)
    void updateUnitCounters(
        String tokenAddress, Map<String, dynamic> realToken) {
      if (!uniqueRentedUnitAddresses.contains(tokenAddress)) {
        rentedUnits += (realToken['rentedUnits'] ?? 0) as int;
        uniqueRentedUnitAddresses.add(tokenAddress);
      }
      if (!uniqueTotalUnitAddresses.contains(tokenAddress)) {
        totalUnits += (realToken['totalUnits'] ?? 0) as int;
        uniqueTotalUnitAddresses.add(tokenAddress);
      }
    }

    debugPrint("🔍 Traitement des tokens...");
    for (var walletToken in walletTokens) {
      final tokenAddress = walletToken['token'].toLowerCase();
      // debugPrint("🔍 Traitement du token: ${walletToken['token']} (type: ${walletToken['type']})");
if (tokenAddress == "0xfc5073816fe9671859ef1e6936efd23bb7814274") {
    debugPrint("→ Traitement de S 1418 W Marquette : wallet = ${walletToken['wallet']}, amount = ${walletToken['amount']}");
  }
      // Recherche du token correspondant dans realTokens
      final matchingRealToken =
          realTokens.cast<Map<String, dynamic>>().firstWhere(
                (realToken) => realToken['uuid'].toLowerCase() == tokenAddress,
                orElse: () => <String, dynamic>{},
              );
      if (matchingRealToken.isEmpty) {
        debugPrint(
            "⚠️ Aucun RealToken correspondant trouvé pour le token: $tokenAddress");
        continue;
      }
     // debugPrint("✅ Token trouvé: ${matchingRealToken['shortName']}");

      final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
      final double tokenValue = walletToken['amount'] * tokenPrice;

      // Mise à jour des compteurs d'unités (une seule fois par token)
      updateUnitCounters(tokenAddress, matchingRealToken);

      // Séparation entre tokens RWA et autres
      if (tokenAddress == Parameters.rwaTokenAddress.toLowerCase()) {
        rwaValue += tokenValue;
      } else {
        if (walletToken['type'] == "wallet") {
          walletValueSum += tokenValue;
          walletTokensSum += walletToken['amount'];
          uniqueWalletTokens.add(tokenAddress);
        } else {
          rmmValueSum += tokenValue;
          rmmTokensSum += walletToken['amount'];
          uniqueRmmTokens.add(tokenAddress);
        }

        // Calcul des revenus si la date de lancement est passée
        final today = DateTime.now();
        final launchDateString = matchingRealToken['rentStartDate']?['date'];
        if (launchDateString != null) {
          final launchDate = DateTime.tryParse(launchDateString);
          if (launchDate != null && launchDate.isBefore(today)) {
            annualYieldSum += matchingRealToken['annualPercentageYield'];
            yieldCount++;
            dailyRentSum +=
                matchingRealToken['netRentDayPerToken'] * walletToken['amount'];
            monthlyRentSum += matchingRealToken['netRentMonthPerToken'] *
                walletToken['amount'];
            yearlyRentSum += matchingRealToken['netRentYearPerToken'] *
                walletToken['amount'];
          }
        }
      }

      // Récupération du prix d'initialisation
      final tokenContractAddress = matchingRealToken['uuid'].toLowerCase();
      double? customInitPrice = customInitPrices[tokenContractAddress];
      double initPrice = customInitPrice ??
          ((matchingRealToken['historic']['init_price'] as num?)?.toDouble() ??
              0.0);

      // Parsing du fullName pour obtenir country, regionCode et city
      final nameDetails = parseFullName(matchingRealToken['fullName']);

      // Récupération des données Yam
      final yamData = yamHistory.firstWhere(
        (yam) => yam['id'].toLowerCase() == tokenContractAddress,
        orElse: () => <String, dynamic>{},
      );
      final double yamTotalVolume = yamData['totalVolume'] ?? 1.0;
      final double yamAverageValue =
          (yamData['averageValue'] != null && yamData['averageValue'] != 0)
              ? yamData['averageValue']
              : tokenPrice;

      // Fusion dans le portfolio par token (agrégation si le même token apparaît plusieurs fois)
      int index = newPortfolio.indexWhere((item) => item['uuid'] == tokenContractAddress);
      if (index != -1) {
        Map<String, dynamic> existingItem = newPortfolio[index];
        List<String> wallets = existingItem['wallets'] is List<String>
            ? List<String>.from(existingItem['wallets'])
            : [];
        if (!wallets.contains(walletToken['wallet'])) {
          wallets.add(walletToken['wallet']);
          // Log dès qu'un nouveau wallet est ajouté pour ce token
        }
        existingItem['wallets'] += wallets;
        existingItem['amount'] += walletToken['amount'];
        existingItem['totalValue'] = existingItem['amount'] * tokenPrice;
        existingItem['initialTotalValue'] = existingItem['amount'] * initPrice;
        existingItem['dailyIncome'] = matchingRealToken['netRentDayPerToken'] * existingItem['amount'];
        existingItem['monthlyIncome'] = matchingRealToken['netRentMonthPerToken'] * existingItem['amount'];
        existingItem['yearlyIncome'] = matchingRealToken['netRentYearPerToken'] * existingItem['amount'];
      } else {
        Map<String, dynamic> portfolioItem = {
          'id': matchingRealToken['id'],
          'uuid': tokenContractAddress,
          'shortName': matchingRealToken['shortName'],
          'fullName': matchingRealToken['fullName'],
          'country': nameDetails['country'],
          'regionCode': nameDetails['regionCode'],
          'city': nameDetails['city'],
          'imageLink': matchingRealToken['imageLink'],
          'lat': matchingRealToken['coordinate']['lat'],
          'lng': matchingRealToken['coordinate']['lng'],
          'amount': walletToken['amount'],
          'totalTokens': matchingRealToken['totalTokens'],
          'source': walletToken['type'],
          'tokenPrice': tokenPrice,
          'totalValue': tokenValue,
          'initialTotalValue': walletToken['amount'] * initPrice,
          'annualPercentageYield': matchingRealToken['annualPercentageYield'],
          'dailyIncome':
              matchingRealToken['netRentDayPerToken'] * walletToken['amount'],
          'monthlyIncome':
              matchingRealToken['netRentMonthPerToken'] * walletToken['amount'],
          'yearlyIncome':
              matchingRealToken['netRentYearPerToken'] * walletToken['amount'],
          'initialLaunchDate': matchingRealToken['initialLaunchDate']?['date'],
          'bedroomBath': matchingRealToken['bedroomBath'],
          // financials details
          'totalInvestment': matchingRealToken['totalInvestment'] ?? 0.0,
          'underlyingAssetPrice':
              matchingRealToken['underlyingAssetPrice'] ?? 0.0,
          'realtListingFee': matchingRealToken['realtListingFee'],
          'initialMaintenanceReserve':
              matchingRealToken['initialMaintenanceReserve'],
          'renovationReserve': matchingRealToken['renovationReserve'],
          'miscellaneousCosts': matchingRealToken['miscellaneousCosts'],
          'grossRentMonth': matchingRealToken['grossRentMonth'],
          'netRentMonth': matchingRealToken['netRentMonth'],
          'propertyMaintenanceMonthly':
              matchingRealToken['propertyMaintenanceMonthly'],
          'propertyManagement': matchingRealToken['propertyManagement'],
          'realtPlatform': matchingRealToken['realtPlatform'],
          'insurance': matchingRealToken['insurance'],
          'propertyTaxes': matchingRealToken['propertyTaxes'],
          'rentalType': matchingRealToken['rentalType'],
          'rentStartDate': matchingRealToken['rentStartDate']?['date'],
          'rentedUnits': matchingRealToken['rentedUnits'],
          'totalUnits': matchingRealToken['totalUnits'],
          'constructionYear': matchingRealToken['constructionYear'],
          'propertyStories': matchingRealToken['propertyStories'],
          'lotSize': matchingRealToken['lotSize'],
          'squareFeet': matchingRealToken['squareFeet'],
          'marketplaceLink': matchingRealToken['marketplaceLink'],
          'propertyType': matchingRealToken['propertyType'],
          'historic': matchingRealToken['historic'],
          'ethereumContract': matchingRealToken['ethereumContract'],
          'gnosisContract': matchingRealToken['gnosisContract'],
          'totalRentReceived': 0.0, // sera mis à jour juste après
          'initPrice': initPrice,
          'section8paid': matchingRealToken['section8paid'] ?? 0.0,
          'yamTotalVolume': yamTotalVolume,
          'yamAverageValue': yamAverageValue,
          'transactions': transactionsByToken[tokenContractAddress] ?? [],
          // Nouveau champ "wallets" pour suivre dans quels wallets ce token apparaît
          'wallets': [walletToken['wallet']],
        };
        newPortfolio.add(portfolioItem);
        // Log de création de l'entrée dans le portfolio pour ce token
      }

      initialTotalValue += walletToken['amount'] * initPrice;
      yamTotalValue += walletToken['amount'] * yamAverageValue;

      // Mise à jour du loyer total pour ce token
      if (tokenAddress.isNotEmpty) {
        double? rentDetails = getRentDetailsForToken(tokenAddress);
        int index =
            newPortfolio.indexWhere((item) => item['uuid'] == tokenAddress);
        if (index != -1) {
          newPortfolio[index]['totalRentReceived'] = rentDetails;
        }
      }
    } // Fin de la boucle sur walletTokens

    // -------- Regroupement par wallet --------
    // Pour chaque token dans la liste brute, on regroupe par wallet et on cumule :
    // - La valeur totale des tokens de type "wallet"
    // - La somme des quantités
    // - Le nombre de tokens présents
    Map<String, Map<String, dynamic>> walletTotals = {};
    for (var token in walletTokens) {
      final String wallet = token['wallet'];
      // Initialisation si nécessaire
      if (!walletTotals.containsKey(wallet)) {
        walletTotals[wallet] = {
          'walletValueSum': 0.0,
          'walletTokensSum': 0.0,
          'tokenCount': 0,
        };
      }
      final tokenAddress = token['token'].toLowerCase();
      final matchingRealToken =
          realTokens.cast<Map<String, dynamic>>().firstWhere(
                (rt) => rt['uuid'].toLowerCase() == tokenAddress,
                orElse: () => <String, dynamic>{},
              );
      if (matchingRealToken.isEmpty) continue;
      final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
      final double tokenValue = token['amount'] * tokenPrice;
      // On additionne uniquement pour les tokens de type "wallet"
      if (token['type'] == "wallet") {
        walletTotals[wallet]!['walletValueSum'] += tokenValue;
        walletTotals[wallet]!['walletTokensSum'] += token['amount'];
      }
      walletTotals[wallet]!['tokenCount'] += 1;
    }

    // Affichage des statistiques par wallet
    walletStats = []; // Réinitialiser la liste des statistiques
    walletTotals.forEach((wallet, totals) {
      debugPrint(
          "Wallet: $wallet → Valeur: ${totals['walletValueSum']}, Quantité: ${totals['walletTokensSum']}, Nombre de tokens: ${totals['tokenCount']}");
      
      // Ajouter les statistiques dans la variable globale
      walletStats.add({
        'address': wallet,
        'walletValueSum': totals['walletValueSum'] as double,
        'walletTokensSum': totals['walletTokensSum'] as double,
        'tokenCount': totals['tokenCount'] as int,
        'rmmTokensSum': 0.0, // Sera mis à jour plus tard
        'rmmValue': 0.0, // Sera mis à jour plus tard
      });
    });

    // -------- Calcul de la valeur RMM par wallet --------
    Map<String, double> walletRmmValues = {};
    Map<String, double> walletRmmTokensSum = {}; // Pour compter le nombre de tokens en RMM
    
    for (var token in walletTokens) {
      // On considère ici uniquement les tokens de type RMM (donc différents de "wallet")
      if (token['type'] != "wallet") {
        final String wallet = token['wallet'];
        final String tokenAddress = token['token'].toLowerCase();
        // Recherche du token correspondant dans realTokens (comme déjà fait précédemment)
        final matchingRealToken =
            realTokens.cast<Map<String, dynamic>>().firstWhere(
                  (rt) => rt['uuid'].toLowerCase() == tokenAddress,
                  orElse: () => <String, dynamic>{},
                );
        if (matchingRealToken.isEmpty) continue;
        final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
        final double tokenValue = token['amount'] * tokenPrice;
        // Cumuler la valeur RMM pour ce wallet
        walletRmmValues[wallet] = (walletRmmValues[wallet] ?? 0.0) + tokenValue;
        // Cumuler le nombre de tokens en RMM
        walletRmmTokensSum[wallet] = (walletRmmTokensSum[wallet] ?? 0.0) + token['amount'];
      }
    }
    // Stocker ces valeurs dans une variable accessible (par exemple, dans DataManager)
    perWalletRmmValues = walletRmmValues;
    
    // Mettre à jour les statistiques des wallets avec les valeurs RMM
    for (var stat in walletStats) {
      final String address = stat['address'] as String;
      stat['rmmValue'] = walletRmmValues[address] ?? 0.0;
      stat['rmmTokensSum'] = walletRmmTokensSum[address] ?? 0.0;
    }
    
    walletRmmValues.forEach((wallet, value) {
      debugPrint("Wallet: $wallet → Valeur RMM: $value");
    });

    // -------- Mise à jour des variables globales pour le Dashboard --------
    totalWalletValue = walletValueSum +
        rmmValueSum +
        rwaValue +
        totalUsdcDepositBalance +
        totalXdaiDepositBalance -
        totalUsdcBorrowBalance -
        totalXdaiBorrowBalance;
    _archiveManager.archiveTotalWalletValue(totalWalletValue);

    walletValue = double.parse(walletValueSum.toStringAsFixed(3));
    rmmValue = double.parse(rmmValueSum.toStringAsFixed(3));
    rwaHoldingsValue = double.parse(rwaValue.toStringAsFixed(3));
    walletTokensSums = double.parse(walletTokensSum.toStringAsFixed(3));
    rmmTokensSums = double.parse(rmmTokensSum.toStringAsFixed(3));
    totalTokens = (walletTokensSum + rmmTokensSum);
    averageAnnualYield = yieldCount > 0 ? annualYieldSum / yieldCount : 0;
    dailyRent = dailyRentSum;
    weeklyRent = dailyRentSum * 7;
    monthlyRent = monthlyRentSum;
    yearlyRent = yearlyRentSum;

    walletTokenCount = uniqueWalletTokens.length;
    rmmTokenCount = uniqueRmmTokens.length;
    final Set<String> allUniqueTokens = {
      ...uniqueWalletTokens,
      ...uniqueRmmTokens
    };
    totalTokenCount = allUniqueTokens.length;
    duplicateTokenCount =
        uniqueWalletTokens.intersection(uniqueRmmTokens).length;

    _portfolio = newPortfolio;
    roiGlobalValue = getTotalRentReceived() / initialTotalValue * 100;
    _archiveManager.archiveRoiValue(roiGlobalValue);

    // Calcul de l'APY global avec calculateApyValues au lieu de le faire directement ici
    calculateApyValues();
    
    healthFactor =
        (rmmValue * 0.7) / (totalUsdcBorrowBalance + totalXdaiBorrowBalance);
    ltv = ((totalUsdcBorrowBalance + totalXdaiBorrowBalance) / rmmValue * 100);
    _archiveManager.archiveHealthAndLtvValue(healthFactor, ltv);

    notifyListeners();
  }

  List<Map<String, dynamic>> getCumulativeRentEvolution() {
    List<Map<String, dynamic>> cumulativeRentList = [];
    double cumulativeRent = 0.0;

    // Filtrer les entrées valides et trier par `rentStartDate`
    final validPortfolioEntries = _portfolio.where((entry) {
      return entry['rentStartDate'] != null && entry['dailyIncome'] != null;
    }).toList()
      ..sort((a, b) {
        DateTime dateA = DateTime.parse(a['rentStartDate']);
        DateTime dateB = DateTime.parse(b['rentStartDate']);
        return dateA.compareTo(dateB);
      });

    // Accumuler les loyers
    for (var portfolioEntry in validPortfolioEntries) {
      DateTime rentStartDate = DateTime.parse(portfolioEntry['rentStartDate']);
      double dailyIncome = portfolioEntry['dailyIncome'] ?? 0.0;

      // Ajouter loyer au cumul
      cumulativeRent += dailyIncome * 7; // Supposons un calcul hebdomadaire

      // Ajouter à la liste des loyers cumulés
      cumulativeRentList.add({
        'rentStartDate': rentStartDate,
        'cumulativeRent': cumulativeRent,
      });
    }

    return cumulativeRentList;
  }

  // Méthode pour extraire les mises à jour récentes sur les 30 derniers jours
  List<Map<String, dynamic>> _extractRecentUpdates(
      List<dynamic> realTokensRaw) {
    final List<Map<String, dynamic>> realTokens =
        realTokensRaw.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> recentUpdates = [];

    for (var token in realTokens) {
      // Vérification si update30 existe, est une liste et est non vide
      if (token.containsKey('update30') &&
          token['update30'] is List &&
          token['update30'].isNotEmpty) {
        // debugPrint("Processing updates for token: ${token['shortName'] ?? 'Nom inconnu'}");

        // Récupérer les informations de base du token
        final String shortName = token['shortName'] ?? 'Nom inconnu';
        final String imageLink =
            (token['imageLink'] != null && token['imageLink'].isNotEmpty)
                ? token['imageLink'][0]
                : 'Lien d\'image non disponible';

        // Filtrer et formater les mises à jour pertinentes
        List<Map<String, dynamic>> updatesWithDetails =
            List<Map<String, dynamic>>.from(token['update30'])
                .where((update) =>
                    update.containsKey('key') &&
                    _isRelevantKey(update['key'])) // Vérifier que 'key' existe
                .map((update) => _formatUpdateDetails(
                    update, shortName, imageLink)) // Formater les détails
                .toList();

        // Ajouter les mises à jour extraites dans recentUpdates
        recentUpdates.addAll(updatesWithDetails);
      } else {
        //debugPrint('Aucune mise à jour pour le token : ${token['shortName'] ?? 'Nom inconnu'}');
      }
    }

    // Trier les mises à jour par date
    recentUpdates.sort((a, b) =>
        DateTime.parse(b['timsync']).compareTo(DateTime.parse(a['timsync'])));
    return recentUpdates;
  }

  // Vérifier les clés pertinentes
  bool _isRelevantKey(String key) {
    return key == 'netRentYearPerToken' || key == 'annualPercentageYield';
  }

  // Formater les détails des mises à jour
  Map<String, dynamic> _formatUpdateDetails(
      Map<String, dynamic> update, String shortName, String imageLink) {
    String formattedKey = 'Donnée inconnue';
    String formattedOldValue = 'Valeur inconnue';
    String formattedNewValue = 'Valeur inconnue';

    // Vérifiez que les clés existent avant de les utiliser
    if (update['key'] == 'netRentYearPerToken') {
      double newValue = double.tryParse(update['new_value'] ?? '0') ?? 0.0;
      double oldValue = double.tryParse(update['old_value'] ?? '0') ?? 0.0;
      formattedKey = 'Net Rent Per Token (Annuel)';
      formattedOldValue = "${oldValue.toStringAsFixed(2)} USD";
      formattedNewValue = "${newValue.toStringAsFixed(2)} USD";
    } else if (update['key'] == 'annualPercentageYield') {
      double newValue = double.tryParse(update['new_value'] ?? '0') ?? 0.0;
      double oldValue = double.tryParse(update['old_value'] ?? '0') ?? 0.0;
      formattedKey = 'Rendement Annuel (%)';
      formattedOldValue = "${oldValue.toStringAsFixed(2)}%";
      formattedNewValue = "${newValue.toStringAsFixed(2)}%";
    }

    return {
      'shortName': shortName,
      'formattedKey': formattedKey,
      'formattedOldValue': formattedOldValue,
      'formattedNewValue': formattedNewValue,
      'timsync': update['timsync'] ?? '', // Assurez-vous que 'timsync' existe
      'imageLink': imageLink,
    };
  }

  // Méthode pour récupérer les données des loyers
  Future<void> fetchRentData({bool forceFetch = false}) async {
    var box = Hive.box('realTokens');

    // Charger les données en cache si disponibles
    final cachedRentData = box.get('cachedRentData');
    if (cachedRentData != null) {
      rentData = List<Map<String, dynamic>>.from(json.decode(cachedRentData));
      debugPrint("Données rentData en cache utilisées.");
    }
    Future(() async {
      try {
        // Exécuter l'appel d'API pour récupérer les données de loyer

        // Vérifier si les résultats ne sont pas vides avant de mettre à jour les variables
        if (tempRentData.isNotEmpty) {
          debugPrint(
              "Mise à jour des données de rentData avec de nouvelles valeurs.");
          rentData = tempRentData; // Mise à jour de la variable locale
          box.put('cachedRentData', json.encode(tempRentData));
        } else {
          debugPrint(
              "Les résultats des données de rentData sont vides, pas de mise à jour.");
        }
      } catch (e) {
        debugPrint("Erreur lors de la récupération des données de loyer: $e");
      }
    }).then((_) {
      notifyListeners(); // Notifier les listeners une fois les données mises à jour
    });
  }

  Future<void> processTransactionsHistory(
    BuildContext context,
    List<Map<String, dynamic>> transactionsHistory,
    List<Map<String, dynamic>> yamTransactions) async {
  
  // Capturer les valeurs localisées au début de la méthode
  final String internalTransferText = S.of(context).internal_transfer;
  final String purchaseText = S.of(context).purchase;
  final String yamText = S.of(context).yam;
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final Set<String> evmAddresses = Set.from(prefs.getStringList('evmAddresses') ?? {});

  Map<String, List<Map<String, dynamic>>> tempTransactionsByToken = {};

  debugPrint("📌 Début du traitement des transactions...");
  debugPrint("📊 Nombre de transactions API: ${transactionsHistory.length}");
  debugPrint("📊 Nombre de transactions YAM: ${yamTransactions.length}");

  for (var transaction in transactionsHistory) {
    final String? tokenId = transaction['Token ID']?.toLowerCase();
    final String? timestampStr = transaction['timestamp'];
    final double? amount = (transaction['amount'] as num?)?.toDouble();
    final String? sender = transaction['sender']?.toLowerCase();
    final String? transactionId = transaction['Transaction ID']?.toLowerCase();

    if (tokenId == null || timestampStr == null || amount == null || transactionId == null) {
      debugPrint("⚠️ Transaction ignorée (champ manquant): $transaction");
      continue;
    }

    try {
      // ✅ Convertir le timestamp Unix en DateTime
      final int timestampMs;
      try {
        timestampMs = int.parse(timestampStr) * 1000; // Convertir en millisecondes
      } catch (e) {
        debugPrint("⚠️ Erreur de conversion du timestamp '$timestampStr': $e");
        continue;
      }

      DateTime dateTime;
      try {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);
      } catch (e) {
        debugPrint("⚠️ Erreur de création de DateTime à partir du timestamp $timestampMs: $e");
        continue;
      }

      final bool isInternalTransfer = evmAddresses.contains(sender);
      // Utiliser les textes capturés au lieu de S.of(context)
      String transactionType = isInternalTransfer ? internalTransferText : purchaseText;

      try {
        final matchingYamTransaction = yamTransactions.firstWhere(
            (yamTransaction) {
              final String? yamId =
                  yamTransaction['transaction_id']?.toLowerCase();
              if (yamId == null || yamId.isEmpty) return false;
              final String yamIdTrimmed = yamId.substring(0, yamId.length - 10);
              final bool match = transactionId.startsWith(yamIdTrimmed);
              return match;
            },
            orElse: () => {},
          );

        double? price;
        if (matchingYamTransaction.isNotEmpty) {
          final double? rawPrice = (matchingYamTransaction['price'] as num?)?.toDouble();
          price = rawPrice ?? 0.0;
          // Utiliser le texte capturé pour YAM
          transactionType = yamText;
          debugPrint("✅ Correspondance YAM trouvée ! Prix: $price");
        } else {
          debugPrint("❌ Aucune correspondance YAM trouvée.");
        }

        tempTransactionsByToken.putIfAbsent(tokenId, () => []).add({
          "amount": amount,
          "dateTime": dateTime,
          "transactionType": transactionType,
          "price": price,
        });
      } catch (e) {
        debugPrint("⚠️ Erreur lors du traitement des informations YAM: $e");
        continue;
      }
    } catch (e) {
      debugPrint("⚠️ Erreur de parsing de la transaction: $transaction. Détail: $e");
      continue;
    }
  }

  // ✅ **Ajout des transactions YAM manquantes**
  debugPrint("📌 Vérification des transactions YAM non trouvées dans transactionsHistory...");
  for (var yamTransaction in yamTransactions) {
    final String? yamId = yamTransaction['transaction_id']?.toLowerCase();
    if (yamId == null || yamId.isEmpty) continue;

    final String yamIdTrimmed = yamId.substring(0, yamId.length - 10);
    final bool alreadyExists = transactionsHistory.any((transaction) =>
        transaction['Transaction ID']?.toLowerCase().startsWith(yamIdTrimmed) ?? false);

    if (!alreadyExists) {
      final String? yamTimestamp = yamTransaction['timestamp'];
      final double? yamPrice = (yamTransaction['price'] as num?)?.toDouble();
      final double? yamQuantity = (yamTransaction['quantity'] as num?)?.toDouble();
      final String? offerTokenAddress = yamTransaction['offer_token_address']?.toLowerCase();

      if (yamTimestamp == null || yamPrice == null || yamQuantity == null || offerTokenAddress == null) {
        debugPrint("⚠️ Transaction YAM ignorée (champ manquant): $yamTransaction");
        continue;
      }

      final int timestampMs;
      try {
        timestampMs = int.parse(yamTimestamp) * 1000;
      } catch (e) {
        debugPrint("⚠️ Erreur de conversion du timestamp YAM '$yamTimestamp': $e");
        continue;
      }

      debugPrint("➕ Ajout d'une nouvelle transaction YAM | ID: $yamId, Token: $offerTokenAddress, Amount: $yamQuantity, Price: $yamPrice");

      tempTransactionsByToken.putIfAbsent(offerTokenAddress, () => []).add({
        "amount": yamQuantity,
        "dateTime": DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true),
        "transactionType": yamText,
        "price": yamPrice,
      });
    }
  }

  debugPrint("✅ Fin du traitement des transactions.");
  transactionsByToken.addAll(tempTransactionsByToken);
  isLoadingTransactions = false;
}

  // Méthode pour récupérer les données des propriétés
  Future<void> fetchPropertyData({bool forceFetch = false}) async {
    List<Map<String, dynamic>> tempPropertyData = [];

    // Fusionner les tokens du portefeuille et du RMM
    List<dynamic> allTokens = [];
    for (var wallet in walletTokens) {
      allTokens
          .addAll(wallet['balances']); // Ajouter tous les balances des wallets
    }

    // Parcourir chaque token du portefeuille et du RMM
    for (var token in allTokens) {
      if (token != null &&
          token['token'] != null &&
          (token['token']['address'] != null || token['token']['id'] != null)) {
        final tokenAddress =
            (token['token']['address'] ?? token['token']['id'])?.toLowerCase();

        // Correspondre avec les RealTokens
        final matchingRealToken = realTokens
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (realToken) =>
                  realToken['uuid'].toLowerCase() == tokenAddress.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );

        if (matchingRealToken.isNotEmpty &&
            matchingRealToken['propertyType'] != null) {
          final propertyType = matchingRealToken['propertyType'];

          // Vérifiez si le type de propriété existe déjà dans propertyData
          final existingPropertyType = tempPropertyData.firstWhere(
            (data) => data['propertyType'] == propertyType,
            orElse: () => <String,
                dynamic>{}, // Renvoie un map vide si aucune correspondance n'est trouvée
          );

          if (existingPropertyType.isNotEmpty) {
            // Incrémenter le compte si la propriété existe déjà
            existingPropertyType['count'] += 1;
          } else {
            // Ajouter une nouvelle entrée si la propriété n'existe pas encore
            tempPropertyData.add({'propertyType': propertyType, 'count': 1});
          }
        }
      } else {
        debugPrint('Invalid token or missing address for token: $token');
      }
    }
    propertyData = tempPropertyData;
    notifyListeners();
  }

  // Méthode pour réinitialiser toutes les données
  Future<void> resetData() async {
    // Remettre toutes les variables à leurs valeurs initiales
    totalWalletValue = 0;
    walletValue = 0;
    rmmValue = 0;
    rwaHoldingsValue = 0;
    rentedUnits = 0;
    totalUnits = 0;
    totalTokens = 0;
    walletTokensSums = 0.0;
    rmmTokensSums = 0.0;
    averageAnnualYield = 0;
    dailyRent = 0;
    weeklyRent = 0;
    monthlyRent = 0;
    yearlyRent = 0;
    totalUsdcDepositBalance = 0;
    totalUsdcBorrowBalance = 0;
    totalXdaiDepositBalance = 0;
    totalXdaiBorrowBalance = 0;

    // Réinitialiser toutes les variables relatives à RealTokens
    totalRealtTokens = 0;
    totalRealtInvestment = 0.0;
    netRealtRentYear = 0.0;
    realtInitialPrice = 0.0;
    realtActualPrice = 0.0;
    totalRealtUnits = 0;
    rentedRealtUnits = 0;
    averageRealtAnnualYield = 0.0;

    // Réinitialiser les compteurs de tokens
    walletTokenCount = 0;
    rmmTokenCount = 0;
    totalTokenCount = 0;
    duplicateTokenCount = 0;

    // Vider les listes de données
    rentData = [];
    detailedRentData = [];
    propertyData = [];
    rmmBalances = [];
    perWalletBalances = [];
    walletTokens = [];
    realTokens = [];
    tempRentData = [];
    _portfolio = [];
    _recentUpdates = [];

    // Réinitialiser la map userIdToAddresses
    userIdToAddresses.clear();

    // Notifier les observateurs que les données ont été réinitialisées
    notifyListeners();

    // Supprimer également les préférences sauvegardées si nécessaire
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Si vous voulez vider toutes les préférences

    // Vider les caches Hive
    var box = Hive.box('realTokens');
    await box.clear(); // Vider la boîte Hive utilisée pour le cache des tokens

    debugPrint('Toutes les données ont été réinitialisées.');
  }

 Future<void> fetchRmmBalances() async {
  try {
    // Totaux globaux
    double totalUsdcDepositSum = 0;
    double totalUsdcBorrowSum = 0;
    double totalXdaiDepositSum = 0;
    double totalXdaiBorrowSum = 0;
    double totalGnosisUsdcSum = 0;
    double totalGnosisXdaiSum = 0;

    // Liste pour stocker les données par wallet
    List<Map<String, dynamic>> walletDetails = [];

    String? timestamp;

    // Itérer sur chaque balance (chaque wallet)
    for (var balance in rmmBalances) {
      double usdcDeposit = balance['usdcDepositBalance'];
      double usdcBorrow = balance['usdcBorrowBalance'];
      double xdaiDeposit = balance['xdaiDepositBalance'];
      double xdaiBorrow = balance['xdaiBorrowBalance'];
      double gnosisUsdc = balance['gnosisUsdcBalance'];
      double gnosisXdai = balance['gnosisXdaiBalance'];
      timestamp = balance['timestamp']; // Dernier timestamp mis à jour

      // Mise à jour des totaux globaux
      totalUsdcDepositSum += usdcDeposit;
      totalUsdcBorrowSum += usdcBorrow;
      totalXdaiDepositSum += xdaiDeposit;
      totalXdaiBorrowSum += xdaiBorrow;
      totalGnosisUsdcSum += gnosisUsdc;
      totalGnosisXdaiSum += gnosisXdai;

      // Stocker les données propres au wallet
      walletDetails.add({
        'address': balance['address'],
        'usdcDeposit': usdcDeposit,
        'usdcBorrow': usdcBorrow,
        'xdaiDeposit': xdaiDeposit,
        'xdaiBorrow': xdaiBorrow,
        'gnosisUsdc': gnosisUsdc,
        'gnosisXdai': gnosisXdai,
        'timestamp': timestamp,
      });
    }

    // Mise à jour des variables globales avec les totaux cumulés
    totalUsdcDepositBalance = totalUsdcDepositSum;
    totalUsdcBorrowBalance = totalUsdcBorrowSum;
    totalXdaiDepositBalance = totalXdaiDepositSum;
    totalXdaiBorrowBalance = totalXdaiBorrowSum;
    gnosisUsdcBalance = totalGnosisUsdcSum;
    gnosisXdaiBalance = totalGnosisXdaiSum;

    // Stocker les détails par wallet
    perWalletBalances = walletDetails;

    // Calcul de l'APY GLOBAL uniquement après avoir accumulé les totaux
    try {
      usdcDepositApy = await calculateAPY('usdcDeposit');
      usdcBorrowApy = await calculateAPY('usdcBorrow');
      xdaiDepositApy = await calculateAPY('xdaiDeposit');
      xdaiBorrowApy = await calculateAPY('xdaiBorrow');
    } catch (e) {
      debugPrint('Erreur lors du calcul de l\'APY global: $e');
    }

    // Debug : Afficher les totaux globaux et APY
    debugPrint(
        'Totaux globaux: USDC Deposit: $totalUsdcDepositSum, USDC Borrow: $totalUsdcBorrowSum, '
        'XDAI Deposit: $totalXdaiDepositSum, XDAI Borrow: $totalXdaiBorrowSum, '
        'Gnosis USDC: $totalGnosisUsdcSum, Gnosis XDAI: $totalGnosisXdaiSum');

    debugPrint('APY Global: USDC Deposit: $usdcDepositApy, USDC Borrow: $usdcBorrowApy, '
        'XDAI Deposit: $xdaiDepositApy, XDAI Borrow: $xdaiBorrowApy');

    notifyListeners(); // Notifier l'interface que les données ont été mises à jour

    // Archivage global si une heure s'est écoulée depuis le dernier archivage
    if (lastArchiveTime == null || DateTime.now().difference(lastArchiveTime!).inMinutes >= 5) {
      if (timestamp != null) {
        _archiveManager.archiveBalance('usdcDeposit', totalUsdcDepositSum, timestamp);
        _archiveManager.archiveBalance('usdcBorrow', totalUsdcBorrowSum, timestamp);
        _archiveManager.archiveBalance('xdaiDeposit', totalXdaiDepositSum, timestamp);
        _archiveManager.archiveBalance('xdaiBorrow', totalXdaiBorrowSum, timestamp);
        lastArchiveTime = DateTime.now();
        debugPrint("✅ Archivage des balances effectué");
      }
    } else {
      final timeUntilNextArchive = Duration(minutes: 5) - DateTime.now().difference(lastArchiveTime!);
      final minutesRemaining = timeUntilNextArchive.inMinutes;
      final secondsRemaining = timeUntilNextArchive.inSeconds % 60;
      debugPrint("⏳ Prochain archivage des balances dans ${minutesRemaining}m ${secondsRemaining}s");
    }
  } catch (e) {
    debugPrint('Erreur lors de la récupération des balances RMM: $e');
  }
}

  Future<double> calculateAPY(String tokenType) async {
    // Récupérer l'historique des balances
    List<BalanceRecord> history = await _archiveManager.getBalanceHistory(tokenType);

    // Vérifier s'il y a au moins deux enregistrements pour calculer l'APY
    if (history.length < 2) {
      debugPrint("Not enough data to calculate APY.");
      return 0.0; // Retourner 0.0 au lieu de lever une exception
    }

    try {
      // Utiliser la nouvelle méthode de calcul d'APY plus réactive
      double averageAPYForLastPairs = apyManager.calculateSmartAPY(history);

      // Vérifier si le résultat est NaN
      if (averageAPYForLastPairs.isNaN) {
        debugPrint("APY calculation resulted in NaN value for $tokenType.");
        return 0.0;
      }

      // Si aucune paire valide n'est trouvée, retourner 0
      if (averageAPYForLastPairs == 0) {
        debugPrint("No valid pairs found for APY calculation.");
        return 0.0;
      }

      // Calculer l'APY moyen global sur toutes les paires en utilisant la méthode exponentielle
      double globalApy = apyManager.calculateExponentialMovingAverageAPY(history);
      
      // Vérifier si le résultat global est NaN
      if (!globalApy.isNaN) {
        apyAverage = globalApy;
      }

      return averageAPYForLastPairs;
    } catch (e) {
      debugPrint("Error calculating APY for $tokenType: $e");
      return 0.0;
    }
  }

  double getTotalRentReceived() {
    return rentData.fold(
        0.0,
        (total, rentEntry) =>
            total +
            (rentEntry['rent'] is String
                ? double.parse(rentEntry['rent'])
                : rentEntry['rent']));
  }

  double getRentDetailsForToken(String token) {
    double totalRent = 0.0;

    // Parcourir chaque entrée de la liste detailedRentData
    for (var entry in detailedRentData) {
      // Vérifie si l'entrée contient une liste de 'rents'
      if (entry.containsKey('rents') && entry['rents'] is List) {
        List rents = entry['rents'];

        // Parcourir chaque élément de la liste des loyers
        for (var rentEntry in rents) {
          if (rentEntry['token'] != null &&
              rentEntry['token'].toLowerCase() == token.toLowerCase()) {
            // Ajoute le rent à totalRent si le token correspond
            totalRent += (rentEntry['rent'] ?? 0.0).toDouble();
          }
        }
      }
    }

    return totalRent;
  }

  // Méthode pour charger les valeurs définies manuellement depuis Hive
  Future<void> loadCustomInitPrices() async {
    final savedData = customInitPricesBox.get('customInitPrices') as String?;

    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      customInitPrices =
          decodedMap.map((key, value) => MapEntry(key, value as double));
    }
    notifyListeners();
  }

  // Méthode pour sauvegarder les valeurs manuelles dans Hive
  Future<void> saveCustomInitPrices() async {
    final encodedData = jsonEncode(customInitPrices);
    await customInitPricesBox.put('customInitPrices', encodedData);
  }

  // Méthode pour définir une valeur initPrice personnalisée
  void setCustomInitPrice(String tokenUuid, double initPrice) {
    customInitPrices[tokenUuid] = initPrice;
    //debugPrint("token: $tokenUuid et prix: $initPrice");
    saveCustomInitPrices(); // Sauvegarder après modification
    notifyListeners();
  }

  void removeCustomInitPrice(String tokenUuid) {
    customInitPrices.remove(tokenUuid);
    saveCustomInitPrices(); // Sauvegarde les changements dans Hive
    notifyListeners();
  }

  Future<void> fetchAndStorePropertiesForSale() async {
    try {
      if (propertiesForSaleFetched.isNotEmpty) {
        propertiesForSale = propertiesForSaleFetched.map((property) {
          // Chercher le RealToken correspondant à partir de realTokens en comparant `title` et `fullName`
          final matchingToken = allTokens.firstWhere(
            (token) =>
                property['title'] != null &&
                token['shortName'] != null &&
                property['title']
                    .toString()
                    .contains(token['shortName'].toString()),
            orElse: () => <String, dynamic>{},
          );

          return {
            'title': property['title'],
            'fullName': matchingToken['fullName'],
            'shortName': matchingToken['shortName'],
            'marketplaceLink': matchingToken['marketplaceLink'],
            'country': matchingToken['country'],
            'city': matchingToken['city'],
            'tokenPrice': matchingToken['tokenPrice'],
            'annualPercentageYield': matchingToken['annualPercentageYield'],
            'totalTokens': matchingToken['totalTokens'],
            'rentStartDate': matchingToken['rentStartDate'],
            'status': property['status'],
            'productId': property['product_id'],
            'stock': property['stock'],
            'maxPurchase': property['max_purchase'],
            'imageLink': matchingToken['imageLink'],
          };
        }).toList();
      } else {
        debugPrint("⚠️ DataManager: Aucune propriété en vente trouvée");
      }
    } catch (e) {
      debugPrint(
          "DataManager: Erreur lors de la récupération des propriétés en vente: $e");
    }

    // Notifie les widgets que les données ont changé
    notifyListeners();
  }

  Future<void> fetchAndStoreYamMarketData() async {
    var box = Hive.box('realTokens');

    // Récupération des données en cache, si disponibles
    final cachedData = box.get('cachedYamMarket');
    List<Map<String, dynamic>> yamMarketData = [];

    if (cachedData != null) {
      yamMarketFetched =
          List<Map<String, dynamic>>.from(json.decode(cachedData));
      debugPrint(
          "✅ Données YamMarket en cache trouvées : ${yamMarketFetched.length} offres chargées.");
    } else {
      debugPrint("⚠️ Aucune donnée YamMarket en cache.");
    }

    double totalTokenValue = 0.0;
    int totalOffers = 0;
    double totalTokenAmount = 0.0;

    List<Map<String, dynamic>> allOffersList = [];

    if (yamMarketFetched.isNotEmpty) {
      //debugPrint("🔄 Début du traitement des ${yamMarketFetched.length} offres...");

      for (var offer in yamMarketFetched) {
        // debugPrint("🔍 Traitement de l'offre ID: ${offer['id_offer']} - Token Sell: ${offer['token_to_sell']} - Token Buy: ${offer['token_to_buy']}");

        // Vérifier si le token de l'offre correspond à un token de allTokens
        final matchingToken = allTokens.firstWhere(
            (token) =>
                token['uuid'] == offer['token_to_sell']?.toLowerCase() ||
                token['uuid'] == offer['token_to_buy']?.toLowerCase(),
            orElse: () {
          // debugPrint("⚠️ Aucun token correspondant trouvé pour l'offre ${offer['id_offer']}. UUIDs: sell=${offer['token_to_sell']}, buy=${offer['token_to_buy']}");
          return <String, dynamic>{};
        });

        // Vérifier si un token a été trouvé
        if (matchingToken.isEmpty) {
          //debugPrint("🚨 Offre ignorée car aucun token correspondant trouvé.");
          continue;
        }

        // Récupérer et convertir les valeurs nécessaires
        double tokenAmount = (offer['token_amount'] ?? 0.0).toDouble();
        double tokenValue = (offer['token_value'] ?? 0.0).toDouble();
        totalTokenValue += tokenValue;
        totalTokenAmount += tokenAmount;
        totalOffers += 1;

        // Ajouter l'offre traitée à la liste
        allOffersList.add({
          'id': offer['id'],
          'shortName': matchingToken['shortName'] ?? 'Unknown',
          'country': matchingToken['country'] ?? 'Unknown',
          'city': matchingToken['city'] ?? 'Unknown',
          'rentStartDate': matchingToken['rentStartDate'],
          'tokenToPay': offer['token_to_pay'],
          'imageLink': matchingToken['imageLink'],
          'holderAddress': offer['holder_address'],
          'token_amount': offer['token_amount'],
          'token_price': matchingToken['tokenPrice'],
          'annualPercentageYield': matchingToken['annualPercentageYield'],
          'tokenDigit': offer['token_digit'],
          'creationDate': offer['creation_date'],
          'token_to_pay': offer['token_to_pay'],
          'token_to_sell': offer['token_to_sell'],
          'token_to_buy': offer['token_to_buy'],
          'id_offer': offer['id_offer'],
          'tokenToPayDigit': offer['token_to_pay_digit'],
          'token_value': offer['token_value'],
          'blockNumber': offer['block_number'],
          'supp': offer['supp'],
          'timsync': offer['timsync'],
          'buyHolderAddress': offer['buy_holder_address'],
        });

        //debugPrint("✅ Offre ajoutée : ${offer['id_offer']} - Token: ${matchingToken['shortName']} - Montant: $tokenAmount - Valeur: $tokenValue");
      }

      yamMarket = allOffersList;
      //debugPrint("✅ Mise à jour de YamMarket terminée : $_totalOffers offres disponibles.");

      notifyListeners();
    } else {
      debugPrint("⚠️ Aucune donnée YamMarket disponible après traitement.");
    }
  }

  void fetchYamHistory() {
    var box = Hive.box('realTokens');
    final yamHistoryJson = box.get('yamHistory');

    if (yamHistoryJson == null) {
      debugPrint(
          "❌ fetchYamHistory -> Aucune donnée Yam History trouvée dans Hive.");
      return;
    }

    List<dynamic> yamHistoryData = json.decode(yamHistoryJson);

    // Regroupement par token
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in yamHistoryData) {
      String token = entry['token'];
      if (grouped[token] == null) {
        grouped[token] = [];
      }
      grouped[token]!.add(Map<String, dynamic>.from(entry));
    }

    List<Map<String, dynamic>> tokenStatistics = [];
    grouped.forEach((token, entries) {
      double totalVolume = 0;
      double totalQuantity = 0;
      for (var day in entries) {
        totalVolume += (day['volume'] as num).toDouble();
        totalQuantity += (day['quantity'] as num).toDouble();
      }
      double averageValue = totalQuantity > 0 ? totalVolume / totalQuantity : 0;
      tokenStatistics.add({
        'id': token,
        'totalVolume': totalVolume,
        'averageValue': averageValue,
      });
    });

    debugPrint(
        "fetchYamHistory -> Mise à jour des statistiques des tokens Yam.");
    yamHistory = tokenStatistics;
    notifyListeners();
  }

  // Méthode centralisée pour calculer et archiver les valeurs d'APY
  void calculateApyValues() {
    // Calculer l'APY global avec la méthode centralisée
    netGlobalApy = calculateGlobalApy();
    
    // Logger la valeur calculée
    debugPrint("✅ APY global calculé: $netGlobalApy%");
    
    // Calculer l'APY moyen pondéré par les montants
    double totalDepositAmount = totalUsdcDepositBalance + totalXdaiDepositBalance;
    double totalBorrowAmount = totalUsdcBorrowBalance + totalXdaiBorrowBalance;
    
    // APY pondéré pour les dépôts (gains) - toujours positif
    double weightedDepositApy = 0.0;
    if (totalDepositAmount > 0) {
      weightedDepositApy = (usdcDepositApy * totalUsdcDepositBalance + 
                           xdaiDepositApy * totalXdaiDepositBalance) / 
                          totalDepositAmount;
    }
    
    // APY pondéré pour les emprunts (coûts) - toujours positif
    double weightedBorrowApy = 0.0;
    if (totalBorrowAmount > 0) {
      weightedBorrowApy = (usdcBorrowApy * totalUsdcBorrowBalance + 
                          xdaiBorrowApy * totalXdaiBorrowBalance) / 
                         totalBorrowAmount;
    }
    
    // Calcul du total des intérêts gagnés et payés
    double depositInterest = weightedDepositApy * totalDepositAmount;
    double borrowInterest = weightedBorrowApy * totalBorrowAmount;
    
    // Intérêt net (positif si les coûts d'emprunt sont supérieurs aux gains de dépôt,
    // négatif si les gains de dépôt sont supérieurs aux coûts d'emprunt)
    double netInterest = borrowInterest - depositInterest;
    
    // Total des montants impliqués
    double totalAmount = totalDepositAmount + totalBorrowAmount;
    
    // Calculer l'APY moyen pondéré final
    if (totalAmount > 0) {
      apyAverage = netInterest / totalAmount;
    } else {
      apyAverage = 0.0;
    }
    
    // Vérifier si le résultat est NaN
    if (apyAverage.isNaN) {
      debugPrint("⚠️ L'APY moyen calculé est NaN, retourne 0.0");
      apyAverage = 0.0;
    }
    
    debugPrint("✅ APY moyen pondéré calculé: $apyAverage% (dépôts: $weightedDepositApy% × $totalDepositAmount, emprunts: $weightedBorrowApy% × $totalBorrowAmount)");
    debugPrint("   Intérêts de dépôt: $depositInterest, Intérêts d'emprunt: $borrowInterest, Net: $netInterest");
    
    // Archiver l'APY global calculé
    archiveApyValue(netGlobalApy, apyAverage);

    // Calculer le ROI global
    roiGlobalValue = apyManager.calculateRoi(
      currentValue: totalWalletValue,
      initialInvestment: apyManager.initialInvestment,
    );

    // Calculer l'APY pour chaque wallet individuel
    Map<String, double> walletApys = apyManager.calculateWalletApys(walletStats);
    
    // Mettre à jour les statistiques de wallet avec les APY calculés
    for (var wallet in walletStats) {
      final String address = wallet['address'] as String;
      wallet['apy'] = walletApys[address] ?? 0.0;
    }
  }

  // Dans la méthode qui met à jour les données de wallet/portfolio
  // Par exemple, dans la méthode fetchData ou processData
  void processData() async {
    // ... existing code ...
    
    // Calculer les statistiques
    // ... existing code ...
    
    // Calculer les valeurs d'APY et ROI
    calculateApyValues();
    
    // Notifier les écouteurs
    notifyListeners();
  }

  /// Ajuste la réactivité du calcul d'APY
  /// 
  /// [reactivityLevel] : niveau de réactivité entre 0 (très lisse) et 1 (très réactif)
  /// [historyDays] : nombre de jours d'historique à prendre en compte (optionnel)
  void adjustApyReactivity(double reactivityLevel, {int? historyDays}) {
    if (reactivityLevel < 0 || reactivityLevel > 1) {
      debugPrint("⚠️ Niveau de réactivité invalide: $reactivityLevel. Doit être entre 0 et 1.");
      return;
    }

    // Calculer l'alpha pour l'EMA en fonction du niveau de réactivité
    // Une réactivité de 0 donne un alpha de 0.05 (très lisse)
    // Une réactivité de 1 donne un alpha de 0.8 (très réactif)
    double alpha = 0.05 + (reactivityLevel * 0.75);
    
    // Déterminer le nombre de jours d'historique
    // Si non spécifié, ajuster en fonction de la réactivité
    // Plus la réactivité est élevée, moins on a besoin d'historique
    // Plage de 1 à 20 jours avec des valeurs discrètes
    int days = historyDays ?? (20 - (reactivityLevel * 19).round()).clamp(1, 20);
    
    debugPrint("🔄 Ajustement de la réactivité APY: alpha=$alpha, jours=$days");
    
    // Appliquer les nouveaux paramètres à l'ApyManager
    apyManager.setApyCalculationParameters(
      newEmaAlpha: alpha,
      newMaxHistoryDays: days,
    );
    
    // Recalculer l'APY avec les nouveaux paramètres
    if (balanceHistory.length >= 2) {
      try {
        // Utiliser calculateApyValues au lieu de recalculer directement ici
        calculateApyValues();
        debugPrint("✅ APY recalculé avec les nouveaux paramètres: $netGlobalApy%");
      } catch (e) {
        debugPrint("❌ Erreur lors du recalcul de l'APY: $e");
      }
    } else {
      debugPrint("⚠️ Historique insuffisant pour recalculer l'APY: ${balanceHistory.length} enregistrement(s) disponible(s) (minimum requis: 2)");
    }
    
    // Notifier les widgets pour qu'ils se mettent à jour
    notifyListeners();
  }

  // Méthode appelée par l'ArchiveManager lorsqu'une nouvelle valeur de portefeuille est archivée
  void updateBalanceHistory(List<BalanceRecord> newBalanceHistory) {
    balanceHistory = newBalanceHistory;
    walletBalanceHistory = newBalanceHistory; // Mettre à jour walletBalanceHistory aussi
    
    // Recalculer l'APY après mise à jour de l'historique
    if (balanceHistory.length >= 2) {
      try {
        // Appeler calculateApyValues pour mettre à jour netGlobalApy
        calculateApyValues();
        debugPrint("✅ APY recalculé après mise à jour de l'historique: $netGlobalApy%");
      } catch (e) {
        debugPrint("❌ Erreur lors du recalcul de l'APY: $e");
      }
    } else {
      debugPrint("⚠️ Historique insuffisant après mise à jour: ${balanceHistory.length} enregistrement(s) disponible(s) (minimum requis: 2)");
    }
    
    // Sauvegarder les modifications dans Hive
    saveWalletBalanceHistory();
    
    notifyListeners();
  }

  /// Méthode centralisée pour archiver une valeur d'APY
  /// 
  /// Cette méthode gère à la fois:
  /// 1. L'ajout à l'historique en mémoire
  /// 2. La persistance dans Hive via l'ArchiveManager
  /// 3. La notification des listeners
  /// 
  /// [netApy] : Valeur nette de l'APY à archiver
  /// [grossApy] : Valeur brute de l'APY à archiver
  void archiveApyValue(double netApy, double grossApy) {
    // Vérifier si nous avons moins de 20 éléments dans l'historique
    if (apyHistory.length < 20) {
      // Si moins de 20 éléments, vérifier si 15 minutes se sont écoulées depuis le dernier archivage
      if (apyHistory.isNotEmpty) {
        final lastRecord = apyHistory.last;
        final timeSinceLastRecord = DateTime.now().difference(lastRecord.timestamp);
        if (timeSinceLastRecord.inMinutes < 15) {
          debugPrint('⏳ Archivage APY ignoré: moins de 15 minutes depuis le dernier enregistrement (${timeSinceLastRecord.inMinutes}m)');
          return;
        }
      }
    } else {
      // Si 20 éléments ou plus, vérifier si 1 heure s'est écoulée depuis le dernier archivage
      if (apyHistory.isNotEmpty) {
        final lastRecord = apyHistory.last;
        final timeSinceLastRecord = DateTime.now().difference(lastRecord.timestamp);
        if (timeSinceLastRecord.inHours < 1) {
          debugPrint('⏳ Archivage APY ignoré: moins d\'une heure depuis le dernier enregistrement (${timeSinceLastRecord.inMinutes}m)');
          return;
        }
      }
    }

    // 1. Ajouter à la liste en mémoire
    apyHistory.add(ApyRecord(
      netApy: netApy, 
      grossApy: grossApy, 
      timestamp: DateTime.now())
    );
    
    // 2. Déléguer à l'ArchiveManager pour la persistance dans Hive
    _archiveManager.archiveApyValue(netApy, grossApy);
    
    // 3. Notifier les widgets pour mise à jour de l'UI
    notifyListeners();
  }

  // Valeurs d'APY calculées à partir de l'historique
  double apyAverageFromHistory = 0.0;
  double usdcDepositApyFromHistory = 0.0;
  double usdcBorrowApyFromHistory = 0.0;
  double xdaiDepositApyFromHistory = 0.0;
  double xdaiBorrowApyFromHistory = 0.0;

  // Valeurs d'APY basées sur les taux fixes
  double apyAverageFromRates = 0.0;
  double usdcDepositApyFromRates = 0.0;
  double usdcBorrowApyFromRates = 0.0;
  double xdaiDepositApyFromRates = 0.0;
  double xdaiBorrowApyFromRates = 0.0;

  Future<void> updateApyValues() async {
    try {
      // Calculer l'APY à partir de l'historique pour chaque type de balance
      usdcDepositApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('usdcDeposit'));
      usdcBorrowApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('usdcBorrow'));
      xdaiDepositApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('xdaiDeposit'));
      xdaiBorrowApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('xdaiBorrow'));

      // Vérifier et corriger les valeurs NaN
      if (usdcDepositApy.isNaN) usdcDepositApy = 0.0;
      if (usdcBorrowApy.isNaN) usdcBorrowApy = 0.0;
      if (xdaiDepositApy.isNaN) xdaiDepositApy = 0.0;
      if (xdaiBorrowApy.isNaN) xdaiBorrowApy = 0.0;

      // Le calcul complet de l'APY moyen est maintenant fait dans calculateApyValues()
      // Nous appelons cette méthode pour mettre à jour apyAverage et netGlobalApy
      calculateApyValues();

      if (kDebugMode) {
        debugPrint('APY individuels calculés à partir de l\'historique:');
        debugPrint('USDC Deposit: $usdcDepositApy%');
        debugPrint('USDC Borrow: $usdcBorrowApy%');
        debugPrint('XDAI Deposit: $xdaiDepositApy%');
        debugPrint('XDAI Borrow: $xdaiBorrowApy%');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors de la mise à jour des valeurs APY: $e');
      }
    }
  }

  // Méthode centralisée pour calculer l'APY global avec la formule originale
  double calculateGlobalApy() {
    double result = (((averageAnnualYield * (walletValue + rmmValue)) +
            (totalUsdcDepositBalance * usdcDepositApy +
                totalXdaiDepositBalance * xdaiDepositApy) -
            (totalUsdcBorrowBalance * usdcBorrowApy +
                totalXdaiBorrowBalance * xdaiBorrowApy)) /
        (walletValue +
            rmmValue +
            totalUsdcDepositBalance +
            totalXdaiDepositBalance +
            totalUsdcBorrowBalance +
            totalXdaiBorrowBalance));
    
    // Vérifier si le résultat est NaN
    if (result.isNaN) {
      debugPrint("⚠️ L'APY global calculé est NaN, retourne 0.0");
      return 0.0;
    }
    
    return result;
  }
}