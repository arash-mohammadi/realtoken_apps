import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {


   /// Récupère toutes les adresses associées à une adresse Ethereum via FastAPI
  static Future<Map<String, dynamic>?> fetchUserAndAddresses(String address) async {
    final apiUrl = "${Parameters.mainApiUrl}/wallet_userId/$address";

    debugPrint("📡 Envoi de la requête à FastAPI: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("📩 Réponse reçue: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("📝 Données reçues: $data");

        if (data['status'] == "success") {
          return {
            "userId": data['userId'],
            "addresses": List<String>.from(data['addresses']),
          };
        } else {
          debugPrint("⚠️ Aucun userId trouvé pour l'adresse $address");
          return null;
        }
      } else {
        debugPrint("❌ Erreur HTTP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception dans fetchUserAndAddresses: $e");
      return null;
    }
  }

  // Méthode factorisée pour fetch les tokens depuis The Graph
 static Future<List<dynamic>> fetchWalletTokens({bool forceFetch = false}) async {
  final box = Hive.box('realTokens');
  final prefs = await SharedPreferences.getInstance();
  List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

  if (evmAddresses.isEmpty) {
    return [];
  }

  final DateTime now = DateTime.now();
  final cacheKey = 'wallet_tokens';
  final lastFetchTime = box.get('lastFetchTime_$cacheKey');

  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
      final cachedData = box.get('cachedTokenData_$cacheKey');
      if (cachedData != null) {
        return jsonDecode(cachedData);
      }
    }
  }

  try {
    List<dynamic> allWalletTokens = [];

    for (String wallet in evmAddresses) {
      final apiUrl = '${Parameters.mainApiUrl}/wallet_tokens/$wallet';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final walletData = jsonDecode(response.body);
        allWalletTokens.addAll(walletData);
      } else {
        debugPrint('Erreur récupération tokens wallet $wallet');
      }
    }

    // Mise en cache des données globales
    box.put('cachedTokenData_$cacheKey', jsonEncode(allWalletTokens));
    debugPrint("🔵 Tokens fetched from API: ${allWalletTokens.length} tokens");
    //debugPrint("🔵 Tokens fetched from API: ${allWalletTokens}");
    box.put('lastFetchTime_$cacheKey', now.toIso8601String());
    box.put('lastExecutionTime_Portfolio ($cacheKey)', now.toIso8601String());

    return allWalletTokens;
  } catch (e) {
    throw Exception('Échec récupération tokens: $e');
  }
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

    // Si lastFetchTime est déjà défini et qufve le temps minimum n'est pas atteint, on vérifie d'abord la validité du cache
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
        return []; // Retourner une liste vide, le DataManager utilisera le cache
      }
    }

    // Vérification du jour de la semaine et de la date de dernière mise à jour
    final lastFetchTime = box.get('lastRentFetchTime');
    bool shouldFetch = forceFetch;
    
    if (!shouldFetch) {
      // Vérifier si aujourd'hui est mardi (jour 2 de la semaine)
      final bool isTuesday = now.weekday == DateTime.tuesday;
      
      // Vérifier si la dernière mise à jour date de plus de 7 jours
      bool isOlderThanOneWeek = false;
      if (lastFetchTime != null) {
        final DateTime lastFetch = DateTime.parse(lastFetchTime);
        isOlderThanOneWeek = now.difference(lastFetch).inDays > 7;
      } else {
        // Si pas de dernière mise à jour, on considère que c'est plus vieux que 7 jours
        isOlderThanOneWeek = true;
      }
      
      // On fetch seulement si c'est mardi ou si ça fait plus de 7 jours
      shouldFetch = isTuesday || isOlderThanOneWeek;
      
      if (!shouldFetch) {
        debugPrint("🛑 apiService: fetchRentData -> Requête annulée, ce n'est pas mardi et dernière mise à jour < 7 jours");
        return []; // Retourner une liste vide, le DataManager utilisera le cache
      }
    }
    
    // Vérification du cache standard (temps minimum)
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        debugPrint("🛑 apiService: fetchRentData -> Requête annulée, temps minimum pas atteint");
        return []; // Retourner une liste vide, le DataManager utilisera le cache
      }
    }

    // Sinon, on effectue la requête API
    List<Map<String, dynamic>> mergedRentData = [];
    bool hasError = false;

    debugPrint("🚀 apiService: fetchRentData -> Lancement des requêtes pour ${wallets.length} wallets");

    for (String wallet in wallets) {
      final url = '${Parameters.rentTrackerUrl}/rent_holder/$wallet';
      final response = await http.get(Uri.parse(url));

      // Si on reçoit un code 429, sauvegarder l'heure et arrêter
      if (response.statusCode == 429) {
        debugPrint('⚠️ apiService: ehpst -> 429 Too Many Requests pour le wallet $wallet');
        // Sauvegarder le temps où la réponse 429 a été reçue
        box.put('lastRent429Time', now.toIso8601String());
        hasError = true;
        break; // Sortir de la boucle et arrêter la méthode
      }

      if (response.statusCode == 200) {
        debugPrint("🚀 apiService: ehpst -> RentTracker, requete lancée pour $wallet");

        List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(response.body));
        for (var rentEntry in rentData) {
          // Vérifier si la date est une chaîne, puis la convertir en DateTime
          DateTime rentDate = DateTime.parse(rentEntry['date']);
          
          // Ajouter 1 jour
          rentDate = rentDate.add(Duration(days: 1));

          // Reformater la date en String
          String updatedDate = "${rentDate.year}-${rentDate.month.toString().padLeft(2, '0')}-${rentDate.day.toString().padLeft(2, '0')}";

          final existingEntry = mergedRentData.firstWhere(
            (entry) => entry['date'] == updatedDate,
            orElse: () => <String, dynamic>{},
          );

          if (existingEntry.isNotEmpty) {
            existingEntry['rent'] = (existingEntry['rent'] ?? 0) + (rentEntry['rent'] ?? 0);
          } else {
            mergedRentData.add({
              'date': updatedDate,  // Utilisation de la date mise à jour
              'rent': rentEntry['rent'] ?? 0,
            });
          }
        }
      } else {
        debugPrint('❌ apiService: ehpst -> Erreur lors de la récupération des données de loyer pour le wallet: $wallet');
        hasError = true;
        break;
      }
    }

    // En cas d'erreur, retourner une liste vide
    if (hasError) {
      debugPrint("⚠️ apiService: fetchRentData -> Erreurs rencontrées, retour d'une liste vide");
      return [];
    }

    mergedRentData.sort((a, b) => a['date'].compareTo(b['date']));

    // Mise à jour des timestamps seulement si aucune erreur n'a été rencontrée et qu'on a récupéré des données
    if (mergedRentData.isNotEmpty) {
      debugPrint("✅ apiService: fetchRentData -> ${mergedRentData.length} entrées récupérées");
      box.put('lastRentFetchTime', now.toIso8601String());
      box.put('lastExecutionTime_Rents', now.toIso8601String());
    }

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

  // Si les données sont en cache et n'ont pas expiré, retourner le cache
  if (cachedData != null && cacheTime != null && (currentTime - cacheTime) < cacheDuration) {
    return jsonDecode(cachedData) as Map<String, dynamic>;
  }

  try {
    // Récupérer les devises depuis l'API
    final response = await http.get(Uri.parse(Parameters.coingeckoUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currencies = data['market_data']['current_price'] as Map<String, dynamic>;

      // Stocker les devises en cache
      await prefs.setString('cachedCurrencies', jsonEncode(currencies));
      await prefs.setInt('cachedCurrenciesTime', currentTime);
      return currencies;
    } else {
      debugPrint('Erreur lors de la récupération des devises: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Exception lors du chargement des devises: $e');
  }

  // En cas d'erreur, retourner le cache si disponible ou un objet vide pour éviter le blocage
  if (cachedData != null) {
    return jsonDecode(cachedData) as Map<String, dynamic>;
  } else {
    return {};
  }
}
  // Récupérer le userId associé à une adresse Ethereum
  
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

    debugPrint("📋 apiService: fetchDetailedRentDataForAllWallets -> ${evmAddresses.length} wallets à consulter: ${evmAddresses.join(', ')}");

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
      debugPrint("🔄 apiService: Traitement du wallet: $walletAddress");
      final lastFetchTime = box.get('lastDetailedRentFetchTime_$walletAddress');

      // Si forceFetch est false, vérifier si c'est mardi ou si le dernier fetch est un mardi de plus de 7 jours
      if (!forceFetch && lastFetchTime != null) {
        final DateTime lastFetch = DateTime.parse(lastFetchTime);

        // Si aujourd'hui n'est pas mardi, et le dernier fetch un mardi est de moins de 7 jours, charger depuis le cache
        if (now.weekday != DateTime.tuesday || (lastFetch.weekday == DateTime.tuesday && now.difference(lastFetch).inDays <= 7)) {
          debugPrint('⚠️ apiService: ehpst -> Pas de fetch API pour $walletAddress, chargement du cache');
          
          // Charger depuis le cache pour ce wallet
          final cachedData = box.get('cachedDetailedRentData_$walletAddress');
          if (cachedData != null) {
            try {
              final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(cachedData));
              
              // Vérifier et ajouter l'adresse du wallet si nécessaire
              for (var entry in rentData) {
                if (!entry.containsKey('wallet') || entry['wallet'] == null) {
                  entry['wallet'] = walletAddress;
                }
              }
              
              allRentData.addAll(rentData);
              debugPrint("✅ apiService: Données de loyer chargées du cache pour $walletAddress (${rentData.length} entrées)");
            } catch (e) {
              debugPrint('❌ Erreur lors du chargement des données en cache pour $walletAddress: $e');
            }
          } else {
            debugPrint('⚠️ apiService: Pas de données en cache pour $walletAddress');
          }
          
          continue; // Passer au wallet suivant
        }
      }

      // Si on est mardi ou si le dernier fetch d'un mardi date de plus de 7 jours, effectuer la requête HTTP avec un timeout de 2 minutes
      final url = '${Parameters.rentTrackerUrl}/detailed_rent_holder/$walletAddress';
      debugPrint("🌐 apiService: Tentative de requête API pour $walletAddress: $url");
      
      try {
        final response = await http.get(Uri.parse(url)).timeout(Duration(minutes: 2), onTimeout: () {
          // Gérer le timeout ici
          debugPrint('⏱️ apiService: Timeout après 2 minutes pour le wallet $walletAddress');
          throw TimeoutException('La requête a expiré après 2 minutes');
        });

        // Si on reçoit un code 429, sauvegarder l'heure et arrêter
        if (response.statusCode == 429) {
          debugPrint('⚠️ apiService: ehpst -> 429 Too Many Requests pour le wallet $walletAddress');
          
          // Essayer de charger depuis le cache
          _loadFromCache(box, walletAddress, allRentData);
          
          break; // Sortir de la boucle et arrêter la méthode
        }

        // Si la requête réussit avec un code 200, traiter les données
        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(response.body));

          // Ajouter l'adresse du wallet à chaque entrée
          for (var entry in rentData) {
            entry['wallet'] = walletAddress;
          }

          // Sauvegarder dans le cache
          box.put('cachedDetailedRentData_$walletAddress', json.encode(rentData));
          box.put('lastDetailedRentFetchTime_$walletAddress', now.toIso8601String());
          debugPrint("✅ apiService: Requête réussie pour $walletAddress, ${rentData.length} entrées obtenues");

          // Ajouter les données brutes au tableau
          allRentData.addAll(rentData);
        } else {
          debugPrint('❌ apiService: Échec de la requête pour $walletAddress: ${response.statusCode}');
          
          // Charger depuis le cache en cas d'échec
          _loadFromCache(box, walletAddress, allRentData);
        }
      } catch (e) {
        debugPrint('❌ Erreur lors de la requête HTTP pour $walletAddress: $e');
        
        // Charger depuis le cache en cas d'erreur
        _loadFromCache(box, walletAddress, allRentData);
      }
    }
    
    // Vérification finale pour s'assurer que toutes les entrées ont un wallet
    int entriesSansWallet = 0;
    for (var entry in allRentData) {
      if (!entry.containsKey('wallet') || entry['wallet'] == null) {
        entry['wallet'] = 'unknown';
        entriesSansWallet++;
      }
    }
    if (entriesSansWallet > 0) {
      debugPrint('⚠️ apiService: $entriesSansWallet entrées sans wallet ont été assignées à "unknown"');
    }
    
    box.put('lastExecutionTime_Rents', now.toIso8601String());
    
    debugPrint('✅ apiService: Fin du traitement - ${allRentData.length} entrées de données de loyer au total');
    
    // Comptage des entrées par wallet
    Map<String, int> entriesPerWallet = {};
    for (var entry in allRentData) {
      String wallet = entry['wallet'];
      entriesPerWallet[wallet] = (entriesPerWallet[wallet] ?? 0) + 1;
    }
    entriesPerWallet.forEach((wallet, count) {
      debugPrint('📊 apiService: Wallet $wallet - $count entrées');
    });

    // Retourner les données brutes pour traitement dans DataManager
    return allRentData;
  }

  // Méthode utilitaire pour charger les données du cache
  static void _loadFromCache(Box box, String walletAddress, List<Map<String, dynamic>> allRentData) {
    debugPrint('🔄 apiService: Tentative de chargement du cache pour $walletAddress');
    final cachedData = box.get('cachedDetailedRentData_$walletAddress');
    if (cachedData != null) {
      try {
        final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(cachedData));
        
        // Vérifier et ajouter l'adresse du wallet si nécessaire
        for (var entry in rentData) {
          if (!entry.containsKey('wallet') || entry['wallet'] == null) {
            entry['wallet'] = walletAddress;
          }
        }
        
        allRentData.addAll(rentData);
        debugPrint("✅ apiService: Données de loyer chargées du cache pour $walletAddress (${rentData.length} entrées)");
      } catch (e) {
        debugPrint('❌ Erreur lors du chargement des données en cache pour $walletAddress: $e');
      }
    } else {
      debugPrint('⚠️ apiService: Pas de données en cache pour le wallet $walletAddress');
    }
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
    var box = Hive.box('realTokens');
    final lastFetchTime = box.get('lastTokenVolumesFetchTime');
    final DateTime now = DateTime.now();

    // Récupération de la limite de jours depuis les SharedPreferences ou 30 par défaut
    // (Si vous n'utilisez plus ce paramètre, vous pouvez le conserver pour la logique du cache.)
    // final prefs = await SharedPreferences.getInstance();
    // int daysLimit = prefs.getInt('daysLimit') ?? 30;

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get('cachedTokenVolumesData');
        if (cachedData != null) {
          return json.decode(cachedData);
        }
      }
    }

    // Appel de la nouvelle route FastAPI
    // Assurez-vous de remplacer l'URL par celle de votre serveur FastAPI.
    final apiUrl = '${Parameters.mainApiUrl}/tokens_volume/';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Sauvegarde dans le cache local
      box.put('cachedTokenVolumesData', json.encode(data));
      box.put('lastTokenVolumesFetchTime', now.toIso8601String());
      box.put('lastExecutionTime_YAM transactions', now.toIso8601String());
      return data;
    } else {
      throw Exception("Échec de la récupération depuis FastAPI: ${response.statusCode}");
    }
  }



 static Future<List<dynamic>> fetchTransactionsHistory({bool forceFetch = false}) async {
  var box = Hive.box('realTokens');
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

  if (evmAddresses.isEmpty) {
    return [];
  }

  final DateTime now = DateTime.now();
  final cacheKey = 'transactions_history';
  final lastFetchTime = box.get('lastFetchTime_$cacheKey');

  // Vérifier le cache avant de récupérer à nouveau les données
  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
      final cachedData = box.get('cachedTransactionsData_$cacheKey');
      if (cachedData != null) {
        return jsonDecode(cachedData);
      }
    }
  }

  try {
    List<dynamic> allTransactions = [];

    for (String wallet in evmAddresses) {
      final apiUrl = '${Parameters.mainApiUrl}/transactions_history/$wallet';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final walletData = jsonDecode(response.body);
        allTransactions.addAll(walletData);
      } else {
        debugPrint("⚠️ Erreur récupération transactions pour le wallet: $wallet");
      }
    }

    // Mise en cache des données globales
    box.put('cachedTransactionsData_$cacheKey', jsonEncode(allTransactions));
    box.put('lastFetchTime_$cacheKey', now.toIso8601String());
    box.put('lastExecutionTime_Transactions', now.toIso8601String());

    debugPrint("✅ Transactions récupérées: ${allTransactions.length}");

    return allTransactions;
  } catch (e) {
    throw Exception('❌ Échec récupération des transactions: $e');
  }
}

static Future<List<dynamic>> fetchYamWalletsTransactions({bool forceFetch = false}) async {
  var box = Hive.box('realTokens');
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

  if (evmAddresses.isEmpty) {
    return [];
  }

  final DateTime now = DateTime.now();
  final cacheKey = 'yam_wallet_transactions';
  final lastFetchTime = box.get('lastFetchTime_$cacheKey');

  // Vérifier le cache avant de récupérer à nouveau les données
  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
      final cachedData = box.get('cachedTransactionsData_$cacheKey');
      if (cachedData != null) {
        return jsonDecode(cachedData);
      }
    }
  }

  try {
    List<dynamic> allYamTransactions = [];

    for (String wallet in evmAddresses) {
      final apiUrl = '${Parameters.mainApiUrl}/YAM_transactions_history/$wallet';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final walletData = jsonDecode(response.body);
        allYamTransactions.addAll(walletData);
      } else {
        debugPrint("⚠️ Erreur récupération transactions YAM pour le wallet: $wallet");
      }
    }

    // Mise en cache des données globales
    box.put('cachedTransactionsData_$cacheKey', jsonEncode(allYamTransactions));
    box.put('lastFetchTime_$cacheKey', now.toIso8601String());
    box.put('lastExecutionTime_YAM transactions', now.toIso8601String());

    debugPrint("✅ Transactions YAM récupérées: ${allYamTransactions.length}");

    return allYamTransactions;
  } catch (e) {
    throw Exception('❌ Échec récupération des transactions YAM: $e');
  }
}}
