import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meprop_asset_tracker/managers/data_manager.dart';

class LocalPortfolioService {
  static const String _portfolioKey = 'local_portfolio';

  // ذخیره خرید جدید
  static Future<void> addPurchase({
    required String propertyId,
    required String shortName,
    required String title,
    required double tokenAmount,
    required double tokenPrice,
    required String imageUrl,
    required String country,
    required String city,
    required double annualYield,
    required DateTime purchaseDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // دریافت پورتفولیوی فعلی
    final currentPortfolio = await getPortfolio();

    // بررسی اینکه آیا این پروپرتی قبلاً خریداری شده یا نه
    final existingIndex = currentPortfolio.indexWhere(
      (item) => item['propertyId'] == propertyId,
    );

    if (existingIndex != -1) {
      // اگر موجود است، مقدار توکن‌ها را اضافه کنید
      currentPortfolio[existingIndex]['tokenAmount'] =
          (currentPortfolio[existingIndex]['tokenAmount'] as double) + tokenAmount;
      currentPortfolio[existingIndex]['lastPurchaseDate'] = purchaseDate.toIso8601String();
    } else {
      // اگر موجود نیست، آیتم جدید اضافه کنید
      final newPurchase = {
        'propertyId': propertyId,
        'shortName': shortName,
        'title': title,
        'tokenAmount': tokenAmount,
        'tokenPrice': tokenPrice,
        'totalValue': tokenAmount * tokenPrice,
        'imageUrl': imageUrl,
        'country': country,
        'city': city,
        'annualYield': annualYield,
        'purchaseDate': purchaseDate.toIso8601String(),
        'lastPurchaseDate': purchaseDate.toIso8601String(),
      };

      currentPortfolio.add(newPurchase);
    }

    // ذخیره پورتفولیوی به‌روزشده
    await prefs.setString(_portfolioKey, jsonEncode(currentPortfolio));

    // به‌روزرسانی داده‌های Russell اگر کاربر فعلی Russell باشد
    await DataManager().updateRussellDataIfNeeded();
  }

  // دریافت تمام خریدها
  static Future<List<Map<String, dynamic>>> getPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final portfolioJson = prefs.getString(_portfolioKey);

    if (portfolioJson == null || portfolioJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> portfolioList = jsonDecode(portfolioJson);
      return portfolioList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // فروش یا کاهش مقدار توکن‌ها
  static Future<void> sellTokens({
    required String propertyId,
    required double sellAmount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPortfolio = await getPortfolio();

    final existingIndex = currentPortfolio.indexWhere(
      (item) => item['propertyId'] == propertyId,
    );

    if (existingIndex != -1) {
      final currentAmount = currentPortfolio[existingIndex]['tokenAmount'] as double;
      final newAmount = currentAmount - sellAmount;

      if (newAmount <= 0) {
        // اگر همه توکن‌ها فروخته شود، آیتم را حذف کنید
        currentPortfolio.removeAt(existingIndex);
      } else {
        // مقدار جدید را به‌روزرسانی کنید
        currentPortfolio[existingIndex]['tokenAmount'] = newAmount;
        currentPortfolio[existingIndex]['totalValue'] =
            newAmount * (currentPortfolio[existingIndex]['tokenPrice'] as double);
      }

      // ذخیره پورتفولیوی به‌روزشده
      await prefs.setString(_portfolioKey, jsonEncode(currentPortfolio));

      // به‌روزرسانی داده‌های Russell اگر کاربر فعلی Russell باشد
      await DataManager().updateRussellDataIfNeeded();
    }
  }

  // حذف کامل یک پراپرتی
  static Future<void> removeProperty(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPortfolio = await getPortfolio();

    currentPortfolio.removeWhere((item) => item['propertyId'] == propertyId);

    await prefs.setString(_portfolioKey, jsonEncode(currentPortfolio));
  }

  // پاک کردن کل پورتفولیو
  static Future<void> clearPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_portfolioKey);
  }

  // دریافت ارزش کل پورتفولیو
  static Future<double> getTotalPortfolioValue() async {
    final portfolio = await getPortfolio();
    double total = 0.0;

    for (final item in portfolio) {
      total += (item['totalValue'] as double? ?? 0.0);
    }

    return total;
  }
}
