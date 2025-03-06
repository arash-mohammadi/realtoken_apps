import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:realtokens/utils/url_utils.dart';
import 'package:show_network_image/show_network_image.dart';

class PropertiesForSaleSecondary extends StatefulWidget {
  const PropertiesForSaleSecondary({super.key});

  @override
  _PropertiesForSaleSecondaryState createState() => _PropertiesForSaleSecondaryState();
}

class _PropertiesForSaleSecondaryState extends State<PropertiesForSaleSecondary> {
  String? lastUpdateTime;
  bool isSearching = false;
  String searchQuery = '';
  bool hideNonWhitelisted = false;

  final TextEditingController searchController = TextEditingController();

  // Variables pour le filtre par type d'offre
  String selectedOfferType = "tout";

  // Variables de tri
  String selectedSortOption = "delta";
  bool ascending = true;

  @override
  void initState() {
    super.initState();
    // Différer la mise à jour des données après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataFetchUtils.refreshData(context);
    });
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
    await DataFetchUtils.refreshData(context);
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
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Regroupement des offres par propriété avec filtres et tri
    final groupedOffers = <String, List<Map<String, dynamic>>>{};
    for (var offer in dataManager.yamMarket) {
  // Filtrer par type d'offre
  if (selectedOfferType == "vente" && offer['token_to_buy'] != null) continue;
  if (selectedOfferType == "achat" && offer['token_to_buy'] == null) continue;
  
  // Si on veut cacher les offres non whitelistées, on vérifie
  if (hideNonWhitelisted) {
    final String? tokenIdentifier = offer['token_to_sell'] ?? offer['token_to_buy'];
    final bool isOfferWhitelisted = dataManager.whitelistTokens.any((whitelisted) =>
        whitelisted['token'].toLowerCase() == tokenIdentifier?.toLowerCase());
    if (!isOfferWhitelisted) continue;
  }
  
  final shortName = offer['shortName']?.toLowerCase() ?? '';
  if (!shortName.contains(searchQuery.toLowerCase())) continue;
  String tokenKey = (offer['token_to_sell'] ?? offer['token_to_buy']) ?? '';
  if (groupedOffers.containsKey(tokenKey)) {
    groupedOffers[tokenKey]!.add(offer);
  } else {
    groupedOffers[tokenKey] = [offer];
  }
}


    // Appliquer le tri sur chaque groupe
    groupedOffers.forEach((key, offers) {
      offers.sort((a, b) {
        if (selectedSortOption == "date") {
          final dateA = a['creationDate'];
          final dateB = b['creationDate'];
          return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        } else {
          final deltaA = ((a['token_value'] / a['token_price'] - 1) * 100);
          final deltaB = ((b['token_value'] / b['token_price'] - 1) * 100);
          return ascending ? deltaA.compareTo(deltaB) : deltaB.compareTo(deltaA);
        }
      });
    });
    

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche et affichage de la dernière mise à jour
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: isSearching
                      ? TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: S.of(context).search_hint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        )
                      : Text(
                          '${S.of(context).last_update} ${CustomDateUtils.formatReadableDateWithTime(lastUpdateTime!)}',
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
                      if (isSearching) searchController.clear();
                      isSearching = !isSearching;
                    });
                  },
                ),
              ],
            ),
          ),
          // Barre des filtres et du tri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filtres par type d'offre avec ChoiceChips
                Row(
  children: [
    ChoiceChip(
      label: Icon(
        Icons.all_inclusive,
        size: 16,
      ),
      selected: selectedOfferType == "tout",
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).cardColor,
      onSelected: (selected) {
        setState(() {
          selectedOfferType = "tout";
        });
      },
    ),
    const SizedBox(width: 8),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChoiceChip(
          label: Icon(
            Icons.add_shopping_cart,
            size: 16,
          ),
          selected: selectedOfferType == "vente",
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).cardColor,
          onSelected: (selected) {
            setState(() {
              selectedOfferType = "vente";
            });
          },
        ),
      ],
    ),
    const SizedBox(width: 8),
    ChoiceChip(
      label: Icon(
        Icons.sell,
        size: 16,
      ),
      selected: selectedOfferType == "achat",
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).cardColor,
      onSelected: (selected) {
        setState(() {
          selectedOfferType = "achat";
        });
      },
    ),
  ],
),
// Contrôles de tri
                Row(
                  children: [
                    IconButton(
          icon: Icon(
            hideNonWhitelisted ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: hideNonWhitelisted ? Colors.red : Colors.green,
          ),
          tooltip: hideNonWhitelisted
              ? "Afficher les propriétés non whitelistées"
              : "Cacher les propriétés non whitelistées",
          onPressed: () {
            setState(() {
              hideNonWhitelisted = !hideNonWhitelisted;
            });
          },
        ),
                    Text(
                      S.of(context).sort_label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    DropdownButton<String>(
                      value: selectedSortOption,
                      items: [
                        DropdownMenuItem(
                          value: "date",
                          child: Text(
                            S.of(context).sort_date,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "delta",
                          child: Text(
                            S.of(context).sort_delta,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSortOption = value;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        ascending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          ascending = !ascending;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: groupedOffers.isEmpty
                ? Center(
                    child: Text(
                      S.of(context).no_market_offers_available,
                      style: TextStyle(
                        fontSize: 16 + appState.getTextSizeOffset(),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Choisir 2 colonnes si la largeur est supérieure à 700, sinon 1 colonne
                      int crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                      return MasonryGridView.count(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedOffers.keys.length,
                        itemBuilder: (context, index) {
                          String tokenKey = groupedOffers.keys.elementAt(index);
                          List<Map<String, dynamic>> offers = groupedOffers[tokenKey]!;
                          final imageUrl =
                              (offers.first['imageLink'] != null && offers.first['imageLink'] is List && offers.first['imageLink'].isNotEmpty) ? offers.first['imageLink'][0] : '';
                          final shortName = offers.first['shortName'] ?? 'N/A';
                          final country = offers.first['country'] ?? 'USA';
final String? tokenIdentifier = offers.first['token_to_sell'] ?? offers.first['token_to_buy'];
final bool isWhitelisted = dataManager.whitelistTokens.any((whitelisted) =>
    whitelisted['token'].toLowerCase() == tokenIdentifier?.toLowerCase());

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 1,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Affichage de l'image de la propriété si disponible
                                  if (imageUrl.isNotEmpty)
                                    AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: kIsWeb
                                            ? ShowNetworkImage(
                                                imageSrc: imageUrl,
                                                mobileBoxFit: BoxFit.cover,
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                errorWidget: (context, url, error) => const Icon(Icons.error),
                                              ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  // Affichage des informations de la propriété
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
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
                                            const SizedBox(height: 4),
            
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
              children: [
                Icon(
                  isWhitelisted ? Icons.check_circle : Icons.cancel,
                  color: isWhitelisted ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  isWhitelisted
                      ? S.of(context).tokenWhitelisted
                      : S.of(context).tokenNotWhitelisted,
                  style: TextStyle(
                    color: isWhitelisted ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
                                  const SizedBox(height: 8),
                                  // Affichage des offres pour ce groupe
                                  ...offers.map((offer) {
                                    bool isTokenWhitelisted = true; // À ajuster selon votre logique
                                    if (selectedOfferType == "vente") {
                                      return _buildSaleOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                                    } else if (selectedOfferType == "achat") {
                                      return _buildPurchaseOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                                    } else {
                                      if (offer['token_to_buy'] == null) {
                                        return _buildSaleOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                                      } else {
                                        return _buildPurchaseOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                                      }
                                    }
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Fonction de construction d'une carte d'offre "Sell"
  Widget _buildSaleOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
  ) {
      final dataManager = Provider.of<DataManager>(context, listen: false);
  // Exemple de vérification : utilisez la clé qui identifie le token dans offer.
  final String? tokenIdentifier = offer['token_to_sell'] ?? offer['token_to_buy'];
  final bool isTokenWhitelisted = dataManager.whitelistTokens.any((whitelisted) =>
      whitelisted['token'].toLowerCase() == tokenIdentifier?.toLowerCase()
  );
    final baseYield = double.tryParse(offer['annualPercentageYield']?.toString() ?? '0') ?? 0;
    final initialPrice = double.tryParse(offer['token_price']?.toString() ?? '0') ?? 0;
    final offerPrice = double.tryParse(offer['token_value']?.toString() ?? '0') ?? 0;

    if (baseYield <= 0 || initialPrice <= 0 || offerPrice <= 0) return const SizedBox();

    final newYield = baseYield * (initialPrice / offerPrice);
    final premiumPercentage = ((offerPrice - initialPrice) / initialPrice) * 100;
    final roiWeeks = (premiumPercentage * 52) / baseYield;
    final double deltaValue = ((offer['token_value'] / offer['token_price'] - 1) * 100);

    Color customColor;
    if (deltaValue >= 1 && deltaValue <= 7) {
      customColor = Colors.orange;
    } else if (deltaValue > 7) {
      customColor = Colors.red;
    } else {
      customColor = Colors.green;
    }

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Opacity(
          opacity: isTokenWhitelisted ? 1.0 : 0.5,
          child: Card(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête : ID et date
                      Row(
                        children: [
                          Image.asset(
                            'assets/logo.png', // Chemin vers l'image dans assets
                            height: 24, // Ajuster la taille de l'image
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${S.of(context).offer_id}: ${offer['id_offer']}',
                            style: TextStyle(
                              fontSize: 14 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CustomDateUtils.formatReadableDate(offer['creationDate']),
                            style: TextStyle(
                              fontSize: 12 + appState.getTextSizeOffset(),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Montant du token
                      Text(
                        '${S.of(context).token_amount}: ${offer['token_amount']?.toStringAsFixed(3)}',
                        style: TextStyle(
                          fontSize: 12 + appState.getTextSizeOffset(),
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Delta Price
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
                            '${deltaValue.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 12 + appState.getTextSizeOffset(),
                              // On conserve ici le style de delta : négatif en vert, positif en rouge
                              color: (deltaValue < 0 ? Colors.green : Colors.red),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // Comparaison des prix

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).current_price,
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                currencyUtils.formatCurrency(initialPrice, currencyUtils.currencySymbol),
                                style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).offer_price,
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                currencyUtils.formatCurrency(offerPrice, currencyUtils.currencySymbol),
                                style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: customColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Comparaison des yields et ROI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).current_yield,
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${baseYield.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                S.of(context).new_yield,
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${newYield.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: customColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Affichage du ROI
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          S.of(context).roi_label(roiWeeks.toStringAsFixed(1)),
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: isTokenWhitelisted
                              ? () {
                                  UrlUtils.launchURL('https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(80, 30),
                          ),
                          child: Text(S.of(context).buy_token),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 35,
                  right: 25,
                  child: Builder(
                    builder: (context) {
                      if (offer['token_to_pay'] == '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' || offer['token_to_pay'] == '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                        return Image.asset(
                          'assets/icons/xdai.png',
                          width: 28,
                          height: 28,
                        );
                      } else if (offer['token_to_pay'] == '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' || offer['token_to_pay'] == '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1') {
                        return Image.asset(
                          'assets/icons/usdc.png',
                          width: 24,
                          height: 24,
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // Fonction de construction d'une carte d'offre "Buy"
  Widget _buildPurchaseOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
  ) {
      final dataManager = Provider.of<DataManager>(context, listen: false);
  // Exemple de vérification : utilisez la clé qui identifie le token dans offer.
  final String? tokenIdentifier = offer['token_to_sell'] ?? offer['token_to_buy'];
  final bool isTokenWhitelisted = dataManager.whitelistTokens.any((whitelisted) =>
      whitelisted['token'].toLowerCase() == tokenIdentifier?.toLowerCase()
  );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.5,
        child: Card(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo.png', // Chemin vers l'image dans assets
                          height: 24, // Ajuster la taille de l'image
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${S.of(context).offer_id}: ${offer['id_offer']}',
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          CustomDateUtils.formatReadableDate(offer['creationDate']),
                          style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${S.of(context).token_amount}: ${offer['token_amount']?.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 12 + appState.getTextSizeOffset(),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${S.of(context).token_value}: ${currencyUtils.formatCurrency(currencyUtils.convert(offer['token_value']), currencyUtils.currencySymbol)}',
                      style: TextStyle(
                        fontSize: 12 + appState.getTextSizeOffset(),
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          '${((offer['token_value'] / offer['token_price'] - 1) * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: ((offer['token_value'] / offer['token_price'] - 1) * 100) < 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton(
                        onPressed: isTokenWhitelisted
                            ? () {
                                UrlUtils.launchURL('https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(80, 30),
                        ),
                        child: Text(S.of(context).sell_token),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 35,
                right: 25,
                child: Builder(
                  builder: (context) {
                    if (offer['token_to_pay'] == '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' || offer['token_to_pay'] == '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                      return Image.asset(
                        'assets/icons/xdai.png',
                        width: 28,
                        height: 28,
                      );
                    } else if (offer['token_to_pay'] == '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' || offer['token_to_pay'] == '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1') {
                      return Image.asset(
                        'assets/icons/usdc.png',
                        width: 24,
                        height: 24,
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
