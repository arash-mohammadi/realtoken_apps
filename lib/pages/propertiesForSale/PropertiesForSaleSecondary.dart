import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/app_state.dart';
import 'package:realtokens_apps/api/data_manager.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:realtokens_apps/generated/l10n.dart';

class PropertiesForSaleSecondary extends StatefulWidget {
  const PropertiesForSaleSecondary({Key? key}) : super(key: key);

  @override
  _PropertiesForSaleSecondaryState createState() =>
      _PropertiesForSaleSecondaryState();
}

class _PropertiesForSaleSecondaryState
    extends State<PropertiesForSaleSecondary> {
  String? lastUpdateTime;

  @override
  void initState() {
    super.initState();
    Utils.refreshData(context);

    // Récupérez la date de dernière mise à jour au chargement
    final box =
        Hive.box('realTokens'); // Remplacez par le nom de votre boîte Hive
    setState(() {
      lastUpdateTime = box.get('lastUpdateTime_YamMarket') as String?;
    });
  }

  Future<void> _refreshData() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndStorePropertiesForSale();
    // Mettez à jour la date de dernière mise à jour
    final box = Hive.box('realTokens');
    setState(() {
      lastUpdateTime = box.get('lastUpdateTime_YamMarket') as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);
    final groupedOffers = <String, List<Map<String, dynamic>>>{};

    for (var offer in dataManager.yamMarket) {
      String tokenKey = (offer['token_to_sell'] ?? offer['token_to_buy']) ?? '';

      if (groupedOffers.containsKey(tokenKey)) {
        groupedOffers[tokenKey]!.add(offer);
      } else {
        groupedOffers[tokenKey] = [offer];
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastUpdateTime != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Dernière mise à jour : ${Utils.formatReadableDateWithTime(lastUpdateTime!)}',
                style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    color: Colors.grey[600]),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: groupedOffers.isEmpty
                  ? Center(
                      child: Text(
                        S.of(context).no_market_offers_available,
                        style: TextStyle(
                            fontSize: 16 + appState.getTextSizeOffset()),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedOffers.keys.length,
                      itemBuilder: (context, index) {
                        String tokenKey = groupedOffers.keys.elementAt(index);
                        List<Map<String, dynamic>> offers =
                            groupedOffers[tokenKey]!;
                        final imageUrl = (offers.first['imageLink'] != null &&
                                offers.first['imageLink'] is List &&
                                offers.first['imageLink'].isNotEmpty)
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (country != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Image.asset(
                                                'assets/country/${country.toLowerCase()}.png',
                                                width: 24,
                                                height: 24,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(Icons.flag,
                                                      size: 24);
                                                },
                                              ),
                                            ),
                                          Text(
                                            shortName,
                                            style: TextStyle(
                                              fontSize: 18 +
                                                  appState.getTextSizeOffset(),
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
                                  final offerId =
                                      offer['id_offer']?.toString() ?? 'N/A';
                                  final holderAddress =
                                      offer['holderAddress'] ?? 'N/A';
                                  final tokenAmount =
                                      offer['tokenAmount']?.toString() ?? '0';
                                  final tokenValue =
                                      offer['tokenValue']?.toString() ?? '0.00';
                                  final creationDate =
                                      offer['creationDate'] ?? 'Unknown date';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(
                                            '${S.of(context).offer_id}: ${offer['id_offer']}',
                                            style: TextStyle(
                                              fontSize: 14 +
                                                  appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            Utils.formatReadableDate(
                                                offer['creationDate']),
                                            style: TextStyle(
                                              fontSize: 12 +
                                                  appState.getTextSizeOffset(),
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${S.of(context).token_amount}: $tokenAmount',
                                          style: TextStyle(
                                            fontSize: 12 +
                                                appState.getTextSizeOffset(),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${S.of(context).token_value}: \$${tokenValue}',
                                          style: TextStyle(
                                            fontSize: 12 +
                                                appState.getTextSizeOffset(),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '${S.of(context).delta_price}: ',
                                              style: TextStyle(
                                                fontSize: 12 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100).toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                fontSize: 12 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                color: ((offer['tokenValue'] /
                                                                    offer[
                                                                        'tokenPrice'] -
                                                                1) *
                                                            100) >
                                                        0
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ElevatedButton(
                                          onPressed: () {
                                            Utils.launchURL(
                                                'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            minimumSize: Size(80, 30),
                                          ),
                                          child: Text(
                                            S.of(context).buy_token,
                                            style: TextStyle(fontSize: 12),
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
