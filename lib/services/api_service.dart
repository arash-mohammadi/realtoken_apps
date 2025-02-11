import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // Méthode factorisée pour fetch les tokens depuis The Graph
  static Future<List<dynamic>> fetchTokensFromUrl(String url, String cacheKey, {bool forceFetch = false}) async {
    debugPrint("🚀 apiService: fetchTokensFromUrl -> Lancement de la requete");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastFetchTime_$cacheKey');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ apiService: fetchTokensFromUrl -> wallet non renseigné");
      return [];
    }

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedTokenData_$cacheKey');
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchTokensFromUrl -> Requete annulée, temps minimum pas atteint");
          return [];
        }
      }
    }

    // Requête GraphQL
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

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "query": query,
        "variables": {"addressList": evmAddresses}
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ apiService: fetchTokensFromUrl -> requete lancée avec success");
      final data = json.decode(response.body)['data']['accounts'];
      box.put('cachedTokenData_$cacheKey', json.encode(data));
      box.put('lastFetchTime_$cacheKey', now.toIso8601String());

      // Enregistrer uniquement la dernière date et heure d'exécution
      box.put('lastExecutionTime_Portfolio ($cacheKey)', now.toIso8601String());
      return data;
    } else {
      throw Exception('apiService: fetchTokensFromUrl -> Failed to fetch tokens from $url');
    }
  }

  // Fetch depuis Gnosis
  static Future<List<dynamic>> fetchTokensFromGnosis({bool forceFetch = false}) {
    return fetchTokensFromUrl(Parameters.gnosisUrl, 'gnosis', forceFetch: forceFetch);
  }

  // Fetch depuis Etherum
  static Future<List<dynamic>> fetchTokensFromEtherum({bool forceFetch = false}) {
    return fetchTokensFromUrl(Parameters.etherumUrl, 'etherum', forceFetch: forceFetch);
  }

  // Récupérer les tokens sur le RealToken Marketplace (RMM)
  static Future<List<dynamic>> fetchRMMTokens({bool forceFetch = false}) async {
    debugPrint("🚀 apiService: fetchRMMTokens -> Lancement de la requete");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastRMMFetchTime');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ apiService: fetchRMMTokens -> wallet non renseigné");
      return [];
    }

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedRMMData');
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchRMMTokens -> Requete annulée, temps minimum pas atteint");
          return [];
        }
      }
    }

    List<dynamic> allBalances = [];
    for (var address in evmAddresses) {
      final response = await http.post(
        Uri.parse(Parameters.rmmUrl),
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
        debugPrint("✅ apiService: fetchRMMTokens -> requete lancée avec succes");

        final decodedResponse = json.decode(response.body);
        if (decodedResponse['data'] != null && decodedResponse['data']['users'] != null && decodedResponse['data']['users'].isNotEmpty) {
          final data = decodedResponse['data']['users'][0]['balances'];
          allBalances.addAll(data);
        }
      } else {
        throw Exception('apiService: theGraph -> Failed to fetch RMM tokens for address: $address');
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
    final lastUpdateResponse = await http.get(Uri.parse('${Parameters.realTokensUrl}/last_get_realTokens'));

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
    debugPrint("🚀 apiService: fetchYamMarket -> Lancement de la requête");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('yamlastFetchTime');
    final lastUpdateTime = box.get('lastUpdateTime_YamMarket');
    final cachedData = box.get('cachedYamMarket');
    final DateTime now = DateTime.now();

    // Si lastFetchTime est déjà défini et que le temps minimum n'est pas atteint, on vérifie d'abord la validité du cache
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Duration(minutes: 5)) {
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchYamMarket -> Requête annulée, temps minimum pas atteint");
          return [];
        }
      }
    }

    // Vérification de la dernière mise à jour sur le serveur
    final lastUpdateResponse = await http.get(Uri.parse('${Parameters.realTokensUrl}/last_update_yam_offers'));

    if (lastUpdateResponse.statusCode == 200) {
      final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
      final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);

      // Comparaison entre la date de la dernière mise à jour et la date stockée localement
      if (lastUpdateTime != null && cachedData != null) {
        final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
        if (lastExecutionDate.isAtSameMomentAs(lastUpdateDate)) {
          debugPrint("🛑 apiService: fetchYamMarket -> Requête annulée, données déjà à jour");
          return [];
        }
      }

      // Si les dates sont différentes ou pas de cache, on continue avec la requête réseau
      final response = await http.get(Uri.parse('${Parameters.realTokensUrl}/get_yam_offers'));

      if (response.statusCode == 200) {
        debugPrint("✅ apiService: fetchYamMarket -> Requête lancée avec succès");

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
    final url = 'https://api.coingecko.com/api/v3/coins/xdai';
    final response = await http.get(Uri.parse(url));

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
  static Future<String?> fetchUserIdFromAddress(String address) async {
    var url = Parameters.gnosisUrl;

    final query = '''
    {
      account(id: "$address") {
        userIds {
          userId
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"query": query}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final userIds = data['data']['account']['userIds'];
      if (userIds != null && userIds.isNotEmpty) {
        return userIds.first['userId']; // Retourne le premier userId
      }
    }
    return null; // Si aucun userId n'a été trouvé
  }

  // Récupérer les adresses associées à un userId
  static Future<List<String>> fetchAddressesForUserId(String userId) async {
    var url = Parameters.gnosisUrl;

    final query = '''
    {
      accounts(where: { userIds: ["0x296033cb983747b68911244ec1a3f01d7708851b-$userId"] }) {
        address
      }
    }
    ''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"query": query}),
    );

    if (response.statusCode == 200) {
      debugPrint("🚀 apiService: theGraph -> requete lancée");
      final data = json.decode(response.body);
      final accounts = data['data']['accounts'];
      if (accounts != null && accounts.isNotEmpty) {
        return List<String>.from(accounts.map((account) => account['address']));
      }
    } else {
      debugPrint("❌ apiService: theGraph -> echec requete");
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchRmmBalances({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ apiService: fetchRMMBalances-> wallet non renseigné");
      return [];
    }

    // Contrats pour USDC & XDAI
    const String usdcDepositContract = '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1'; // Dépôt USDC
    const String usdcBorrowContract = '0x69c731ae5f5356a779f44c355abb685d84e5e9e6'; // Emprunt USDC
    const String xdaiDepositContract = '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b'; // Dépôt XDAI
    const String xdaiBorrowContract = '0x9908801df7902675c3fedd6fea0294d18d5d5d34'; // Emprunt XDAI

    List<Map<String, dynamic>> allBalances = [];

    for (var address in evmAddresses) {
      // Requête pour le dépôt et l'emprunt de USDC
      final usdcDepositResponse = await _fetchBalance(usdcDepositContract, address, forceFetch: forceFetch);
      final usdcBorrowResponse = await _fetchBalance(usdcBorrowContract, address, forceFetch: forceFetch);

      // Requête pour le dépôt et l'emprunt de XDAI
      final xdaiDepositResponse = await _fetchBalance(xdaiDepositContract, address, forceFetch: forceFetch);
      final xdaiBorrowResponse = await _fetchBalance(
        xdaiBorrowContract,
        address,
      );

      // Traitement des réponses
      if (usdcDepositResponse != null && usdcBorrowResponse != null && xdaiDepositResponse != null && xdaiBorrowResponse != null) {
        final timestamp = DateTime.now().toIso8601String();

        // Conversion des balances en int après division par 1e6 pour USDC et 1e18 pour xDAI
        double usdcDepositBalance = (usdcDepositResponse / BigInt.from(1e6));
        double usdcBorrowBalance = (usdcBorrowResponse / BigInt.from(1e6));
        double xdaiDepositBalance = (xdaiDepositResponse / BigInt.from(1e18));
        double xdaiBorrowBalance = (xdaiBorrowResponse / BigInt.from(1e18));

        // Ajout des balances et du timestamp pour calculer l'APY
        allBalances.add({
          'address': address,
          'usdcDepositBalance': usdcDepositBalance,
          'usdcBorrowBalance': usdcBorrowBalance,
          'xdaiDepositBalance': xdaiDepositBalance,
          'xdaiBorrowBalance': xdaiBorrowBalance,
          'timestamp': timestamp,
        });
      } else {
        throw Exception('Failed to fetch balances for address: $address');
      }
    }
    return allBalances;
  }

// Méthode pour simplifier la récupération des balances
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

  static Future<List<dynamic>> fetchTokenVolumes({bool forceFetch = false}) async {
    debugPrint("🚀 apiService: fetchTokenVolumes -> Lancement de la requête");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastTokenVolumesFetchTime');
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    int daysLimit = prefs.getInt('daysLimit') ?? 30; // Par défaut, 30 jours

    // Vérifiez si le cache est valide
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedTokenVolumesData');
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchTokenVolumes -> Requête annulée, cache valide");
          return json.decode(cachedData);
        }
      }
    }

    // Définition des variables pour la requête GraphQL
    const List<String> stables = ["0xe91d153e0b41518a2ce8dd3d7944fa863463a97d", "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83", "0x7349c9eaa538e118725a6130e0f8341509b9f8a0"];
    final String limitDate = DateTime.now().subtract(Duration(days: daysLimit)).toIso8601String().split('T').first;

    // Envoyer la requête GraphQL
    final response = await http.post(
      Uri.parse(Parameters.yamUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "query": '''
          query GetTokenVolumes(\$stables: [String!], \$limitDate: String!) {
            tokens(first: 1000) {
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
          "stables": stables,
          "limitDate": limitDate,
        }
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ apiService: fetchTokenVolumes -> Requête lancée avec succès");

      final decodedResponse = json.decode(response.body);
      if (decodedResponse['data'] != null && decodedResponse['data']['tokens'] != null) {
        final List<dynamic> tokens = decodedResponse['data']['tokens'];

        // Mettre les données dans le cache
        box.put('cachedTokenVolumesData', json.encode(tokens));
        box.put('lastTokenVolumesFetchTime', now.toIso8601String());
        box.put('lastExecutionTime_YAM transactions', now.toIso8601String());

        return tokens;
      } else {
        debugPrint("❌ apiService: fetchTokenVolumes -> Aucune donnée disponible");
        return [];
      }
    } else {
      throw Exception('apiService: fetchTokenVolumes -> Échec de la requête');
    }
  }

  static Future<List<dynamic>> fetchTransactionsHistory({
    required List<Map<String, dynamic>> portfolio,
    bool forceFetch = false,
  }) async {
    debugPrint("🚀 apiService: fetchTransactionsHistory -> Lancement de la requête");

    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('transactionsHistoryFetchTime');
    final DateTime now = DateTime.now();

    // Vérifiez si le cache est valide
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Duration(days: 1)) {
        final cachedData = box.get('cachedTransactionsHistoryData');
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchTransactionsHistory -> Requête annulée, cache valide");
          return json.decode(cachedData);
        }
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> destinations = prefs.getStringList('evmAddresses') ?? [];

    if (destinations.isEmpty) {
      debugPrint("apiService: fetchTransactionsHistory -> Pas d'adresses de destination disponibles");
      return [];
    }

    // Extraire les UUID des tokens depuis le portfolio
    List<String> tokenAddresses = portfolio.map((token) => token['uuid'] as String).toList();

    if (tokenAddresses.isEmpty) {
      debugPrint("apiService: fetchTransactionsHistory -> Pas de tokens disponibles dans le portfolio");
      return [];
    }

    // Requête GraphQL
    final response = await http.post(
      Uri.parse(Parameters.gnosisUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "query": '''
      query GetTransferEvents(\$tokenAddresses: [String!], \$destinations: [String!]) {
        transferEvents(
          where: {
            token_in: \$tokenAddresses,
            destination_in: \$destinations
          }
          orderBy: timestamp
          orderDirection: desc
          first: 1000
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
        }
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ apiService: fetchTransactionsHistory -> Requête lancée avec succès");

      final decodedResponse = json.decode(response.body);

      // Vérifiez si "data" et "transferEvents" existent
      if (decodedResponse['data'] != null && decodedResponse['data']['transferEvents'] != null) {
        final List<dynamic> transferEvents = decodedResponse['data']['transferEvents'];

        if (transferEvents.isNotEmpty) {
          // Mettre les données dans le cache
          box.put('cachedTransactionsHistoryData', json.encode(transferEvents));
          box.put('transactionsHistoryFetchTime', now.toIso8601String());
          box.put('lastExecutionTime_Wallets Transactions', now.toIso8601String());
          print(transferEvents);
          return transferEvents;
        } else {
          debugPrint("apiService: fetchTransactionsHistory -> Aucun événement de transfert trouvé");
          return [];
        }
      } else {
        debugPrint("apiService: fetchTransactionsHistory -> Aucune donnée dans la réponse");
        return [];
      }
    } else {
      throw Exception('apiService: fetchTransactionsHistory -> Échec de la requête');
    }
  }

static Future<List<dynamic>> fetchYamWalletsTransactions({
    bool forceFetch = false,
  }) async {
    debugPrint("🚀 apiService: fetchYamWalletsTransactions -> Lancement de la requête");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> destinations = prefs.getStringList('evmAddresses') ?? [];

    if (destinations.isEmpty) {
      debugPrint("apiService: fetchYamWalletsTransactions -> Pas d'adresses de destination disponibles");
      return [];
    }

    List<dynamic> allYamTransactions = [];

    for (String address in destinations) {
      final response = await http.post(
        Uri.parse(Parameters.yamUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "query": '''
          query GetYamTransactions(\$accountId: String!) {
            account(id: \$accountId) {
              transactions {
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
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ apiService: fetchYamWalletsTransactions -> Requête réussie pour $address");
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['data'] != null && decodedResponse['data']['account'] != null) {
          final List<dynamic> transactions = decodedResponse['data']['account']['transactions'] ?? [];
          allYamTransactions.addAll(transactions);
        }
      } else {
        debugPrint("❌ apiService: fetchYamWalletsTransactions -> Échec pour $address");
      }
    }

    return allYamTransactions;
  }
}
