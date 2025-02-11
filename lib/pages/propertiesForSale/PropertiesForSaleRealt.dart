import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/url_utils.dart';

class PropertiesForSaleRealt extends StatefulWidget {
  const PropertiesForSaleRealt({super.key});

  @override
  _PropertiesForSaleRealtState createState() => _PropertiesForSaleRealtState();
}

class _PropertiesForSaleRealtState extends State<PropertiesForSaleRealt> {
  @override
  void initState() {
    super.initState();
    final dataManager = Provider.of<DataManager>(context, listen: false);
    dataManager.fetchAndStorePropertiesForSale();
  }

  Widget _buildGaugeForRent(double rentValue, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 15,
                  width: maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), // Couleur du fond grisé
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 14,
                  width: rentValue.clamp(0, 100) / 100 * maxWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      "${rentValue.toStringAsFixed(1)} %",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);
    final propertiesForSale = dataManager.propertiesForSale;

    return Scaffold(
      body: propertiesForSale.isEmpty
          ? Center(
              child: Text(
                S.of(context).noPropertiesForSale,
                style: TextStyle(fontSize: 16 + appState.getTextSizeOffset()),
              ),
            )
          : AlignedGridView.count(
              padding: const EdgeInsets.only(top: 20, bottom: 80),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1, // Nombre de colonnes selon la largeur de l'écran

              itemCount: propertiesForSale.length,
              itemBuilder: (context, index) {
                final property = propertiesForSale[index];

                final imageUrl = property['imageLink'][0];
                final title = property['shortName'] ?? S.of(context).nameUnavailable;
                final double stock = (property['stock'] as num?)?.toDouble() ?? 0.0;

                final double tokenPrice = (property['tokenPrice'] as num?)?.toDouble() ?? 0.0;
                final double annualPercentageYield = (property['annualPercentageYield'] as num?)?.toDouble() ?? 0.0;

                final double totalTokens = (property['totalTokens'] as num?)?.toDouble() ?? 0.0;

                final country = property['country'] ?? 'unknown';

                final city = property['city'] ?? 'unknown';
                final status = property['status'] ?? 'Unknown';
                final sellPercentage = (totalTokens - stock) / totalTokens * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      // Implémentez l'action au clic sur la carte, par exemple, afficher les détails
                    },
                    child: Card(
                      color: Theme.of(context).cardColor,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                            title,
                                            style: TextStyle(
                                              fontSize: 18 + appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: status == 'Available' ? Colors.green : Colors.red,
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildGaugeForRent(sellPercentage, context),
                                const SizedBox(height: 8),
                                Text(
                                  'Stock: $totalTokens Left: $stock ',
                                  style: TextStyle(
                                    fontSize: 15 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                Text(
                                  'Price: ${CurrencyUtils.formatCurrency(tokenPrice, dataManager.currencySymbol)} Yield: ${annualPercentageYield.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 15 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () => UrlUtils.launchURL(property['marketplaceLink']),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Theme.of(context).primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      textStyle: TextStyle(
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                      ),
                                    ),
                                    child: Text('Acheter cette propriété'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
