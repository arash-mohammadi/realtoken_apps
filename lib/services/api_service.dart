import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Méthode générique optimisée pour gérer le cache avec fallback automatique
  /// Support des types: List<dynamic>, Map<String, dynamic>, String, etc.
  static Future<T> _fetchWithCache<T>({
    required String cacheKey,
    required Future<T> Function() apiCall,
    required String debugName,
    required T Function(dynamic) fromJson,
    required dynamic Function(T) toJson,
    required T emptyValue,
    bool forceFetch = false,
    String? alternativeCacheKey,
    Duration? customCacheDuration,
    Future<bool> Function()? shouldUpdate,
  }) async {
    final box = Hive.box('realTokens');
    final DateTime now = DateTime.now();
    final lastFetchTime = box.get('lastFetchTime_$cacheKey');
    final cacheDuration = customCacheDuration ?? Parameters.apiCacheDuration;

    // 1. Toujours tenter de charger le cache d'abord
    T? cachedResult;
    try {
      var cachedData = box.get(cacheKey);
      if (cachedData == null && alternativeCacheKey != null) {
        cachedData = box.get(alternativeCacheKey);
      }
      
      if (cachedData != null) {
        cachedResult = fromJson(cachedData is String ? jsonDecode(cachedData) : cachedData);
        debugPrint("🔵 Cache $debugName disponible");
      }
    } catch (e) {
      debugPrint("⚠️ Erreur décodage cache $debugName: $e");
    }

    // 2. Vérifier si une mise à jour est nécessaire
    bool needsUpdate = forceFetch;
    if (!needsUpdate && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      needsUpdate = now.difference(lastFetch) >= cacheDuration;
    } else if (lastFetchTime == null) {
      needsUpdate = true;
    }

    // 3. Vérifier les conditions personnalisées de mise à jour
    if (!needsUpdate && shouldUpdate != null) {
      try {
        needsUpdate = await shouldUpdate();
      } catch (e) {
        debugPrint("⚠️ Erreur vérification shouldUpdate pour $debugName: $e");
      }
    }

    // 4. Si pas besoin de mise à jour et cache disponible, retourner le cache
    if (!needsUpdate && cachedResult != null) {
      debugPrint("✅ Cache $debugName valide utilisé");
      return cachedResult;
    }

    // 5. Tentative de mise à jour via API
    try {
      debugPrint("🔄 Mise à jour $debugName depuis l'API...");
      final apiResult = await apiCall();
      
      if (apiResult != null && apiResult != emptyValue) {
        // Sauvegarder le nouveau cache
        final jsonData = toJson(apiResult);
        await box.put(cacheKey, jsonData is String ? jsonData : jsonEncode(jsonData));
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        await box.put('lastExecutionTime_$debugName', now.toIso8601String());
        debugPrint("💾 $debugName mis à jour depuis l'API");
        return apiResult;
      } else {
        debugPrint("⚠️ API $debugName a retourné des données vides");
      }
    } catch (e) {
      debugPrint("❌ Erreur API $debugName: $e");
    }

    // 6. Fallback sur le cache si disponible
    if (cachedResult != null) {
      debugPrint("🔄 Utilisation du cache $debugName suite à erreur API");
      return cachedResult;
    }

    // 7. Dernier recours : valeur par défaut
    debugPrint("❌ Aucune donnée disponible pour $debugName, utilisation valeur par défaut");
    return emptyValue;
  }

  /// Version simplifiée pour les listes (compatibilité descendante)
  static Future<List<dynamic>> _fetchWithCacheList({
    required String cacheKey,
    required Future<List<dynamic>> Function() apiCall,
    required String debugName,
    bool forceFetch = false,
    String? alternativeCacheKey,
    Duration? customCacheDuration,
    Future<bool> Function()? shouldUpdate,
  }) async {
    return _fetchWithCache<List<dynamic>>(
      cacheKey: cacheKey,
      apiCall: apiCall,
      debugName: debugName,
      fromJson: (data) => List<dynamic>.from(data),
      toJson: (data) => data,
      emptyValue: <dynamic>[],
      forceFetch: forceFetch,
      alternativeCacheKey: alternativeCacheKey,
      customCacheDuration: customCacheDuration,
      shouldUpdate: shouldUpdate,
    );
  }

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

  // Méthode factorisée pour fetch les tokens depuis The Graph avec cache optimisé
  static Future<List<dynamic>> fetchWalletTokens({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    return _fetchWithCacheList(
      cacheKey: 'cachedTokenData_wallet_tokens',
      alternativeCacheKey: 'cachedTokenData_tokens',
      debugName: "Wallet Tokens",
      forceFetch: forceFetch,
      apiCall: () async {
        List<dynamic> allWalletTokens = [];
        int successCount = 0;
        int errorCount = 0;

        for (String wallet in evmAddresses) {
          final apiUrl = '${Parameters.mainApiUrl}/wallet_tokens/$wallet';
          debugPrint("🔄 Récupération des tokens pour le wallet: $wallet");

          try {
            final response = await http.get(Uri.parse(apiUrl))
                .timeout(Duration(seconds: 10), onTimeout: () {
              throw TimeoutException('Délai dépassé pour la récupération des tokens du wallet $wallet');
            });

            if (response.statusCode == 200) {
              final walletData = jsonDecode(response.body);
              if (walletData is List && walletData.isNotEmpty) {
                allWalletTokens.addAll(walletData);
                successCount++;
                debugPrint("✅ ${walletData.length} tokens récupérés pour le wallet $wallet");
              } else {
                debugPrint("⚠️ Aucun token trouvé pour le wallet $wallet");
              }
            } else {
              errorCount++;
              debugPrint("❌ Erreur récupération tokens wallet $wallet: Code HTTP ${response.statusCode}");
            }
          } catch (e) {
            errorCount++;
            debugPrint("❌ Exception lors de la récupération des tokens pour le wallet $wallet: $e");
          }
        }

        debugPrint("📊 Récapitulatif: $successCount wallets réussis, $errorCount wallets en erreur");
        return allWalletTokens;
      },
    );
  }

  // Récupérer la liste complète des RealTokens depuis l'API pitswap avec cache optimisé
  static Future<List<dynamic>> fetchRealTokens({bool forceFetch = false}) async {
    debugPrint("🚀 apiService: fetchRealTokens -> Lancement de la requête");

    final box = Hive.box('realTokens');
    
    return _fetchWithCacheList(
      cacheKey: 'cachedRealTokens',
      debugName: "RealTokens",
      forceFetch: forceFetch,
      shouldUpdate: () async {
        // Logique spécifique : vérifier les timestamps serveur
        if (forceFetch) return true;
        
        try {
          final lastUpdateTime = box.get('lastUpdateTime_RealTokens');
          if (lastUpdateTime == null) return true;

          // Vérification de la dernière mise à jour sur le serveur
          final lastUpdateResponse = await http.get(
            Uri.parse('${Parameters.realTokensUrl}/last_get_realTokens_mobileapps')
          ).timeout(Duration(seconds: 10));

          if (lastUpdateResponse.statusCode == 200) {
            final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
            final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);
            final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
            
            bool needsUpdate = !lastExecutionDate.isAtSameMomentAs(lastUpdateDate);
            if (!needsUpdate) {
              debugPrint("✅ Données RealTokens déjà à jour selon le serveur");
            }
            return needsUpdate;
          }
        } catch (e) {
          debugPrint("⚠️ Erreur vérification timestamp serveur RealTokens: $e");
        }
        return false; // En cas d'erreur, ne pas forcer la mise à jour
      },
      apiCall: () async {
        // Récupérer les nouvelles données
        final response = await http.get(
          Uri.parse('${Parameters.realTokensUrl}/realTokens_mobileapps')
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Sauvegarder le timestamp serveur spécifique à RealTokens
          try {
            final lastUpdateResponse = await http.get(
              Uri.parse('${Parameters.realTokensUrl}/last_get_realTokens_mobileapps')
            ).timeout(Duration(seconds: 5));
            
            if (lastUpdateResponse.statusCode == 200) {
              final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
              await box.put('lastUpdateTime_RealTokens', lastUpdateDateString);
            }
          } catch (e) {
            debugPrint("⚠️ Erreur sauvegarde timestamp RealTokens: $e");
          }
          
          debugPrint("💾 RealTokens mis à jour: ${data.length} tokens");
          return data;
        } else {
          throw Exception("Erreur HTTP ${response.statusCode} lors de la récupération des RealTokens");
        }
      },
    );
  }

  // Récupérer la liste complète des offres YAM depuis l'API avec cache optimisé
  static Future<List<dynamic>> fetchYamMarket({bool forceFetch = false}) async {
    final box = Hive.box('realTokens');
    
    return _fetchWithCacheList(
      cacheKey: 'cachedYamMarket',
      debugName: "YAM Market",
      forceFetch: forceFetch,
      shouldUpdate: () async {
        // Logique spécifique : vérifier les timestamps serveur YAM
        if (forceFetch) return true;
        
        try {
          final lastUpdateTime = box.get('lastUpdateTime_YamMarket');
          if (lastUpdateTime == null) return true;

          // Vérification de la dernière mise à jour sur le serveur
          final lastUpdateResponse = await http.get(
            Uri.parse('${Parameters.realTokensUrl}/last_update_yam_offers_mobileapps')
          ).timeout(Duration(seconds: 10));

          if (lastUpdateResponse.statusCode == 200) {
            final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
            final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);
            final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
            
            bool needsUpdate = !lastExecutionDate.isAtSameMomentAs(lastUpdateDate);
            if (!needsUpdate) {
              debugPrint("✅ Données YAM Market déjà à jour selon le serveur");
            }
            return needsUpdate;
          }
        } catch (e) {
          debugPrint("⚠️ Erreur vérification timestamp serveur YAM Market: $e");
        }
        return false; // En cas d'erreur, ne pas forcer la mise à jour
      },
      apiCall: () async {
        // Récupérer les nouvelles données YAM
        final response = await http.get(
          Uri.parse('${Parameters.realTokensUrl}/get_yam_offers_mobileapps')
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Sauvegarder le timestamp serveur spécifique à YAM Market
          try {
            final lastUpdateResponse = await http.get(
              Uri.parse('${Parameters.realTokensUrl}/last_update_yam_offers_mobileapps')
            ).timeout(Duration(seconds: 5));
            
            if (lastUpdateResponse.statusCode == 200) {
              final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
              await box.put('lastUpdateTime_YamMarket', lastUpdateDateString);
            }
          } catch (e) {
            debugPrint("⚠️ Erreur sauvegarde timestamp YAM Market: $e");
          }
          
          debugPrint("💾 YAM Market mis à jour: ${data.length} offres");
          return data;
        } else {
          throw Exception("Erreur HTTP ${response.statusCode} lors de la récupération du YAM Market");
        }
      },
    );
  }
  // Récupérer les données de loyer pour chaque wallet et les fusionner avec cache

  static Future<List<Map<String, dynamic>>> fetchRentData({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wallets = prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      return []; // Ne pas exécuter si la liste des wallets est vide
    }

    final box = Hive.box('realTokens');
    
    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedRentData',
      debugName: "Rent Data",
      forceFetch: forceFetch,
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      customCacheDuration: Duration(hours: 1), // Cache plus court pour les loyers
      shouldUpdate: () async {
        // Logique spécifique : vérifier les erreurs 429 et jour de la semaine
        if (forceFetch) return true;
        
        final DateTime now = DateTime.now();
        
        // Vérifier si une réponse 429 a été reçue récemment
        final last429Time = box.get('lastRent429Time');
        if (last429Time != null) {
          final DateTime last429 = DateTime.parse(last429Time);
          if (now.difference(last429) < Duration(minutes: 5)) {
            debugPrint('⚠️ 429 reçu récemment, attente de 5 minutes avant nouvelle requête');
            return false;
          }
        }

        // Vérification du jour de la semaine et de la date de dernière mise à jour
        final lastFetchTime = box.get('lastRentFetchTime');
        final lastSuccessfulFetch = box.get('lastSuccessfulRentFetch');
        
        // Si pas de cache du tout, on peut fetch à tout moment
        if (lastFetchTime == null && lastSuccessfulFetch == null) {
          debugPrint("✅ Pas de cache, fetch autorisé à tout moment");
          return true;
        }

        // Calculer le début de la semaine actuelle (lundi)
        final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final DateTime startOfCurrentWeekMidnight = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
        
        // Vérifier si on a déjà un fetch réussi cette semaine
        if (lastSuccessfulFetch != null) {
          final DateTime lastSuccess = DateTime.parse(lastSuccessfulFetch);
          if (lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
            debugPrint("🛑 Fetch déjà réussi cette semaine (${lastSuccess.toIso8601String()})");
            return false;
          }
        }

        // Vérifier si aujourd'hui est mardi (jour 2 de la semaine)
        final bool isTuesday = now.weekday == DateTime.tuesday;
        
        if (!isTuesday) {
          debugPrint("🛑 Pas mardi, fetch non autorisé (jour ${now.weekday})");
          return false;
        }

        // Si c'est mardi et qu'on n'a pas de fetch réussi cette semaine
        debugPrint("✅ Mardi et pas de fetch réussi cette semaine, fetch autorisé");
        return true;
      },
      apiCall: () async {
        final DateTime now = DateTime.now();
        List<Map<String, dynamic>> mergedRentData = [];
        bool hasError = false;

        debugPrint("🚀 Lancement des requêtes pour ${wallets.length} wallets");

        for (String wallet in wallets) {
          final url = '${Parameters.rentTrackerUrl}/rent_holder/$wallet';
          
          try {
            final response = await http.get(Uri.parse(url))
                .timeout(Duration(seconds: 20));

            // Si on reçoit un code 429, sauvegarder l'heure et arrêter
            if (response.statusCode == 429) {
              debugPrint('⚠️ 429 Too Many Requests pour le wallet $wallet - pause de 5 minutes');
              await box.put('lastRent429Time', now.toIso8601String());
              hasError = true;
              break;
            }

            if (response.statusCode == 200) {
              debugPrint("✅ RentTracker, requête réussie pour $wallet");

              List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(
                json.decode(response.body)
              );
              
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
                    'date': updatedDate,
                    'rent': rentEntry['rent'] ?? 0,
                  });
                }
              }
            } else {
              debugPrint('❌ Erreur HTTP ${response.statusCode} pour le wallet: $wallet');
              hasError = true;
              break;
            }
          } catch (e) {
            debugPrint('❌ Exception pour le wallet $wallet: $e');
            hasError = true;
            break;
          }
        }

        // En cas d'erreur, lever une exception pour utiliser le fallback cache
        if (hasError) {
          throw Exception("Erreurs rencontrées lors de la récupération des données de loyer");
        }

        // Trier les données par date
        mergedRentData.sort((a, b) => a['date'].compareTo(b['date']));

        // Sauvegarder le timestamp spécifique pour les loyers
        if (mergedRentData.isNotEmpty) {
          await box.put('lastRentFetchTime', now.toIso8601String());
          await box.put('lastSuccessfulRentFetch', now.toIso8601String()); // Marquer le succès
          debugPrint("✅ ${mergedRentData.length} entrées de loyer récupérées avec succès");
        }

        return mergedRentData;
      },
    );
  }

  static Future<List<Map<String, dynamic>>> fetchWhitelistTokens({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wallets = prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      return []; // Pas d'exécution si aucun wallet n'est renseigné
    }

    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedWhitelistData',
      debugName: "Whitelist Tokens",
      forceFetch: forceFetch,
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        final box = Hive.box('realTokens');
        final DateTime now = DateTime.now();
        List<Map<String, dynamic>> mergedWhitelistTokens = [];

        debugPrint("🚀 Récupération des tokens whitelistés pour ${wallets.length} wallets");

        // Parcourir chaque wallet pour récupérer ses tokens whitelistés
        for (String wallet in wallets) {
          final url = '${Parameters.rentTrackerUrl}/whitelist2/$wallet';
          
          try {
            final response = await http.get(Uri.parse(url))
                .timeout(Duration(seconds: 15));

            // En cas de code 429, sauvegarder l'heure et interrompre la boucle
            if (response.statusCode == 429) {
              debugPrint('⚠️ 429 Too Many Requests pour wallet: $wallet');
              await box.put('lastWhitelistFetchTime', now.toIso8601String());
              throw Exception("Limite de requêtes atteinte pour les tokens whitelistés");
            }

            if (response.statusCode == 200) {
              debugPrint("✅ Requête réussie pour wallet: $wallet");
              List<Map<String, dynamic>> whitelistData = List<Map<String, dynamic>>.from(
                json.decode(response.body)
              );
              mergedWhitelistTokens.addAll(whitelistData);
            } else {
              debugPrint('❌ Erreur HTTP ${response.statusCode} pour wallet: $wallet');
              throw Exception('Impossible de récupérer les tokens whitelistés pour wallet: $wallet');
            }
          } catch (e) {
            debugPrint('❌ Exception pour wallet $wallet: $e');
            throw e;
          }
        }

        // Sauvegarder le timestamp spécifique pour les tokens whitelistés
        await box.put('lastWhitelistFetchTime', now.toIso8601String());
        debugPrint("✅ ${mergedWhitelistTokens.length} tokens whitelistés récupérés");

        return mergedWhitelistTokens;
      },
    );
  }

  static Future<Map<String, dynamic>> fetchCurrencies({bool forceFetch = false}) async {
    return _fetchWithCache<Map<String, dynamic>>(
      cacheKey: 'cachedCurrencies',
      debugName: "Currencies",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 1), // 1 heure pour les devises
      fromJson: (data) => Map<String, dynamic>.from(data),
      toJson: (data) => data,
      emptyValue: <String, dynamic>{},
      apiCall: () async {
        debugPrint("🔄 Récupération des devises depuis CoinGecko");
        
        final response = await http.get(Uri.parse(Parameters.coingeckoUrl))
            .timeout(Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final currencies = data['market_data']['current_price'] as Map<String, dynamic>;
          
          debugPrint("✅ ${currencies.length} devises récupérées");
          return currencies;
        } else {
          throw Exception('Erreur HTTP ${response.statusCode} lors de la récupération des devises');
        }
      },
    );
  }
  // Récupérer le userId associé à une adresse Ethereum

  static Future<List<Map<String, dynamic>>> fetchRmmBalances({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ Aucun wallet renseigné pour RMM Balances");
      return [];
    }

    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedRmmBalances',
      debugName: "RMM Balances",
      forceFetch: forceFetch,
      customCacheDuration: Duration(minutes: 15), // Cache plus court pour les balances
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        // Contrats pour USDC & XDAI (dépôt et emprunt)
        const String usdcDepositContract = '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1';
        const String usdcBorrowContract = '0x69c731ae5f5356a779f44c355abb685d84e5e9e6';
        const String xdaiDepositContract = '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b';
        const String xdaiBorrowContract = '0x9908801df7902675c3fedd6fea0294d18d5d5d34';

        // Contrats pour USDC & XDAI sur Gnosis
        const String gnosisUsdcContract = '0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83';
        const String gnosisRegContract = '0x0aa1e96d2a46ec6beb2923de1e61addf5f5f1dce';
        const String gnosisVaultRegContract = '0xe1877d33471e37fe0f62d20e60c469eff83fb4a0';

        List<Map<String, dynamic>> allBalances = [];

        debugPrint("🔄 Récupération des balances RMM pour ${evmAddresses.length} wallets");

        for (var address in evmAddresses) {
          try {
            // Requêtes pour tous les contrats
            final futures = await Future.wait([
              _fetchBalance(usdcDepositContract, address, forceFetch: forceFetch),
              _fetchBalance(usdcBorrowContract, address, forceFetch: forceFetch),
              _fetchBalance(xdaiDepositContract, address, forceFetch: forceFetch),
              _fetchBalance(xdaiBorrowContract, address, forceFetch: forceFetch),
              _fetchBalance(gnosisUsdcContract, address, forceFetch: forceFetch),
              _fetchBalance(gnosisRegContract, address, forceFetch: forceFetch),
              _fetchVaultBalance(gnosisVaultRegContract, address, forceFetch: forceFetch),
              _fetchNativeBalance(address, forceFetch: forceFetch),
            ]);

            final [
              usdcDepositResponse,
              usdcBorrowResponse,
              xdaiDepositResponse,
              xdaiBorrowResponse,
              gnosisUsdcResponse,
              gnosisRegResponse,
              gnosisVaultRegResponse,
              gnosisXdaiResponse,
            ] = futures;

            // Vérification que toutes les requêtes ont retourné une valeur
            if (usdcDepositResponse != null && usdcBorrowResponse != null && 
                xdaiDepositResponse != null && xdaiBorrowResponse != null && 
                gnosisUsdcResponse != null && gnosisXdaiResponse != null) {
              
              final timestamp = DateTime.now().toIso8601String();

              // Conversion des balances en double (USDC : 6 décimales, XDAI : 18 décimales)
              double usdcDepositBalance = (usdcDepositResponse / BigInt.from(1e6));
              double usdcBorrowBalance = (usdcBorrowResponse / BigInt.from(1e6));
              double xdaiDepositBalance = (xdaiDepositResponse / BigInt.from(1e18));
              double xdaiBorrowBalance = (xdaiBorrowResponse / BigInt.from(1e18));
              double gnosisUsdcBalance = (gnosisUsdcResponse / BigInt.from(1e6));
              double gnosisRegBalance = ((gnosisRegResponse ?? BigInt.zero)) / BigInt.from(1e18);
              double gnosisVaultRegBalance = ((gnosisVaultRegResponse ?? BigInt.zero)) / BigInt.from(1e18);
              double gnosisXdaiBalance = (gnosisXdaiResponse / BigInt.from(1e18));

              // Ajout des données dans la liste
              allBalances.add({
                'address': address,
                'usdcDepositBalance': usdcDepositBalance,
                'usdcBorrowBalance': usdcBorrowBalance,
                'xdaiDepositBalance': xdaiDepositBalance,
                'xdaiBorrowBalance': xdaiBorrowBalance,
                'gnosisUsdcBalance': gnosisUsdcBalance,
                'gnosisRegBalance': gnosisRegBalance,
                'gnosisVaultRegBalance': gnosisVaultRegBalance,
                'gnosisXdaiBalance': gnosisXdaiBalance,
                'timestamp': timestamp,
              });

              debugPrint("✅ Balances RMM récupérées pour wallet: $address");
            } else {
              debugPrint("❌ Échec récupération balances pour wallet: $address");
              throw Exception('Failed to fetch balances for address: $address');
            }
          } catch (e) {
            debugPrint("❌ Exception balances pour wallet $address: $e");
            throw e;
          }
        }

        debugPrint("✅ ${allBalances.length} balances RMM récupérées au total");
        return allBalances;
      },
    );
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
        debugPrint("🚀 apiService: RPC gnosis -> $contract balance récupérée: $balance");
        await box.put(cacheKey, balance.toString());
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        box.put('lastExecutionTime_Balances', now.toIso8601String());

        return balance;
      } else {
         debugPrint("apiService: RPC gnosis -> Invalid response for contract $contract: $result");
      }
    } else {
       debugPrint('apiService: RPC gnosis -> Failed to fetch balance for contract $contract. Status code: ${response.statusCode}');
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

static Future<BigInt?> _fetchVaultBalance(String contract, String address, {bool forceFetch = false}) async {
  final String cacheKey = 'cachedVaultBalance_${contract}_$address';
  final box = await Hive.openBox('balanceCache');
  final now = DateTime.now();

  final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        debugPrint("🛑 apiService: fetchVaultBalance -> Requête annulée, cache valide");
        return BigInt.tryParse(cachedData);
      }
    }
  }

  // Construire la data : 0xf262a083 + adresse paddée (sans '0x', alignée sur 32 bytes)
  final String functionSelector = 'f262a083';
  final String paddedAddress = address.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
  final String data = '0x$functionSelector$paddedAddress';

  final response = await http.post(
    Uri.parse('https://rpc.gnosischain.com'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {"to": contract, "data": data},
        "latest"
      ],
      "id": 1
    }),
  );

  if (response.statusCode == 200) {
    final responseBody = json.decode(response.body);
    final result = responseBody['result'];

    debugPrint("🚀 apiService: fetchVaultBalance -> Requête lancée");

    if (result != null && result != "0x" && result.length >= 66) {
      // On suppose que le solde est dans le 1er mot (64 caractères hex après le "0x")
      final String balanceHex = result.substring(2, 66);
      final balance = BigInt.parse(balanceHex, radix: 16);

      debugPrint("✅ apiService: fetchVaultBalance -> Balance récupérée: $balance");
      await box.put(cacheKey, balance.toString());
      await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
      box.put('lastExecutionTime_Balances', now.toIso8601String());

      return balance;
    } else {
      debugPrint("⚠️ apiService: fetchVaultBalance -> Résultat invalide pour $contract: $result");
    }
  } else {
    debugPrint('❌ apiService: fetchVaultBalance -> Échec HTTP. Code: ${response.statusCode}');
  }

  return null;
}

  // Nouvelle méthode pour récupérer les détails des loyers
  static Future<List<Map<String, dynamic>>> fetchDetailedRentDataForAllWallets({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    debugPrint("📋 ${evmAddresses.length} wallets à consulter: ${evmAddresses.join(', ')}");

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ Aucun wallet renseigné pour les données détaillées de loyer");
      return [];
    }

    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedDetailedRentDataAll',
      debugName: "Detailed Rent Data",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 2), // Cache plus court pour données détaillées
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      shouldUpdate: () async {
        // Logique spécifique : jour de la semaine (mardi) et vérification par wallet
        if (forceFetch) return true;
        
        final DateTime now = DateTime.now();
        final box = await Hive.openBox('detailedRentData');
        final lastSuccessfulDetailedFetch = box.get('lastSuccessfulDetailedRentFetch');
        
        // Si pas de cache du tout, on peut fetch à tout moment
        if (lastSuccessfulDetailedFetch == null) {
          bool hasAnyCache = false;
          for (var walletAddress in evmAddresses) {
            if (box.get('cachedDetailedRentData_$walletAddress') != null) {
              hasAnyCache = true;
              break;
            }
          }
          if (!hasAnyCache) {
            debugPrint("✅ Pas de cache détaillé, fetch autorisé à tout moment");
            return true;
          }
        }

        // Calculer le début de la semaine actuelle (lundi)
        final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final DateTime startOfCurrentWeekMidnight = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
        
        // Vérifier si on a déjà un fetch réussi cette semaine
        if (lastSuccessfulDetailedFetch != null) {
          final DateTime lastSuccess = DateTime.parse(lastSuccessfulDetailedFetch);
          if (lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
            debugPrint("🛑 Fetch détaillé déjà réussi cette semaine (${lastSuccess.toIso8601String()})");
            return false;
          }
        }

        // Vérifier si aujourd'hui est mardi (jour 2 de la semaine)
        final bool isTuesday = now.weekday == DateTime.tuesday;
        
        if (!isTuesday) {
          debugPrint("🛑 Pas mardi, fetch détaillé non autorisé (jour ${now.weekday})");
          return false;
        }

        // Si c'est mardi et qu'on n'a pas de fetch réussi cette semaine
        debugPrint("✅ Mardi et pas de fetch détaillé réussi cette semaine, fetch autorisé");
        return true;
      },
      apiCall: () async {
        final box = await Hive.openBox('detailedRentData');
        final DateTime now = DateTime.now();
        List<Map<String, dynamic>> allRentData = [];

        // Boucle pour chaque adresse de wallet
        for (var walletAddress in evmAddresses) {
          debugPrint("🔄 Traitement du wallet: $walletAddress");
          
          try {
            final url = '${Parameters.rentTrackerUrl}/detailed_rent_holder/$walletAddress';
            debugPrint("🌐 Tentative de requête API pour $walletAddress");

            final response = await http.get(Uri.parse(url))
                .timeout(Duration(minutes: 2), onTimeout: () {
              throw TimeoutException('Timeout après 2 minutes pour le wallet $walletAddress');
            });

            // Si on reçoit un code 429, charger le cache et arrêter
            if (response.statusCode == 429) {
              debugPrint('⚠️ 429 Too Many Requests pour le wallet $walletAddress - pause de 5 minutes');
              await _loadFromCacheOptimized(box, walletAddress, allRentData);
              break;
            }

            // Si la requête réussit
            if (response.statusCode == 200) {
              final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(
                json.decode(response.body)
              );

              // Ajouter l'adresse du wallet à chaque entrée
              for (var entry in rentData) {
                entry['wallet'] = walletAddress;
              }

              // Sauvegarder dans le cache spécifique du wallet
              await box.put('cachedDetailedRentData_$walletAddress', json.encode(rentData));
              await box.put('lastDetailedRentFetchTime_$walletAddress', now.toIso8601String());
              
              debugPrint("✅ Requête réussie pour $walletAddress, ${rentData.length} entrées obtenues");
              allRentData.addAll(rentData);
            } else {
              debugPrint('❌ Échec requête pour $walletAddress: ${response.statusCode}');
              await _loadFromCacheOptimized(box, walletAddress, allRentData);
            }
          } catch (e) {
            debugPrint('❌ Erreur requête HTTP pour $walletAddress: $e');
            await _loadFromCacheOptimized(box, walletAddress, allRentData);
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
          debugPrint('⚠️ $entriesSansWallet entrées sans wallet assignées à "unknown"');
        }

        await box.put('lastExecutionTime_Rents', now.toIso8601String());

        // Marquer le succès seulement si on a récupéré des données pour au moins un wallet
        if (allRentData.isNotEmpty) {
          await box.put('lastSuccessfulDetailedRentFetch', now.toIso8601String());
          debugPrint('✅ Fetch détaillé réussi, marqué pour cette semaine');
        }

        debugPrint('✅ Fin du traitement - ${allRentData.length} entrées de données de loyer au total');

        // Comptage des entrées par wallet
        Map<String, int> entriesPerWallet = {};
        for (var entry in allRentData) {
          String wallet = entry['wallet'];
          entriesPerWallet[wallet] = (entriesPerWallet[wallet] ?? 0) + 1;
        }
        entriesPerWallet.forEach((wallet, count) {
          debugPrint('📊 Wallet $wallet - $count entrées');
        });

        return allRentData;
      },
    );
  }

  // Méthode utilitaire pour charger les données du cache (version optimisée async)
  static Future<void> _loadFromCacheOptimized(Box box, String walletAddress, List<Map<String, dynamic>> allRentData) async {
    debugPrint('🔄 Tentative de chargement du cache pour $walletAddress');
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
        debugPrint("✅ Données de loyer chargées du cache pour $walletAddress (${rentData.length} entrées)");
      } catch (e) {
        debugPrint('❌ Erreur lors du chargement des données en cache pour $walletAddress: $e');
      }
    } else {
      debugPrint('⚠️ Pas de données en cache pour le wallet $walletAddress');
    }
  }

  // Méthode utilitaire pour charger les données du cache (version synchrone pour compatibilité)
  static void _loadFromCache(Box box, String walletAddress, List<Map<String, dynamic>> allRentData) {
    debugPrint('🔄 Tentative de chargement du cache pour $walletAddress');
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
        debugPrint("✅ Données de loyer chargées du cache pour $walletAddress (${rentData.length} entrées)");
      } catch (e) {
        debugPrint('❌ Erreur lors du chargement des données en cache pour $walletAddress: $e');
      }
    } else {
      debugPrint('⚠️ Pas de données en cache pour le wallet $walletAddress');
    }
  }

  // Nouvelle méthode pour récupérer les propriétés en cours de vente
  static Future<List<Map<String, dynamic>>> fetchPropertiesForSale({bool forceFetch = false}) async {
    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedPropertiesForSale',
      debugName: "Properties For Sale",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 6), // Cache de 6 heures pour les propriétés en vente
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        const url = 'https://realt.co/wp-json/realt/v1/products/for_sale';
        
        debugPrint("🔄 Récupération des propriétés en vente");

        final response = await http.get(Uri.parse(url))
            .timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          // Décoder la réponse JSON
          final data = json.decode(response.body);
          
          // Extraire la liste de produits
          final List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(data['products']);
          
          debugPrint("✅ ${properties.length} propriétés en vente récupérées");
          return properties;
        } else {
          throw Exception('Échec de la requête propriétés. Code: ${response.statusCode}');
        }
      },
    );
  }

  static Future<List<dynamic>> fetchTokenVolumes({bool forceFetch = false}) async {
    return _fetchWithCacheList(
      cacheKey: 'cachedTokenVolumesData',
      debugName: "Token Volumes",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 4), // Cache de 4 heures pour les volumes
      apiCall: () async {
        final apiUrl = '${Parameters.mainApiUrl}/tokens_volume/';
        debugPrint("🔄 Récupération des volumes de tokens");
        
        final response = await http.get(Uri.parse(apiUrl))
            .timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint("✅ Volumes de tokens récupérés");
          return data;
        } else {
          throw Exception("Échec de la récupération depuis FastAPI: ${response.statusCode}");
        }
      },
    );
  }

  static Future<List<dynamic>> fetchTransactionsHistory({bool forceFetch = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    return _fetchWithCacheList(
      cacheKey: 'cachedTransactionsData_transactions_history',
      debugName: "Transactions History",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 3), // Cache de 3 heures pour l'historique
      apiCall: () async {
        List<dynamic> allTransactions = [];
        int successCount = 0;
        int errorCount = 0;

        debugPrint("🔄 Récupération de l'historique des transactions pour ${evmAddresses.length} wallets");

        for (String wallet in evmAddresses) {
          final apiUrl = '${Parameters.mainApiUrl}/transactions_history/$wallet';
          
          try {
            final response = await http.get(Uri.parse(apiUrl))
                .timeout(Duration(seconds: 20));

            if (response.statusCode == 200) {
              final walletData = jsonDecode(response.body);
              allTransactions.addAll(walletData);
              successCount++;
              debugPrint("✅ Transactions récupérées pour wallet: $wallet");
            } else {
              errorCount++;
              debugPrint("⚠️ Erreur récupération transactions pour wallet: $wallet (HTTP ${response.statusCode})");
            }
          } catch (e) {
            errorCount++;
            debugPrint("❌ Exception récupération transactions pour wallet $wallet: $e");
          }
        }

        debugPrint("📊 Récapitulatif transactions: $successCount wallets réussis, $errorCount en erreur");
        debugPrint("✅ ${allTransactions.length} transactions récupérées au total");

        return allTransactions;
      },
    );
  }

  static Future<List<dynamic>> fetchYamWalletsTransactions({bool forceFetch = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    return _fetchWithCacheList(
      cacheKey: 'cachedTransactionsData_yam_wallet_transactions',
      debugName: "YAM Wallets Transactions",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 3), // Cache de 3 heures pour les transactions YAM
      apiCall: () async {
        List<dynamic> allYamTransactions = [];
        int successCount = 0;
        int errorCount = 0;

        debugPrint("🔄 Récupération des transactions YAM pour ${evmAddresses.length} wallets");

        for (String wallet in evmAddresses) {
          final apiUrl = '${Parameters.mainApiUrl}/YAM_transactions_history/$wallet';
          
          try {
            final response = await http.get(Uri.parse(apiUrl))
                .timeout(Duration(seconds: 20));

            if (response.statusCode == 200) {
              final walletData = jsonDecode(response.body);
              allYamTransactions.addAll(walletData);
              successCount++;
              debugPrint("✅ Transactions YAM récupérées pour wallet: $wallet");
            } else {
              errorCount++;
              debugPrint("⚠️ Erreur récupération transactions YAM pour wallet: $wallet (HTTP ${response.statusCode})");
            }
          } catch (e) {
            errorCount++;
            debugPrint("❌ Exception récupération transactions YAM pour wallet $wallet: $e");
          }
        }

        debugPrint("📊 Récapitulatif transactions YAM: $successCount wallets réussis, $errorCount en erreur");
        debugPrint("✅ ${allYamTransactions.length} transactions YAM récupérées au total");

        return allYamTransactions;
      },
    );
  }

  static Future<List<Map<String, dynamic>>> fetchRmmBalancesForAddress(String address, {bool forceFetch = false}) async {
    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedRmmBalancesForAddress_$address',
      debugName: "RMM Balances for $address",
      forceFetch: forceFetch,
      customCacheDuration: Duration(minutes: 15), // Cache court pour les balances individuelles
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        // Contrats pour USDC & XDAI (dépôt et emprunt)
        const String usdcDepositContract = '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1';
        const String usdcBorrowContract = '0x69c731ae5f5356a779f44c355abb685d84e5e9e6';
        const String xdaiDepositContract = '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b';
        const String xdaiBorrowContract = '0x9908801df7902675c3fedd6fea0294d18d5d5d34';
        const String gnosisUsdcContract = '0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83';
        const String gnosisRegContract = '0x0aa1e96d2a46ec6beb2923de1e61addf5f5f1dce';
        const String gnosisVaultRegContract = '0xe1877d33471e37fe0f62d20e60c469eff83fb4a0';

        debugPrint("🔄 Récupération des balances RMM pour l'adresse: $address");

        // Requêtes parallèles pour tous les contrats
        final futures = await Future.wait([
          _fetchBalance(usdcDepositContract, address, forceFetch: forceFetch),
          _fetchBalance(usdcBorrowContract, address, forceFetch: forceFetch),
          _fetchBalance(xdaiDepositContract, address, forceFetch: forceFetch),
          _fetchBalance(xdaiBorrowContract, address, forceFetch: forceFetch),
          _fetchBalance(gnosisUsdcContract, address, forceFetch: forceFetch),
          _fetchBalance(gnosisRegContract, address, forceFetch: forceFetch),
          _fetchVaultBalance(gnosisVaultRegContract, address, forceFetch: forceFetch),
          _fetchNativeBalance(address, forceFetch: forceFetch),
        ]);

        final [
          usdcDepositResponse,
          usdcBorrowResponse,
          xdaiDepositResponse,
          xdaiBorrowResponse,
          gnosisUsdcResponse,
          gnosisRegResponse,
          gnosisVaultRegResponse,
          gnosisXdaiResponse,
        ] = futures;

        if (usdcDepositResponse != null && usdcBorrowResponse != null && 
            xdaiDepositResponse != null && xdaiBorrowResponse != null && 
            gnosisUsdcResponse != null && gnosisXdaiResponse != null) {
          
          final timestamp = DateTime.now().toIso8601String();
          double usdcDepositBalance = (usdcDepositResponse / BigInt.from(1e6));
          double usdcBorrowBalance = (usdcBorrowResponse / BigInt.from(1e6));
          double xdaiDepositBalance = (xdaiDepositResponse / BigInt.from(1e18));
          double xdaiBorrowBalance = (xdaiBorrowResponse / BigInt.from(1e18));
          double gnosisUsdcBalance = (gnosisUsdcResponse / BigInt.from(1e6));
          double gnosisRegBalance = ((gnosisRegResponse ?? BigInt.zero)) / BigInt.from(1e18);
          double gnosisVaultRegBalance = ((gnosisVaultRegResponse ?? BigInt.zero)) / BigInt.from(1e18);
          double gnosisXdaiBalance = (gnosisXdaiResponse / BigInt.from(1e18));
          
          debugPrint("✅ Balances RMM récupérées pour l'adresse: $address");
          
          return [
            {
              'address': address,
              'usdcDepositBalance': usdcDepositBalance,
              'usdcBorrowBalance': usdcBorrowBalance,
              'xdaiDepositBalance': xdaiDepositBalance,
              'xdaiBorrowBalance': xdaiBorrowBalance,
              'gnosisUsdcBalance': gnosisUsdcBalance,
              'gnosisRegBalance': gnosisRegBalance,
              'gnosisVaultRegBalance': gnosisVaultRegBalance,
              'gnosisXdaiBalance': gnosisXdaiBalance,
              'timestamp': timestamp,
            }
          ];
        } else {
          throw Exception('Failed to fetch balances for address: $address');
        }
      },
    );
  }
}
