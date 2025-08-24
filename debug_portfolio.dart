import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> debugPortfolio() async {
  final prefs = await SharedPreferences.getInstance();
  final portfolioJson = prefs.getString('local_portfolio');

  print('🔍 Debug Portfolio Data:');
  print('Raw JSON: $portfolioJson');

  if (portfolioJson != null && portfolioJson.isNotEmpty) {
    try {
      final List<dynamic> portfolioList = jsonDecode(portfolioJson);
      print('📊 Portfolio Count: ${portfolioList.length}');

      for (int i = 0; i < portfolioList.length; i++) {
        final item = portfolioList[i];
        print('🏠 Property $i:');
        print('  - Title: ${item['title']}');
        print('  - ShortName: ${item['shortName']}');
        print('  - ImageUrl: ${item['imageUrl']}');
        print('  - PropertyId: ${item['propertyId']}');
        print('  - Country: ${item['country']}');
        print('  - City: ${item['city']}');
        print('  - TokenAmount: ${item['tokenAmount']}');
        print('  - TokenPrice: ${item['tokenPrice']}');
        print('  - TotalValue: ${item['totalValue']}');
        print('---');
      }
    } catch (e) {
      print('❌ Error parsing portfolio: $e');
    }
  } else {
    print('⚠️ No portfolio data found');
  }
}

void main() async {
  await debugPortfolio();
}
