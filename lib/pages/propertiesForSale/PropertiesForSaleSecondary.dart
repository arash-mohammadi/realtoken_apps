import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/api/data_manager.dart';
import 'package:realtokens/utils/utils.dart';
import 'package:realtokens/generated/l10n.dart';

class PropertiesForSaleSecondary extends StatefulWidget {
  const PropertiesForSaleSecondary({Key? key}) : super(key: key);

  @override
  _PropertiesForSaleSecondaryState createState() => _PropertiesForSaleSecondaryState();
}

class _PropertiesForSaleSecondaryState extends State<PropertiesForSaleSecondary> {
  String? lastUpdateTime;
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Utils.refreshData(context);

    final box = Hive.box('realTokens');
    setState(() {
      lastUpdateTime = box.get('lastUpdateTime_YamMarket') as String?;
    });

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
  }

  Future<void> _refreshData() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await Utils.refreshData(context);
    await dataManager.fetchAndStorePropertiesForSale();

    final box = Hive.box('realTokens');
    setState(() {
      lastUpdateTime = box.get('lastUpdateTime_YamMarket') as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);

    // Filtrer les offres en fonction du champ `shortName`
    final groupedOffers = <String, List<Map<String, dynamic>>>{};
    for (var offer in dataManager.yamMarket) {
      String tokenKey = (offer['token_to_sell'] ?? offer['token_to_buy']) ?? '';
      final shortName = offer['shortName']?.toLowerCase() ?? '';

      if (shortName.contains(searchQuery.toLowerCase())) {
        if (groupedOffers.containsKey(tokenKey)) {
          groupedOffers[tokenKey]!.add(offer);
        } else {
          groupedOffers[tokenKey] = [offer];
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: isSearching
                      ? TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher par nom...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        )
                      : Text(
                          'Dernière mise à jour : ${Utils.formatReadableDateWithTime(lastUpdateTime!)}',
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            color: Colors.grey[600],
                          ),
                        ),
                ),
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      if (isSearching) {
                        searchController.clear();
                      }
                      isSearching = !isSearching;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: groupedOffers.isEmpty
                  ? Center(
                      child: Text(
                        S.of(context).no_market_offers_available,
                        style: TextStyle(fontSize: 16 + appState.getTextSizeOffset()),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedOffers.keys.length,
                      itemBuilder: (context, index) {
                        String tokenKey = groupedOffers.keys.elementAt(index);
                        List<Map<String, dynamic>> offers = groupedOffers[tokenKey]!;
                        final imageUrl = (offers.first['imageLink'] != null && offers.first['imageLink'] is List && offers.first['imageLink'].isNotEmpty)
                            ? offers.first['imageLink'][0]
                            : '';
                        final shortName = offers.first['shortName'] ?? 'N/A';
                        final country = offers.first['country'] ?? 'USA';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  Image.network(
                                    imageUrl,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (country != null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Image.asset(
                                                'assets/country/${country.toLowerCase()}.png',
                                                width: 24,
                                                height: 24,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(Icons.flag, size: 24);
                                                },
                                              ),
                                            ),
                                          Text(
                                            shortName,
                                            style: TextStyle(
                                              fontSize: 18 + appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...offers.map((offer) {
                                  final offerId = offer['id_offer']?.toString() ?? 'N/A';
                                  final tokenAmount = offer['tokenAmount']?.toString() ?? '0';
                                  final tokenValue = offer['tokenValue']?.toString() ?? '0.00';
                                  final creationDate = offer['creationDate'] ?? 'Unknown date';
                                  final delta = (offer['token_to_buy'] == null)
                                      ? ((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100) // Formule inversée
                                      : ((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100); // Formule originale
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${S.of(context).offer_id}: $offerId',
                                              style: TextStyle(
                                                fontSize: 14 + appState.getTextSizeOffset(),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Spacer(),
                                            Stack(
                                              alignment: Alignment.center,
                                              clipBehavior: Clip.none,
                                              children: [
                                                Text(
                                                  Utils.formatReadableDate(creationDate),
                                                  style: TextStyle(
                                                    fontSize: 12 + appState.getTextSizeOffset(),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                if (offer['token_to_pay'] == '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                                                    offer['token_to_pay'] == '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d')
                                                  Positioned(
                                                    bottom: -30,
                                                    child: Image.asset(
                                                      'assets/icons/xdai.png',
                                                      width: 28,
                                                      height: 28,
                                                    ),
                                                  )
                                                else if (offer['token_to_pay'] == '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' ||
                                                    offer['token_to_pay'] == '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1')
                                                  Positioned(
                                                    bottom: -30,
                                                    child: Image.asset(
                                                      'assets/icons/usdc.png',
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${S.of(context).token_amount}: $tokenAmount',
                                          style: TextStyle(
                                            fontSize: 12 + appState.getTextSizeOffset(),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${S.of(context).token_value}: ${Utils.formatCurrency(offer['tokenValue'], dataManager.currencySymbol)}',
                                          style: TextStyle(
                                            fontSize: 12 + appState.getTextSizeOffset(),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '${S.of(context).delta_price}: ',
                                              style: TextStyle(
                                                fontSize: 12 + appState.getTextSizeOffset(),
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              offer['tokenValue'] != null && offer['tokenPrice'] != null && offer['tokenPrice'] != 0
                                                  ? '${(((offer['tokenValue'] ?? 0) / (offer['tokenPrice'] ?? 1) - 1) * 100).toStringAsFixed(2)}%'
                                                  : 'N/A',
                                              style: TextStyle(
                                                fontSize: 12 + appState.getTextSizeOffset(),
                                                fontWeight: FontWeight.bold,
                                                color: offer['token_to_buy'] == null
                                                    ? (delta < 0 ? Colors.green : Colors.red)
                                                    : (delta < 0 ? Colors.red : Colors.green),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ElevatedButton(
                                          onPressed: () {
                                            Utils.launchURL('https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                                offer['token_to_buy'] == null ? Colors.blue : Colors.green, // Rouge pour "acheter" et bleu pour "vendre"
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size(80, 30),
                                          ),
                                          child: Text(
                                            offer['token_to_buy'] == null ? S.of(context).buy_token : S.of(context).sell_token,
                                          ),
                                        ),
                                        Divider(),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
