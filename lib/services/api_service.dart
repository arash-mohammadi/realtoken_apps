import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Méthode factorisée pour fetch les tokens depuis The Graph
  static Future<List<dynamic>> fetchTokensFromUrl(String subgraphId, String cacheKey, {bool forceFetch = false, bool useAlternativeKey = false}) async {
    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastFetchTime_$cacheKey');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedTokenData_$cacheKey');
        if (cachedData != null) {
          return jsonDecode(cachedData);
        }
      }
    }

    final apiUrl = Parameters.getGraphUrl(subgraphId, useAlternativeKey: useAlternativeKey);

    final query = '''
      query RealtokenQuery(\$addressList: [String]!) {
        accounts(where: { address_in: \$addressList }) {
          address
          balances(where: { amount_gt: "0" }, first: 1000, orderBy: amount, orderDirection: desc) {
            token {
              address
            }
            amount
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "query": query,
          "variables": {"addressList": evmAddresses}
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse.containsKey('errors')) {
          final errorMessage = json.encode(decodedResponse['errors']);
          if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
            debugPrint("🔄 TheGraph API limit exceeded or  not found , switching to alternative API key...");
            return await fetchTokensFromUrl(subgraphId, cacheKey, forceFetch: forceFetch, useAlternativeKey: true);
          }
          throw Exception("Erreur API: $errorMessage");
        }

        final data = decodedResponse['data']['accounts'];
        box.put('cachedTokenData_$cacheKey', json.encode(data));
        box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        box.put('lastExecutionTime_Portfolio ($cacheKey)', now.toIso8601String());
        return data;
      } else {
        throw Exception('Failed to fetch tokens from API');
      }
    } catch (e) {
      throw Exception('Échec de la récupération des tokens: $e');
    }
  }

  static Future<List<dynamic>> fetchTokensFromGnosis({bool forceFetch = false}) {
    return fetchTokensFromUrl(Parameters.gnosisSubgraphId, 'gnosis', forceFetch: forceFetch);
  }

  static Future<List<dynamic>> fetchTokensFromEtherum({bool forceFetch = false}) {
    return fetchTokensFromUrl(Parameters.etherumSubgraphId, 'etherum', forceFetch: forceFetch);
  }

  // Récupérer les tokens sur le RealToken Marketplace (RMM)
  static Future<List<dynamic>> fetchRMMTokens({bool forceFetch = false, bool useAlternativeKey = false}) async {
    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastRMMFetchTime');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedRMMData');
        if (cachedData != null) {
          return jsonDecode(cachedData);
        }
      }
    }

    List<dynamic> allBalances = [];
    final apiUrl = Parameters.getGraphUrl(Parameters.rmmSubgraphId, useAlternativeKey: useAlternativeKey);

    for (var address in evmAddresses) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "query": '''
              query RmmQuery(\$addressList: String!) {
                users(where: { id: \$addressList }) {
                  balances(
                    where: { amount_gt: 0 },
                    first: 1000,
                    orderBy: amount,
                    orderDirection: desc,
                    skip: 0
                  ) {
                    amount
                    token {
                      decimals
                      id
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
              }
            ''',
            "variables": {
              "addressList": address,
            }
          }),
        );

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(response.body);

          if (decodedResponse.containsKey('errors')) {
            final errorMessage = json.encode(decodedResponse['errors']);
            if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
              debugPrint("🔄 TheGraph API limit exceeded or  not found , switching to alternative API key...");
              return await fetchRMMTokens(forceFetch: forceFetch, useAlternativeKey: true);
            }
            throw Exception("Erreur API: $errorMessage");
          }

          if (decodedResponse['data'] != null && decodedResponse['data']['users'] != null && decodedResponse['data']['users'].isNotEmpty) {
            final data = decodedResponse['data']['users'][0]['balances'];
            allBalances.addAll(data);
          }
        } else {
          throw Exception('Failed to fetch RMM tokens for address: $address');
        }
      } catch (e) {
        throw Exception('Échec de la récupération des tokens RMM: $e');
      }
    }

    box.put('cachedRMMData', json.encode(allBalances));
    box.put('lastRMMFetchTime', now.toIso8601String());
    box.put('lastExecutionTime_RMM', now.toIso8601String());

    return allBalances;
  }

  // Récupérer la liste complète des RealTokens depuis l'API pitswap
  static Future<List<dynamic>> fetchRealTokens({bool forceFetch = false}) async {
    debugPrint("🚀 apiService: fetchRealTokens -> Lancement de la requête");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastFetchTime');
    final lastUpdateTime = box.get('lastUpdateTime_Tokens list');
    final cachedData = box.get('cachedRealTokens');
    final DateTime now = DateTime.now();

    // Si lastFetchTime est déjà défini et que le temps minimum n'est pas atteint, on vérifie d'abord la validité du cache
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchRealTokens -> Requête annulée, temps minimum pas atteint");
          return [];
        }
      }
    }

    // Vérification de la dernière mise à jour sur le serveur
    final lastUpdateResponse = await http.get(Uri.parse('${Parameters.realTokensUrl}/last_get_realTokens_mobileapps'));

    if (lastUpdateResponse.statusCode == 200) {
      final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
      final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);

      // Comparaison entre la date de la dernière mise à jour et la date stockée localement
      if (!forceFetch) {
        if (lastUpdateTime != null && cachedData != null) {
          final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
          if (lastExecutionDate.isAtSameMomentAs(lastUpdateDate)) {
            debugPrint("🛑 apiService: fetchRealTokens -> Requête annulée, données déjà à jour");
            return [];
          }
        }
      }
      // Si les dates sont différentes ou pas de cache, on continue avec la requête réseau
      final response = await http.get(Uri.parse('${Parameters.realTokensUrl}/realTokens_mobileapps'));

      if (response.statusCode == 200) {
        debugPrint("✅ apiService: fetchRealTokens -> Requête lancée avec succès");

        final data = json.decode(response.body);
        box.put('cachedRealTokens', json.encode(data));
        box.put('lastFetchTime', now.toIso8601String());
        // Enregistrer la nouvelle date de mise à jour renvoyée par l'API
        box.put('lastUpdateTime_RealTokens', lastUpdateDateString);
        box.put('lastExecutionTime_RealTokens', now.toIso8601String());

        return data;
      } else {
        throw Exception('apiService: fetchRealTokens -> Failed to fetch RealTokens');
      }
    } else {
      throw Exception('apiService: fetchRealTokens -> Failed to fetch last update date');
    }
  }

  // Récupérer la liste complète des RealTokens depuis l'API pitswap
  static Future<List<dynamic>> fetchYamMarket({bool forceFetch = false}) async {
    //debugPrint("🚀 apiService: fetchYamMarket -> Lancement de la requête");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('yamlastFetchTime');
    final lastUpdateTime = box.get('lastUpdateTime_YamMarket');
    final cachedData = box.get('cachedYamMarket');
    final DateTime now = DateTime.now();

    // Si lastFetchTime est déjà défini et que le temps minimum n'est pas atteint, on vérifie d'abord la validité du cache
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        if (cachedData != null) {
          //debugPrint("🛑 apiService: fetchYamMarket -> Requête annulée, temps minimum pas atteint");
          return [];
        }
      }
    }

    // Vérification de la dernière mise à jour sur le serveur
    final lastUpdateResponse = await http.get(Uri.parse('${Parameters.realTokensUrl}/last_update_yam_offers_mobileapps'));

    if (lastUpdateResponse.statusCode == 200) {
      final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
      final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);

      // Comparaison entre la date de la dernière mise à jour et la date stockée localement
      if (lastUpdateTime != null && cachedData != null) {
        final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
        if (lastExecutionDate.isAtSameMomentAs(lastUpdateDate)) {
          //debugPrint("🛑 apiService: fetchYamMarket -> Requête annulée, données déjà à jour");
          return [];
        }
      }

      // Si les dates sont différentes ou pas de cache, on continue avec la requête réseau
      final response = await http.get(Uri.parse('${Parameters.realTokensUrl}/get_yam_offers_mobileapps'));

      if (response.statusCode == 200) {
        //debugPrint("✅ apiService: fetchYamMarket -> Requête lancée avec succès");

        final data = json.decode(response.body);
        box.put('cachedYamMarket', json.encode(data));
        box.put('yamlastFetchTime', now.toIso8601String());
        // Enregistrer la nouvelle date de mise à jour renvoyée par l'API
        box.put('lastUpdateTime_YamMarket', lastUpdateDateString);
        box.put('lastExecutionTime_YAM Market', now.toIso8601String());

        return data;
      } else {
        throw Exception('apiService: fetchYamMarket -> Failed to fetch RealTokens');
      }
    } else {
      throw Exception('apiService: fetchYamMarket -> Failed to fetch last update date');
    }
  }
  // Récupérer les données de loyer pour chaque wallet et les fusionner avec cache

  static Future<List<Map<String, dynamic>>> fetchRentData({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wallets = prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      return []; // Ne pas exécuter si la liste des wallets est vide
    }

    var box = Hive.box('realTokens');
    final DateTime now = DateTime.now();

    // Vérifier si une réponse 429 a été reçue récemment
    final last429Time = box.get('lastRent429Time');
    if (last429Time != null) {
      final DateTime last429 = DateTime.parse(last429Time);
      // Si on est dans la période d'attente de 3 minutes
      if (now.difference(last429) < Duration(minutes: 3)) {
        debugPrint('⚠️ apiService: ehpst -> 429 reçu, attente avant nouvelle requête.');
        return []; // Si pas de cache, on retourne une liste vide
      }
    }

    // Vérification du cache
    final lastFetchTime = box.get('lastRentFetchTime');
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedRentData');
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchRentData -> Requete annulée, temps minimum pas atteint");
          return [];
        }
      }
    }

    // Sinon, on effectue la requête API
    List<Map<String, dynamic>> mergedRentData = [];

    for (String wallet in wallets) {
      final url = '${Parameters.rentTrackerUrl}/rent_holder/$wallet';
      final response = await http.get(Uri.parse(url));

      // Si on reçoit un code 429, sauvegarder l'heure et arrêter
      if (response.statusCode == 429) {
        debugPrint('⚠️ apiService: ehpst -> 429 Too Many Requests');
        // Sauvegarder le temps où la réponse 429 a été reçue
        box.put('lastRent429Time', now.toIso8601String());
        break; // Sortir de la boucle et arrêter la méthode
      }

      if (response.statusCode == 200) {
        debugPrint("🚀 apiService: ehpst -> RentTracker, requete lancée");

        List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(response.body));
        for (var rentEntry in rentData) {
          final existingEntry = mergedRentData.firstWhere(
            (entry) => entry['date'] == rentEntry['date'],
            orElse: () => <String, dynamic>{},
          );

          if (existingEntry.isNotEmpty) {
            existingEntry['rent'] = (existingEntry['rent'] ?? 0) + (rentEntry['rent'] ?? 0);
          } else {
            mergedRentData.add({
              'date': rentEntry['date'],
              'rent': rentEntry['rent'] ?? 0,
            });
          }
        }
      } else {
        throw Exception('ehpst -> RentTracker, Failed to load rent data for wallet: $wallet');
      }
    }

    mergedRentData.sort((a, b) => a['date'].compareTo(b['date']));

    // Mise à jour du cache après la récupération des données
    box.put('lastRentFetchTime', now.toIso8601String());
    box.put('lastExecutionTime_Rents', now.toIso8601String());

    return mergedRentData;
  }

  static Future<List<Map<String, dynamic>>> fetchWhitelistTokens({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wallets = prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      return []; // Pas d'exécution si aucun wallet n'est renseigné
    }

    var box = Hive.box('realTokens');
    final DateTime now = DateTime.now();

    // Vérification du cache global pour la whitelist
    final lastFetchTime = box.get('lastWhitelistFetchTime');
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedWhitelistData');
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchWhitelistTokens -> Requête annulée, temps minimum pas atteint");
          return List<Map<String, dynamic>>.from(json.decode(cachedData));
        }
      }
    }

    List<Map<String, dynamic>> mergedWhitelistTokens = [];

    // Parcourir chaque wallet pour récupérer ses tokens whitelistés
    for (String wallet in wallets) {
      final url = '${Parameters.rentTrackerUrl}/whitelist2/$wallet';
      final response = await http.get(Uri.parse(url));

      // En cas de code 429, on peut mettre en cache l'heure et interrompre la boucle
      if (response.statusCode == 429) {
        debugPrint('⚠️ apiService: fetchWhitelistTokens -> 429 Too Many Requests pour wallet: $wallet');
        box.put('lastWhitelistFetchTime', now.toIso8601String());
        break;
      }

      if (response.statusCode == 200) {
        debugPrint("🚀 apiService: fetchWhitelistTokens -> Requête réussie pour wallet: $wallet");
        List<Map<String, dynamic>> whitelistData = List<Map<String, dynamic>>.from(json.decode(response.body));
        mergedWhitelistTokens.addAll(whitelistData);
      } else {
        throw Exception('Erreur: Impossible de récupérer les tokens whitelistés pour wallet: $wallet (code ${response.statusCode})');
      }
    }

    // Optionnel : vous pouvez trier ou filtrer mergedWhitelistTokens si nécessaire
    // Mise à jour du cache après la récupération des données
    box.put('cachedWhitelistData', json.encode(mergedWhitelistTokens));
    box.put('lastWhitelistFetchTime', now.toIso8601String());

    return mergedWhitelistTokens;
  }

  static Future<Map<String, dynamic>> fetchCurrencies() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier si les devises sont déjà en cache
    final cachedData = prefs.getString('cachedCurrencies');
    final cacheTime = prefs.getInt('cachedCurrenciesTime');

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const cacheDuration = 3600000; // 1 heure en millisecondes

    // Si les données sont en cache et n'ont pas expiré
    if (cachedData != null && cacheTime != null && (currentTime - cacheTime) < cacheDuration) {
      // Retourner les données du cache
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }

    // Sinon, récupérer les devises depuis l'API
    final response = await http.get(Uri.parse(Parameters.coingeckoUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currencies = data['market_data']['current_price'] as Map<String, dynamic>;

      // Stocker les devises en cache
      await prefs.setString('cachedCurrencies', jsonEncode(currencies));
      await prefs.setInt('cachedCurrenciesTime', currentTime); // Stocker l'heure actuelle
      return currencies;
    } else {
      throw Exception('Failed to load currencies');
    }
  }

  // Récupérer le userId associé à une adresse Ethereum
  static Future<String?> fetchUserIdFromAddress(String address, {bool useAlternativeKey = false}) async {
  final apiUrl = Parameters.getGraphUrl(Parameters.gnosisSubgraphId, useAlternativeKey: useAlternativeKey);

  final query = '''
  {
    account(id: "$address") {
      userIds {
        userId
      }
    }
  }
  ''';


  debugPrint("Envoi de la requête vers $apiUrl avec l'adresse $address");

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"query": query}),
    );
    
    debugPrint("Réponse reçue: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint("Données reçues: $data");

      if (data.containsKey('errors')) {
        final errorMessage = json.encode(data['errors']);
        debugPrint("Erreur dans la réponse de l'API: $errorMessage");

        if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
          debugPrint("🔄 TheGraph API limit exceeded or not found, switching to alternative API key...");
          return await fetchUserIdFromAddress(address, useAlternativeKey: true);
        }
        throw Exception("Erreur API: $errorMessage");
      }

      final userIds = data['data']['account']['userIds'];
      if (userIds != null && userIds.isNotEmpty) {
        final userId = userIds.first['userId'];
        debugPrint("UserId trouvé: $userId");
        return userId;
      } else {
        debugPrint("Aucun userId trouvé pour l'adresse $address");
      }
    } else {
      debugPrint("Statut HTTP inattendu: ${response.statusCode}");
    }
    return null;
  } catch (e) {
    debugPrint("Exception attrapée dans fetchUserIdFromAddress: $e");
    throw Exception('Échec de la récupération de userId: $e');
  }
}

  // Récupérer les adresses associées à un userId
  static Future<List<String>> fetchAddressesForUserId(String userId, {bool useAlternativeKey = false}) async {
    final apiUrl = Parameters.getGraphUrl(Parameters.gnosisSubgraphId, useAlternativeKey: useAlternativeKey);

    final query = '''
    {
      accounts(where: { userIds: ["0x296033cb983747b68911244ec1a3f01d7708851b-$userId"] }) {
        address
      }
    }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"query": query}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('errors')) {
          final errorMessage = json.encode(data['errors']);
          if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
            debugPrint("🔄 TheGraph API limit exceeded or  not found , switching to alternative API key...");
            return await fetchAddressesForUserId(userId, useAlternativeKey: true);
          }
          throw Exception("Erreur API: $errorMessage");
        }

        final accounts = data['data']['accounts'];
        if (accounts != null && accounts.isNotEmpty) {
          return List<String>.from(accounts.map((account) => account['address']));
        }
      }
      return [];
    } catch (e) {
      throw Exception('Échec de la récupération des adresses pour userId: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRmmBalances({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ apiService: fetchRMMBalances -> wallet non renseigné");
      return [];
    }

    // Contrats pour USDC & XDAI (dépôt et emprunt)
    const String usdcDepositContract = '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1';
    const String usdcBorrowContract = '0x69c731ae5f5356a779f44c355abb685d84e5e9e6';
    const String xdaiDepositContract = '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b';
    const String xdaiBorrowContract = '0x9908801df7902675c3fedd6fea0294d18d5d5d34';

    // Contrats pour USDC & XDAI sur Gnosis (remplacer les adresses par celles du réseau Gnosis)
    const String gnosisUsdcContract = '0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83';

    List<Map<String, dynamic>> allBalances = [];

    for (var address in evmAddresses) {
      // Requêtes pour USDC et XDAI sur le réseau d'origine
      final usdcDepositResponse = await _fetchBalance(usdcDepositContract, address, forceFetch: forceFetch);
      final usdcBorrowResponse = await _fetchBalance(usdcBorrowContract, address, forceFetch: forceFetch);
      final xdaiDepositResponse = await _fetchBalance(xdaiDepositContract, address, forceFetch: forceFetch);
      final xdaiBorrowResponse = await _fetchBalance(xdaiBorrowContract, address, forceFetch: forceFetch);
      // Requêtes pour USDC et XDAI sur Gnosis
      final gnosisUsdcResponse = await _fetchBalance(gnosisUsdcContract, address, forceFetch: forceFetch);
      final gnosisXdaiResponse = await _fetchNativeBalance(address, forceFetch: forceFetch);

      // Vérification que toutes les requêtes ont retourné une valeur
      if (usdcDepositResponse != null &&
          usdcBorrowResponse != null &&
          xdaiDepositResponse != null &&
          xdaiBorrowResponse != null &&
          gnosisUsdcResponse != null &&
          gnosisXdaiResponse != null) {
        final timestamp = DateTime.now().toIso8601String();

        // Conversion des balances en double (USDC : 6 décimales, XDAI : 18 décimales)
        double usdcDepositBalance = (usdcDepositResponse / BigInt.from(1e6));
        double usdcBorrowBalance = (usdcBorrowResponse / BigInt.from(1e6));
        double xdaiDepositBalance = (xdaiDepositResponse / BigInt.from(1e18));
        double xdaiBorrowBalance = (xdaiBorrowResponse / BigInt.from(1e18));
        double gnosisUsdcBalance = (gnosisUsdcResponse / BigInt.from(1e6));
        double gnosisXdaiBalance = (gnosisXdaiResponse / BigInt.from(1e18));

        // Ajout des données dans la liste
        allBalances.add({
          'address': address,
          'usdcDepositBalance': usdcDepositBalance,
          'usdcBorrowBalance': usdcBorrowBalance,
          'xdaiDepositBalance': xdaiDepositBalance,
          'xdaiBorrowBalance': xdaiBorrowBalance,
          'gnosisUsdcBalance': gnosisUsdcBalance,
          'gnosisXdaiBalance': gnosisXdaiBalance,
          'timestamp': timestamp,
        });
      } else {
        throw Exception('Failed to fetch balances for address: $address');
      }
    }
    return allBalances;
  }

  /// Fonction pour récupérer le solde d'un token ERC20 (via eth_call)
  static Future<BigInt?> _fetchBalance(String contract, String address, {bool forceFetch = false}) async {
    final String cacheKey = 'cachedBalance_${contract}_$address';
    final box = await Hive.openBox('balanceCache'); // Remplacez par le système de stockage persistant que vous utilisez
    final now = DateTime.now();

    // Récupérer l'heure de la dernière requête dans le cache
    final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

    // Vérifier si on doit utiliser le cache ou forcer une nouvelle requête
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        // Vérifier si le résultat est mis en cache
        final cachedData = box.get(cacheKey);
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchBallance -> Requete annulée, temps minimum pas atteint");
          return BigInt.tryParse(cachedData);
        }
      }
    }

    // Effectuer la requête si les données ne sont pas en cache ou expirées
    final response = await http.post(
      Uri.parse('https://rpc.gnosischain.com'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "jsonrpc": "2.0",
        "method": "eth_call",
        "params": [
          {"to": contract, "data": "0x70a08231000000000000000000000000${address.substring(2)}"},
          "latest"
        ],
        "id": 1
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];
      debugPrint("🚀 apiService: RPC gnosis -> requête lancée");

      if (result != null && result != "0x") {
        final balance = BigInt.parse(result.substring(2), radix: 16);

        // Sauvegarder le résultat dans le cache
        await box.put(cacheKey, balance.toString());
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        box.put('lastExecutionTime_Balances', now.toIso8601String());

        return balance;
      } else {
        // debugPrint("apiService: RPC gnosis -> Invalid response for contract $contract: $result");
      }
    } else {
      // debugPrint('apiService: RPC gnosis -> Failed to fetch balance for contract $contract. Status code: ${response.statusCode}');
    }

    return null;
  }

  /// Fonction pour récupérer le solde du token natif (xDAI) via eth_getBalance
  static Future<BigInt?> _fetchNativeBalance(String address, {bool forceFetch = false}) async {
    final String cacheKey = 'cachedNativeBalance_$address';
    final box = await Hive.openBox('balanceCache');
    final now = DateTime.now();

    final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get(cacheKey);
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchNativeBalance -> Cache utilisé");
          return BigInt.tryParse(cachedData);
        }
      }
    }

    final response = await http.post(
      Uri.parse('https://rpc.gnosischain.com'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [address, "latest"],
        "id": 1
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];
      debugPrint("🚀 apiService: RPC Gnosis -> Requête eth_getBalance lancée");

      if (result != null && result != "0x") {
        final balance = BigInt.parse(result.substring(2), radix: 16);
        await box.put(cacheKey, balance.toString());
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        return balance;
      }
    }
    return null;
  }

  // Nouvelle méthode pour récupérer les détails des loyers
  static Future<List<Map<String, dynamic>>> fetchDetailedRentDataForAllWallets({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? []; // Récupérer les adresses de tous les wallets

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ apiService: fetchDetailedRentDataForAllWallets -> wallet non renseigné");
      return []; // Ne pas exécuter si la liste des wallets est vide
    }

    // Ouvrir la boîte Hive pour stocker en cache
    var box = await Hive.openBox('detailedRentData');
    final DateTime now = DateTime.now();

    // Initialiser une liste pour stocker les données brutes
    List<Map<String, dynamic>> allRentData = [];

    // Boucle pour chaque adresse de wallet
    for (var walletAddress in evmAddresses) {
      final lastFetchTime = box.get('lastDetailedRentFetchTime_$walletAddress');

      // Si forceFetch est false, vérifier si c'est mardi ou si le dernier fetch est un mardi de plus de 7 jours
      if (!forceFetch && lastFetchTime != null) {
        final DateTime lastFetch = DateTime.parse(lastFetchTime);

        // Si aujourd'hui n'est pas mardi, et le dernier fetch un mardi est de moins de 7 jours, renvoyer une liste vide
        if (now.weekday != DateTime.tuesday || (lastFetch.weekday == DateTime.tuesday && now.difference(lastFetch).inDays <= 7)) {
          debugPrint('⚠️ apiService: ehpst -> Pas de fetch car aujourd\'hui n\'est pas mardi ou le dernier fetch mardi est de moins de 7 jours');
          return [];
        }
      }

      // Si on est mardi ou si le dernier fetch d'un mardi date de plus de 7 jours, effectuer la requête HTTP avec un timeout de 2 minutes
      final url = '${Parameters.rentTrackerUrl}/detailed_rent_holder/$walletAddress';
      try {
        final response = await http.get(Uri.parse(url)).timeout(Duration(minutes: 2), onTimeout: () {
          // Gérer le timeout ici
          throw TimeoutException('La requête a expiré après 2 minutes');
        });

        // Si on reçoit un code 429, sauvegarder l'heure et arrêter
        if (response.statusCode == 429) {
          debugPrint('⚠️ apiService: ehpst -> 429 Too Many Requests');
          break; // Sortir de la boucle et arrêter la méthode
        }

        // Si la requête réussit avec un code 200, traiter les données
        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(response.body));

          // Sauvegarder dans le cache
          box.put('cachedDetailedRentData_$walletAddress', json.encode(rentData));
          box.put('lastDetailedRentFetchTime_$walletAddress', now.toIso8601String());
          debugPrint("🚀 apiService: ehpst -> detailRent, requête lancée");

          // Ajouter les données brutes au tableau
          allRentData.addAll(rentData);
        } else {
          throw Exception('apiService: ehpst -> detailRent, Failed to fetch detailed rent data for wallet: $walletAddress');
        }
      } catch (e) {
        debugPrint('❌ Erreur lors de la requête HTTP : $e');
        // Vous pouvez gérer les exceptions ici (timeout ou autres erreurs)
      }
    }
    box.put('lastExecutionTime_Rents', now.toIso8601String());

    // Retourner les données brutes pour traitement dans DataManager
    return allRentData;
  }

  // Nouvelle méthode pour récupérer les propriétés en cours de vente
  static Future<List<Map<String, dynamic>>> fetchPropertiesForSale() async {
    const url = 'https://realt.co/wp-json/realt/v1/products/for_sale';

    try {
      // Envoie de la requête GET
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        debugPrint("✅ apiService: fetchPropertiesForSale -> Requête lancée avec succès");

        // Décoder la réponse JSON
        final data = json.decode(response.body);

        // Extraire la liste de produits
        final List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(data['products']);

        return properties;
      } else {
        throw Exception('apiService: fetchPropertiesForSale -> Échec de la requête. Code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("apiService: fetchPropertiesForSale -> Erreur lors de la requête: $e");
      return [];
    }
  }

  static Future<List<dynamic>> fetchTokenVolumes({bool forceFetch = false, bool useAlternativeKey = false}) async {
    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastTokenVolumesFetchTime');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    int daysLimit = prefs.getInt('daysLimit') ?? 30;

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedTokenVolumesData');
        if (cachedData != null) {
          return json.decode(cachedData);
        }
      }
    }

    final String limitDate = DateTime.now().subtract(Duration(days: daysLimit)).toIso8601String().split('T').first;
    final apiUrl = Parameters.getGraphUrl(Parameters.yamSubgraphId, useAlternativeKey: useAlternativeKey);

    List<dynamic> allTokens = [];
    int skip = 0;
    bool hasMoreData = true;

    while (hasMoreData) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "query": '''
            query GetTokenVolumes(\$stables: [String!], \$limitDate: String!, \$skip: Int!) {
              tokens(first: 1000, skip: \$skip) {
                id
                decimals
                volumes(where: { token_in: \$stables }) {
                  token {
                    decimals
                  }
                  volumeDays(orderBy: date, orderDirection: desc, where: { date_gte: \$limitDate }) {
                    date
                    quantity
                    volume
                  }
                }
              }
            }
          ''',
            "variables": {
              "stables": Parameters.stables,
              "limitDate": limitDate,
              "skip": skip,
            }
          }),
        );

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(response.body);

          if (decodedResponse.containsKey('errors')) {
            final errorMessage = json.encode(decodedResponse['errors']);
            if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
              debugPrint("🔄 TheGraph API limit exceeded or API key not found, switching to alternative API key...");
              return await fetchTokenVolumes(forceFetch: forceFetch, useAlternativeKey: true);
            }
            throw Exception("Erreur API: $errorMessage");
          }

          if (decodedResponse['data'] != null && decodedResponse['data']['tokens'] != null) {
            final List<dynamic> tokens = decodedResponse['data']['tokens'];

            allTokens.addAll(tokens);

            // Si on récupère moins de 1000 éléments, on arrête la pagination
            if (tokens.length < 1000) {
              hasMoreData = false;
            } else {
              skip += 1000; // Passer aux tokens suivants
            }
          } else {
            hasMoreData = false; // Arrêter si aucune donnée
          }
        } else {
          throw Exception('Échec de la requête fetchTokenVolumes');
        }
      } catch (e) {
        throw Exception('Échec de la récupération des volumes de tokens: $e');
      }
    }

    // Sauvegarde des données en cache
    box.put('cachedTokenVolumesData', json.encode(allTokens));
    box.put('lastTokenVolumesFetchTime', now.toIso8601String());
    box.put('lastExecutionTime_YAM transactions', now.toIso8601String());

    return allTokens;
  }

  static Future<List<dynamic>> fetchTransactionsHistory({
    required List<Map<String, dynamic>> portfolio,
    bool forceFetch = false,
    bool useAlternativeKey = false,
  }) async {
    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('transactionsHistoryFetchTime');
    final DateTime now = DateTime.now();

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Duration(days: 1)) {
        final cachedData = box.get('cachedTransactionsHistoryData');
        if (cachedData != null) {
          return json.decode(cachedData);
        }
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> destinations = prefs.getStringList('evmAddresses') ?? [];
    if (destinations.isEmpty) {
      return [];
    }

    List<String> tokenAddresses = portfolio.map((token) => token['uuid'] as String).toList();
    if (tokenAddresses.isEmpty) {
      return [];
    }

    final apiUrl = Parameters.getGraphUrl(Parameters.gnosisSubgraphId, useAlternativeKey: useAlternativeKey);

    List<dynamic> allTransferEvents = [];
    int skip = 0;
    bool hasMoreData = true;

    while (hasMoreData) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "query": '''
            query GetTransferEvents(\$tokenAddresses: [String!], \$destinations: [String!], \$skip: Int!) {
              transferEvents(
                where: {
                  token_in: \$tokenAddresses,
                  destination_in: \$destinations
                }
                orderBy: timestamp
                orderDirection: desc
                first: 1000
                skip: \$skip
              ) {
                id
                token {
                  id
                }
                amount
                sender
                destination
                timestamp
                transaction {
                  id
                }
              }
            }
          ''',
            "variables": {
              "tokenAddresses": tokenAddresses,
              "destinations": destinations,
              "skip": skip,
            }
          }),
        );

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(response.body);

          if (decodedResponse.containsKey('errors')) {
            final errorMessage = json.encode(decodedResponse['errors']);
            if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
              debugPrint("🔄 TheGraph API limit exceeded or API key not found, switching to alternative API key...");
              return await fetchTransactionsHistory(portfolio: portfolio, forceFetch: forceFetch, useAlternativeKey: true);
            }
            throw Exception("Erreur API: $errorMessage");
          }

          final List<dynamic> transferEvents = decodedResponse['data']['transferEvents'] ?? [];
          allTransferEvents.addAll(transferEvents);

          // Si on récupère moins de 1000 résultats, il n'y en a plus à récupérer
          if (transferEvents.length < 1000) {
            hasMoreData = false;
          } else {
            skip += 1000; // Passer aux résultats suivants
          }
        } else {
          throw Exception('Échec de la requête fetchTransactionsHistory');
        }
      } catch (e) {
        throw Exception('Échec de la récupération de l\'historique des transactions: $e');
      }
    }

    // Sauvegarde des données en cache
    box.put('cachedTransactionsHistoryData', json.encode(allTransferEvents));
    box.put('transactionsHistoryFetchTime', now.toIso8601String());
    box.put('lastExecutionTime_Wallets Transactions', now.toIso8601String());

    return allTransferEvents;
  }

  static Future<List<dynamic>> fetchYamWalletsTransactions({
    bool forceFetch = false,
    bool useAlternativeKey = false,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> destinations = prefs.getStringList('evmAddresses') ?? [];

    if (destinations.isEmpty) {
      return [];
    }

    List<dynamic> allYamTransactions = [];
    final apiUrl = Parameters.getGraphUrl(Parameters.yamSubgraphId, useAlternativeKey: useAlternativeKey);

    for (String address in destinations) {
      int skip = 0; // Début de la pagination
      bool hasMoreData = true; // Flag pour savoir s'il y a encore des données à récupérer

      while (hasMoreData) {
        try {
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "query": '''
              query GetYamTransactions(\$accountId: String!, \$skip: Int!) {
                account(id: \$accountId) {
                  transactions(first: 1000, skip: \$skip) {
                    id
                    price
                    quantity
                    taker { address }
                    createdAtTimestamp
                    offer {
                      id
                      offerToken { address decimals }
                      buyerToken { address decimals }
                      maker { address }
                    }
                  }
                }
              }
            ''',
              "variables": {
                "accountId": address,
                "skip": skip,
              }
            }),
          );

          if (response.statusCode == 200) {
            final decodedResponse = json.decode(response.body);

            if (decodedResponse.containsKey('errors')) {
              final errorMessage = json.encode(decodedResponse['errors']);
              if ((errorMessage.contains('spend limit exceeded') || errorMessage.contains('API key not found')) && !useAlternativeKey) {
                debugPrint("🔄 TheGraph API limit exceeded or API key not found, switching to alternative API key...");
                return await fetchYamWalletsTransactions(forceFetch: forceFetch, useAlternativeKey: true);
              }
              throw Exception("Erreur API: $errorMessage");
            }

            if (decodedResponse['data'] != null && decodedResponse['data']['account'] != null) {
              final List<dynamic> transactions = decodedResponse['data']['account']['transactions'] ?? [];

              allYamTransactions.addAll(transactions);

              // S'il y a moins de 1000 transactions, on arrête la pagination
              if (transactions.length < 1000) {
                hasMoreData = false;
              } else {
                skip += 1000; // Passer aux transactions suivantes
              }
            } else {
              hasMoreData = false; // Arrêter si aucune donnée
            }
          } else {
            throw Exception('Échec de la requête fetchYamWalletsTransactions pour l\'adresse: $address');
          }
        } catch (e) {
          throw Exception('Échec de la récupération des transactions YAM: $e');
        }
      }
    }

    return allYamTransactions;
  }
}
