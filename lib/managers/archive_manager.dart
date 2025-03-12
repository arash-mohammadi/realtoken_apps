import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/balance_record.dart';
import '../models/roi_record.dart';
import '../models/apy_record.dart';
import '../models/healthandltv_record.dart';
import '../models/rented_record.dart';

class ArchiveManager {
  static final ArchiveManager _instance = ArchiveManager._internal();
  factory ArchiveManager() => _instance;
  ArchiveManager._internal();

  DateTime? lastArchiveTime;

  Future<void> archiveTotalWalletValue(double totalWalletValue) async {
    var box = Hive.box('walletValueArchive');

    List<dynamic>? balanceHistoryJson =
        box.get('balanceHistory_totalWalletValue');
    List<BalanceRecord> balanceHistory = balanceHistoryJson != null
        ? balanceHistoryJson
            .map((recordJson) =>
                BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson)))
            .toList()
        : [];

    if (balanceHistory.isNotEmpty) {
      BalanceRecord lastRecord = balanceHistory.last;
      DateTime lastTimestamp = lastRecord.timestamp;

      if (DateTime.now().difference(lastTimestamp).inHours < 1) {
        return;
      }
    }

    BalanceRecord newRecord = BalanceRecord(
      tokenType: 'totalWalletValue',
      balance: double.parse(totalWalletValue.toStringAsFixed(3)),
      timestamp: DateTime.now(),
    );
    balanceHistory.add(newRecord);

    List<Map<String, dynamic>> balanceHistoryJsonToSave =
        balanceHistory.map((record) => record.toJson()).toList();
    await box.put('balanceHistory_totalWalletValue', balanceHistoryJsonToSave);
  }

  Future<void> archiveRentedValue(double rentedValue) async {
    try {
      var box = Hive.box('rentedArchive');

      List<dynamic>? rentedHistoryJson = box.get('rented_history');
      List<RentedRecord> rentedHistory = rentedHistoryJson != null
          ? rentedHistoryJson
              .map((recordJson) =>
                  RentedRecord.fromJson(Map<String, dynamic>.from(recordJson)))
              .toList()
          : [];

      if (rentedHistory.isNotEmpty) {
        RentedRecord lastRecord = rentedHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;

        if (DateTime.now().difference(lastTimestamp).inHours < 1) {
          debugPrint(
              'Dernière archive récente, aucun nouvel enregistrement ajouté.');
          return;
        }
      }

      RentedRecord newRecord = RentedRecord(
        percentage: double.parse(rentedValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      rentedHistory.add(newRecord);

      List<Map<String, dynamic>> rentedHistoryJsonToSave =
          rentedHistory.map((record) => record.toJson()).toList();
      await box.put('rented_history', rentedHistoryJsonToSave);
      debugPrint('Nouvel enregistrement ROI ajouté et sauvegardé avec succès.');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage de la valeur ROI : $e');
    }
  }

  Future<void> archiveRoiValue(double roiValue) async {
    try {
      var box = Hive.box('roiValueArchive');

      List<dynamic>? roiHistoryJson = box.get('roi_history');
      List<RoiRecord> roiHistory = roiHistoryJson != null
          ? roiHistoryJson
              .map((recordJson) =>
                  RoiRecord.fromJson(Map<String, dynamic>.from(recordJson)))
              .toList()
          : [];

      if (roiHistory.isNotEmpty) {
        RoiRecord lastRecord = roiHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;

        if (DateTime.now().difference(lastTimestamp).inHours < 1) {
          debugPrint(
              'Dernière archive récente, aucun nouvel enregistrement ajouté.');
          return;
        }
      }

      RoiRecord newRecord = RoiRecord(
        roi: double.parse(roiValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      roiHistory.add(newRecord);

      List<Map<String, dynamic>> roiHistoryJsonToSave =
          roiHistory.map((record) => record.toJson()).toList();
      await box.put('roi_history', roiHistoryJsonToSave);
      debugPrint('Nouvel enregistrement ROI ajouté et sauvegardé avec succès.');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage de la valeur ROI : $e');
    }
  }

  Future<void> archiveApyValue(double netApyValue, double grossApyValue) async {
    try {
      var box = Hive.box('apyValueArchive');

      List<dynamic>? apyHistoryJson = box.get('apy_history');
      List<ApyRecord> apyHistory = apyHistoryJson != null
          ? apyHistoryJson
              .map((recordJson) =>
                  ApyRecord.fromJson(Map<String, dynamic>.from(recordJson)))
              .toList()
          : [];

      if (apyHistory.isNotEmpty) {
        ApyRecord lastRecord = apyHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;

        if (DateTime.now().difference(lastTimestamp).inHours < 1) {
          debugPrint(
              'Dernier enregistrement récent, aucun nouvel enregistrement ajouté.');
          return;
        }
      }

      ApyRecord newRecord = ApyRecord(
        netApy: double.parse(netApyValue.toStringAsFixed(3)),
        grossApy: double.parse(grossApyValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      apyHistory.add(newRecord);

      List<Map<String, dynamic>> apyHistoryJsonToSave =
          apyHistory.map((record) => record.toJson()).toList();
      await box.put('apy_history', apyHistoryJsonToSave);

      debugPrint('Nouvel enregistrement APY ajouté et sauvegardé avec succès.');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage des valeurs APY : $e');
    }
  }

  Future<void> archiveBalance(
      String tokenType, double balance, String timestamp) async {
    try {
      var box = Hive.box('balanceHistory');

      List<dynamic>? balanceHistoryJson = box.get('balanceHistory_$tokenType');
      List<BalanceRecord> balanceHistory = balanceHistoryJson != null
          ? balanceHistoryJson
              .map((recordJson) =>
                  BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson)))
              .toList()
          : [];

      BalanceRecord newRecord = BalanceRecord(
        tokenType: tokenType,
        balance: double.parse(balance.toStringAsFixed(3)),
        timestamp: DateTime.parse(timestamp),
      );

      balanceHistory.add(newRecord);

      List<Map<String, dynamic>> balanceHistoryJsonToSave =
          balanceHistory.map((record) => record.toJson()).toList();
      await box.put('balanceHistory_$tokenType', balanceHistoryJsonToSave);
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'archivage de la balance pour $tokenType : $e');
    }
  }

  Future<void> archiveHealthAndLtvValue(
      double healtFactorValue, double ltvValue) async {
    try {
      var box = Hive.box('HealthAndLtvValueArchive');

      List<dynamic>? healthAndLtvHistoryJson = box.get('healthAndLtv_history');
      List<HealthAndLtvRecord> healthAndLtvHistory =
          healthAndLtvHistoryJson != null
              ? healthAndLtvHistoryJson
                  .map((recordJson) => HealthAndLtvRecord.fromJson(
                      Map<String, dynamic>.from(recordJson)))
                  .toList()
              : [];

      if (healthAndLtvHistory.isNotEmpty) {
        HealthAndLtvRecord lastRecord = healthAndLtvHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;

        if (DateTime.now().difference(lastTimestamp).inHours < 1) {
          debugPrint(
              'Dernier enregistrement récent, aucun nouvel enregistrement ajouté.');
          return;
        }
      }

      HealthAndLtvRecord newRecord = HealthAndLtvRecord(
        healthFactor: double.parse(healtFactorValue.toStringAsFixed(3)),
        ltv: double.parse(ltvValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      healthAndLtvHistory.add(newRecord);

      List<Map<String, dynamic>> healthAndLtvHistoryJsonToSave =
          healthAndLtvHistory.map((record) => record.toJson()).toList();
      await box.put('healthAndLtv_history', healthAndLtvHistoryJsonToSave);

      debugPrint('Nouvel enregistrement APY ajouté et sauvegardé avec succès.');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage des valeurs APY : $e');
    }
  }

  Future<List<BalanceRecord>> getBalanceHistory(String tokenType) async {
    var box = Hive.box('balanceHistory');

    List<dynamic>? balanceHistoryJson = box.get('balanceHistory_$tokenType');
    return balanceHistoryJson!
        .map((recordJson) =>
            BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson)))
        .where((record) => record.tokenType == tokenType)
        .toList();
  }
}
