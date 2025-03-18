import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/models/apy_record.dart';

/// Gestionnaire dédié aux calculs et au suivi de l'APY
/// Centralise toutes les méthodes de calcul d'APY, ROI et autres métriques financières
class ApyManager extends ChangeNotifier {
  // Facteur d'alpha pour la moyenne mobile exponentielle (EMA)
  // Plus ce facteur est élevé (max 1.0), plus les valeurs récentes ont du poids
  double emaAlpha = 0.2; // Valeur par défaut, ajustable selon les besoins de réactivité
  
  // Période maximale à considérer pour le calcul de l'APY (en jours)
  int maxHistoryDays = 30; // Valeur par défaut, ajustable
  
  // Valeur initiale de l'investissement pour les calculs de ROI
  double initialInvestment = 0.0;
  
  // Historique des valeurs d'APY
  List<ApyRecord> apyHistory = [];
  
  // Valeur actuelle de l'APY
  double currentApy = 0.0;
  
  // Valeur moyenne de l'APY annuel
  double averageAnnualYield = 0.0;

  /// Constructeur
  ApyManager();

  /// Calcule l'APY entre deux enregistrements avec une tolérance pour les petits changements
  double calculateAPY(BalanceRecord current, BalanceRecord previous) {
    double initialBalance = previous.balance;
    double finalBalance = current.balance;

    // Vérifier les valeurs invalides
    if (initialBalance <= 0 || finalBalance <= 0) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: balances invalides (init: $initialBalance, final: $finalBalance)");
      }
      return 0;
    }

    // Calculer la différence en pourcentage
    double percentageChange = ((finalBalance - initialBalance) / initialBalance) * 100;

    if (kDebugMode) {
      debugPrint("🔍 Analyse de la paire: ${previous.timestamp} → ${current.timestamp}");
      debugPrint("   Balance initiale: $initialBalance, Balance finale: $finalBalance");
      debugPrint("   Variation: ${percentageChange.toStringAsFixed(5)}%");
    }

    // Ignorer si la différence est trop faible ou nulle (seuil réduit à 0.00001%)
    if (percentageChange.abs() < 0.00001) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: variation trop faible (${percentageChange.toStringAsFixed(5)}%)");
      }
      return 0; // Ne pas prendre en compte cette paire
    }

    // Ignorer si la différence est supérieure à 25% ou inférieure à 0% (dépôt ou retrait)
    if (percentageChange > 25 || percentageChange < 0) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: variation hors limites (${percentageChange.toStringAsFixed(2)}%) - APY négatif ou > 25%");
      }
      return 0; // Ne pas prendre en compte cette paire
    }

    // Calculer la durée en secondes
    double timePeriodInSeconds = current.timestamp.difference(previous.timestamp).inSeconds.toDouble();

    // Si la durée est trop courte (moins d'une minute), ignorer la paire
    if (timePeriodInSeconds < 60) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: intervalle de temps trop court (${timePeriodInSeconds.toStringAsFixed(1)} secondes)");
      }
      return 0;
    }

    // Convertir en années (secondes dans une année = 365 * 24 * 60 * 60)
    double timePeriodInYears = timePeriodInSeconds / (365 * 24 * 60 * 60);

    // Si la période est trop courte, cela peut causer des NaN dans le calcul
    if (timePeriodInYears <= 0) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: période en années trop courte ou négative (${timePeriodInYears.toStringAsFixed(8)})");
      }
      return 0;
    }

    // Calculer l'APY annualisé
    double apy;
    try {
      apy = (math.pow((1 + percentageChange / 100), (1 / timePeriodInYears)) - 1) * 100;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("⚠️ Erreur dans le calcul de l'APY: $e");
      }
      return 0;
    }

    // Vérifier si le résultat est NaN
    if (apy.isNaN) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: APY est NaN");
      }
      return 0;
    }

    // Vérifier que l'APY calculé est dans les limites acceptables
    if (apy <= 0 || apy > 25) {
      if (kDebugMode) {
        debugPrint("⚠️ Paire ignorée: APY hors limites (${apy.toStringAsFixed(2)}%)");
      }
      return 0;
    }

    if (kDebugMode) {
      debugPrint("✅ Paire valide: variation de ${percentageChange.toStringAsFixed(2)}% sur ${(timePeriodInYears * 365).toStringAsFixed(1)} jours → APY: ${apy.toStringAsFixed(2)}%");
    }

    return apy;
  }

  /// Calcule l'APY moyen pour les trois dernières paires valides
  double calculateAPYForLastThreeValidPairs(List<BalanceRecord> history) {
    if (history.length < 2) return 0;

    double totalAPY = 0;
    int count = 0;
    int validPairsFound = 0;

    // Trier l'historique par date décroissante
    List<BalanceRecord> sortedHistory = List.from(history);
    sortedHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Périodes de temps à essayer (en minutes)
    final List<int> timePeriods = [180, 120, 60, 30, 15]; // 3h, 2h, 1h, 30min, 15min

    // Parcourir l'historique pour trouver des paires valides
    for (int i = 0; i < sortedHistory.length - 1 && validPairsFound < 3; i++) {
      for (int j = i + 1; j < sortedHistory.length && validPairsFound < 3; j++) {
        Duration timeDiff = sortedHistory[i].timestamp.difference(sortedHistory[j].timestamp);
        
        // Vérifier si l'intervalle de temps correspond à une des périodes recherchées
        if (timePeriods.contains(timeDiff.inMinutes)) {
          double apy = calculateAPY(sortedHistory[i], sortedHistory[j]);
          // Ne prendre en compte que les paires valides (APY entre 0 et 25% et non NaN)
          if (apy > 0 && apy <= 25 && !apy.isNaN) {
            totalAPY += apy;
            count++;
            validPairsFound++;
            if (kDebugMode) {
              debugPrint("✅ Paire valide trouvée: ${sortedHistory[j].timestamp} → ${sortedHistory[i].timestamp} (${timeDiff.inMinutes}m) → APY: ${apy.toStringAsFixed(2)}%");
            }
            break; // Passer à la prochaine paire de base
          }
        }
      }
    }

    // Retourner la moyenne des APY valides, ou 0 s'il n'y a aucune paire valide
    if (count == 0) return 0;
    
    double result = totalAPY / count;
    
    // Vérification finale pour NaN
    if (result.isNaN) {
      if (kDebugMode) {
        debugPrint("⚠️ calculateAPYForLastThreeValidPairs: Résultat est NaN, retourne 0");
      }
      return 0;
    }
    
    return result;
  }

  /// Calculer la moyenne des APY sur toutes les paires d'enregistrements, en ignorant les dépôts/retraits
  double calculateAverageAPY(List<BalanceRecord> history) {
    double totalAPY = 0;
    int count = 0;

    for (int i = 1; i < history.length; i++) {
      double apy = calculateAPY(history[i], history[i - 1]);
      // Ne prendre en compte que les paires valides (APY entre 0 et 25%)
      if (apy > 0 && apy <= 25) {
        totalAPY += apy;
        count++;
      }
    }
    // Retourner la moyenne des APY valides, ou 0 s'il n'y a aucune paire valide
    return count > 0 ? totalAPY / count : 0;
  }

  /// Calcule l'APY en utilisant une moyenne mobile exponentielle pour donner plus de poids aux valeurs récentes
  /// Tout en continuant à filtrer les dépôts/retraits (valeurs négatives ou trop élevées)
  /// 
  /// [history] : Liste des enregistrements de balance
  /// [alpha] : Facteur de lissage pour l'EMA (entre 0 et 1, plus proche de 1 = plus réactif)
  /// [maxDays] : Limite maximale d'historique à considérer en jours
  double calculateExponentialMovingAverageAPY(
    List<BalanceRecord> history, {
    double? alpha,
    int? maxDays,
  }) {
    // Utiliser les valeurs par défaut si non spécifiées
    final double useAlpha = alpha ?? emaAlpha;
    final int useMaxDays = maxDays ?? maxHistoryDays;
    
    if (history.length < 2) return 0;

    // Filtrer les enregistrements pour ne considérer que ceux des derniers "maxDays" jours
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: useMaxDays));
    final List<BalanceRecord> recentHistory = history
        .where((record) => record.timestamp.isAfter(cutoffDate))
        .toList();

    if (recentHistory.length < 2) return 0;

    // Trier l'historique par date, du plus ancien au plus récent
    recentHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculer l'APY pour chaque paire adjacente d'enregistrements
    List<Map<String, dynamic>> validApyRecords = [];
    for (int i = 1; i < recentHistory.length; i++) {
      double apy = calculateAPY(recentHistory[i], recentHistory[i - 1]);
      
      // Filtrer les APY invalides (négatifs, NaN ou > 25%)
      if (apy > 0 && apy <= 25 && !apy.isNaN) {
        validApyRecords.add({
          'apy': apy,
          'timestamp': recentHistory[i].timestamp,
        });
      }
    }

    if (validApyRecords.isEmpty) return 0;

    // Calculer l'EMA sur les valeurs d'APY valides
    double ema = validApyRecords.first['apy'];
    for (int i = 1; i < validApyRecords.length; i++) {
      ema = useAlpha * validApyRecords[i]['apy'] + (1 - useAlpha) * ema;
    }

    // Vérification finale pour NaN
    if (ema.isNaN) {
      if (kDebugMode) {
        debugPrint("⚠️ calculateExponentialMovingAverageAPY: Résultat EMA est NaN, retourne 0");
      }
      return 0;
    }

    return ema;
  }

  /// Version améliorée du calcul d'APY global tenant compte de la périodicité des enregistrements
  /// Cette méthode donne plus de poids aux paires avec des mesures plus fréquentes
  /// 
  /// [history] : Liste des enregistrements de balance
  /// [maxDays] : Nombre maximum de jours d'historique à prendre en compte
  double calculateWeightedAPY(
    List<BalanceRecord> history, {
    int? maxDays,
  }) {
    final int useMaxDays = maxDays ?? maxHistoryDays;
    
    if (history.length < 2) return 0;

    // Filtrer les enregistrements pour ne considérer que ceux des derniers "maxDays" jours
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: useMaxDays));
    final List<BalanceRecord> recentHistory = history
        .where((record) => record.timestamp.isAfter(cutoffDate))
        .toList();

    if (recentHistory.length < 2) return 0;

    // Trier l'historique par date, du plus ancien au plus récent
    recentHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double weightedSumAPY = 0;
    double totalWeight = 0;

    for (int i = 1; i < recentHistory.length; i++) {
      double apy = calculateAPY(recentHistory[i], recentHistory[i - 1]);
      
      // Ne prendre en compte que les paires valides (APY entre 0 et 25% et non NaN)
      if (apy > 0 && apy <= 25 && !apy.isNaN) {
        // Calculer un poids en fonction de la récence (les plus récents ont plus de poids)
        // et de la durée entre les mesures (les mesures plus rapprochées ont plus de poids)
        final double recencyWeight = math.exp(0.1 * (i - recentHistory.length + 1));
        
        // La durée entre les mesures (en jours) - inversement proportionnelle au poids
        final double durationInDays = recentHistory[i].timestamp
            .difference(recentHistory[i - 1].timestamp)
            .inHours / 24;
        
        // Plus la durée est courte, plus le poids est élevé
        final double frequencyWeight = 1.0 / math.max(1.0, durationInDays);
        
        // Poids combiné
        final double weight = recencyWeight * frequencyWeight;
        
        weightedSumAPY += apy * weight;
        totalWeight += weight;
      }
    }

    // Retourner la moyenne pondérée
    if (totalWeight <= 0) return 0;
    
    double result = weightedSumAPY / totalWeight;
    
    // Vérification finale pour NaN
    if (result.isNaN) {
      if (kDebugMode) {
        debugPrint("⚠️ calculateWeightedAPY: Résultat pondéré est NaN, retourne 0");
      }
      return 0;
    }
    
    return result;
  }

  /// Calcule l'APY global avec la méthode la plus appropriée
  /// 
  /// Cette méthode sélectionne automatiquement le meilleur algorithme en fonction
  /// du volume et de la qualité des données disponibles
  double calculateSmartAPY(List<BalanceRecord> history) {
    if (history.length < 2) return 0;
    
    double result = 0.0;
    
    // Si nous avons beaucoup d'enregistrements, utiliser l'EMA
    if (history.length >= 10) {
      result = calculateExponentialMovingAverageAPY(history);
    }
    // Si nous avons entre 5 et 9 enregistrements, utiliser la méthode pondérée
    else if (history.length >= 5) {
      result = calculateWeightedAPY(history);
    }
    // Pour un petit nombre d'enregistrements, utiliser les 3 dernières paires valides
    else {
      result = calculateAPYForLastThreeValidPairs(history);
    }
    
    // Vérifier si le résultat est NaN et le remplacer par 0 le cas échéant
    if (result.isNaN) {
      if (kDebugMode) {
        debugPrint("⚠️ calculateSmartAPY: Résultat NaN détecté, remplacé par 0.0");
      }
      return 0.0;
    }
    
    return result;
  }

  /// Calcule l'APY net global basé sur les valeurs de dépôt, d'emprunt et les taux respectifs
  /// 
  /// [usdcDepositBalance] : Montant total des dépôts en USDC
  /// [xdaiDepositBalance] : Montant total des dépôts en XDAI
  /// [usdcBorrowBalance] : Montant total des emprunts en USDC
  /// [xdaiBorrowBalance] : Montant total des emprunts en XDAI
  /// [walletValue] : Valeur totale des tokens dans le wallet (optionnel)
  /// [rmmValue] : Valeur totale des tokens en RMM (optionnel)
  double calculateNetGlobalApy({
    required double usdcDepositBalance,
    required double xdaiDepositBalance,
    required double usdcBorrowBalance,
    required double xdaiBorrowBalance,
    double walletValue = 0.0,
    double rmmValue = 0.0,
  }) {
    // Calculer les APY à partir des balances
    double usdcDepositApy = calculateAPY(
      BalanceRecord(
        tokenType: 'usdcDeposit',
        balance: usdcDepositBalance,
        timestamp: DateTime.now(),
      ),
      BalanceRecord(
        tokenType: 'usdcDeposit',
        balance: usdcDepositBalance * 0.99, // Estimation pour le calcul
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    );

    double xdaiDepositApy = calculateAPY(
      BalanceRecord(
        tokenType: 'xdaiDeposit',
        balance: xdaiDepositBalance,
        timestamp: DateTime.now(),
      ),
      BalanceRecord(
        tokenType: 'xdaiDeposit',
        balance: xdaiDepositBalance * 0.99, // Estimation pour le calcul
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    );

    double usdcBorrowApy = calculateAPY(
      BalanceRecord(
        tokenType: 'usdcBorrow',
        balance: usdcBorrowBalance,
        timestamp: DateTime.now(),
      ),
      BalanceRecord(
        tokenType: 'usdcBorrow',
        balance: usdcBorrowBalance * 0.99, // Estimation pour le calcul
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    );

    double xdaiBorrowApy = calculateAPY(
      BalanceRecord(
        tokenType: 'xdaiBorrow',
        balance: xdaiBorrowBalance,
        timestamp: DateTime.now(),
      ),
      BalanceRecord(
        tokenType: 'xdaiBorrow',
        balance: xdaiBorrowBalance * 0.99, // Estimation pour le calcul
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    );

    // Calcul des intérêts gagnés sur les dépôts
    final double usdcDepositInterest = usdcDepositBalance * (usdcDepositApy / 100);
    final double xdaiDepositInterest = xdaiDepositBalance * (xdaiDepositApy / 100);
    final double totalDepositInterest = usdcDepositInterest + xdaiDepositInterest;
    
    // Calcul des intérêts payés sur les emprunts
    final double usdcBorrowInterest = usdcBorrowBalance * (usdcBorrowApy / 100);
    final double xdaiBorrowInterest = xdaiBorrowBalance * (xdaiBorrowApy / 100);
    final double totalBorrowInterest = usdcBorrowInterest + xdaiBorrowInterest;
    
    // Calcul de l'intérêt net
    final double netInterest = totalDepositInterest - totalBorrowInterest;
    
    // Calcul du total des actifs (dépôts)
    final double totalDeposits = usdcDepositBalance + xdaiDepositBalance;
    
    // Calcul de l'APY net
    // Si pas de dépôts, retourner 0 pour éviter une division par zéro
    if (totalDeposits <= 0) {
      return 0.0;
    }
    
    // APY net en pourcentage
    return (netInterest / totalDeposits) * 100;
  }

  /// Méthode pour ajuster les paramètres de calcul d'APY
  /// Permet de régler la réactivité de l'APY en fonction des besoins
  void setApyCalculationParameters({
    double? newEmaAlpha,
    int? newMaxHistoryDays,
  }) {
    if (newEmaAlpha != null) {
      // S'assurer que alpha reste entre 0 et 1
      emaAlpha = newEmaAlpha.clamp(0.0, 1.0);
    }
    
    if (newMaxHistoryDays != null && newMaxHistoryDays > 0) {
      maxHistoryDays = newMaxHistoryDays;
    }
    
    notifyListeners();
  }

  /// Calcule le ROI (Return on Investment) pour un portefeuille
  /// 
  /// [currentValue] : Valeur actuelle du portefeuille
  /// [initialInvestment] : Investissement initial
  /// [timeInYears] : Durée de l'investissement en années
  double calculateRoi({
    required double currentValue,
    required double initialInvestment,
    double timeInYears = 1.0,
  }) {
    if (initialInvestment <= 0) {
      return 0.0;
    }
    
    // Calcul du ROI simple (en pourcentage)
    final double simpleRoi = ((currentValue - initialInvestment) / initialInvestment) * 100;
    
    // Calcul du ROI annualisé si la période est différente d'un an
    if (timeInYears != 1.0 && timeInYears > 0) {
      // Formule du ROI annualisé : (1 + ROI)^(1/temps) - 1
      final double annualizedRoi = (math.pow((1 + simpleRoi / 100), (1 / timeInYears)) - 1) * 100;
      return annualizedRoi;
    }
    
    return simpleRoi;
  }
  
  /// Calcule l'APY pour un wallet spécifique, en tenant compte de ses dépôts et emprunts
  /// 
  /// [wallet] : Map contenant les informations du wallet
  double calculateWalletApy({
    required Map<String, dynamic> wallet,
  }) {
    final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0.0;
    final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0.0;
    final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0.0;
    final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0.0;
    
    return calculateNetGlobalApy(
      usdcDepositBalance: usdcDeposit,
      xdaiDepositBalance: xdaiDeposit,
      usdcBorrowBalance: usdcBorrow,
      xdaiBorrowBalance: xdaiBorrow,
    );
  }

  /// Calcule l'APY pour chaque wallet
  Map<String, double> calculateWalletApys(List<Map<String, dynamic>> wallets) {
    Map<String, double> walletApys = {};
    
    for (var wallet in wallets) {
      final String address = wallet['address'] as String;
      final double apy = calculateWalletApy(wallet: wallet);
      walletApys[address] = apy;
    }
    
    return walletApys;
  }

  /// Détermine la couleur appropriée pour une valeur de ROI ou d'APY
  /// 
  /// [percentage] : Pourcentage de ROI ou d'APY
  /// Retourne une couleur en fonction de la performance
  Color getApyColor(double percentage) {
    if (percentage < 5) {
      return Colors.red;
    } else if (percentage < 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// Cette méthode n'est plus utilisée pour ajouter des éléments à l'historique
  /// Utilisez DataManager.archiveApyValue() à la place qui gère à la fois
  /// la mise à jour en mémoire et la persistance
  @deprecated
  void archiveApyValue(double netApy, double grossApy) {
    // Cette fonctionnalité est maintenant gérée par DataManager
    // qui charge l'historique depuis Hive via loadApyHistory()
    debugPrint("⚠️ Cette méthode est dépréciée. Utilisez DataManager.archiveApyValue() à la place.");
  }
} 