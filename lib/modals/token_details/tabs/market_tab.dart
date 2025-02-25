import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:realtokens/utils/url_utils.dart';

class MarketTab extends StatefulWidget {
  final Map<String, dynamic> token;
  final bool isModal;

  const MarketTab({Key? key, required this.token, this.isModal = false}) : super(key: key);

  @override
  _MarketTabState createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  // Variables et logique inchangées
  String selectedOfferType = "tout";
  String selectedSortOption = "delta";
  bool ascending = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Column(
      children: [
        // Affichage d'un header spécifique pour la modal
        if (widget.isModal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).offers_list_header,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        // On place le reste dans une Expanded pour occuper l'espace restant
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Header conditionnel pour la version non modale
              SliverPersistentHeader(
                floating: true,
                pinned: false,
                delegate: _FilterHeaderDelegate(
                  height: 60,
                  child: Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Partie filtres
                        Row(
                          children: [
                            ChoiceChip(
                              label: Icon(
                                Icons.all_inclusive,
                                size: 14, // Utiliser size au lieu de fontSize
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
                            ChoiceChip(
                              label: Icon(
                                Icons.add_shopping_cart,
                                size: 14, // Utiliser size au lieu de fontSize
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
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Icon(
                                Icons.sell,
                                size: 14, // Utiliser size au lieu de fontSize
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
                        // Partie tri
                        Row(
                          children: [
                            Text(S.of(context).sort_label, style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: selectedSortOption,
                              items: [
                                DropdownMenuItem(
                                  value: "date",
                                  child: Text(S.of(context).sort_date, style: TextStyle(fontSize: 12)),
                                ),
                                DropdownMenuItem(
                                  value: "delta",
                                  child: Text(S.of(context).sort_delta, style: TextStyle(fontSize: 12)),
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
                            if (!widget.isModal)
                              IconButton(
                                icon: Icon(Icons.open_in_new),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      return Container(
                                        color: Theme.of(context).cardColor,
                                        height: MediaQuery.of(context).size.height * 0.9,
                                        child: MarketTab(token: widget.token, isModal: true),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Titre de la section pour la version non modale
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    S.of(context).secondary_offers_related_to_token,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15 + appState.getTextSizeOffset(),
                    ),
                  ),
                ),
              ),
              // Liste des offres
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getFilteredOffers(dataManager, widget.token['uuid'], selectedOfferType),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text(S.of(context).error_occurred(snapshot.error.toString()))),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(child: Text(S.of(context).no_market_offers_available)),
                    );
                  } else {
                    final offers = snapshot.data!;
                    // Tri des offres
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

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final offer = offers[index];
                          final bool isTokenWhitelisted = dataManager.whitelistTokens.any(
                            (whitelisted) => whitelisted['token'].toLowerCase() == widget.token['uuid'].toLowerCase(),
                          );

                          // Si un filtre spécifique est sélectionné, on affiche la carte correspondante.
                          if (selectedOfferType == "vente") {
                            return _buildSaleOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                          } else if (selectedOfferType == "achat") {
                            return _buildPurchaseOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                          } else {
                            // Pour "tout", on vérifie le type réel de l'offre :
                            if (offer['token_to_buy'] == null) {
                              return _buildSaleOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                            } else {
                              return _buildPurchaseOfferCard(context, appState, currencyUtils, offer, isTokenWhitelisted);
                            }
                          }
                        },
                        childCount: offers.length,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleOfferDetails(BuildContext context, AppState appState, CurrencyProvider currencyUtils, Map<String, dynamic> offer) {
    final baseYield = double.tryParse(widget.token['annualPercentageYield'].toString()) ?? 0;
    final initialPrice = double.tryParse(widget.token['initPrice'].toString()) ?? 0;
    final offerPrice = double.tryParse(offer['token_value'].toString()) ?? 0;

    // Si une des valeurs est invalide, ne rien afficher
    if (baseYield <= 0 || initialPrice <= 0 || offerPrice <= 0) {
      return const SizedBox();
    }

    // Calcul du nouveau yield et du ROI
    final newYield = baseYield * (initialPrice / offerPrice);
    final premiumPercentage = ((offerPrice - initialPrice) / initialPrice) * 100;
    final roiWeeks = (premiumPercentage * 52) / baseYield;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comparaison des prix
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix Actuel:',
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${currencyUtils.formatCurrency(initialPrice, currencyUtils.currencySymbol)}',
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
                  'Prix Offre:',
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${currencyUtils.formatCurrency(offerPrice, currencyUtils.currencySymbol)}',
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Comparaison des yields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yield Actuel:',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau Yield:',
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
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Zone mise en valeur pour le ROI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'ROI: ${roiWeeks.toStringAsFixed(1)} semaines',
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // Contenu principal de la carte
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning si non whitelisté
                    if (!isTokenWhitelisted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          S.of(context).not_whitelisted_warning,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                                UrlUtils.launchURL(
                                  'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}',
                                );
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
              // Icône superposée dans le coin supérieur droit
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

  Widget _buildSaleOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
  ) {
    final baseYield = double.tryParse(widget.token['annualPercentageYield'].toString()) ?? 0;
    final initialPrice = double.tryParse(widget.token['initPrice'].toString()) ?? 0;
    final offerPrice = double.tryParse(offer['token_value'].toString()) ?? 0;

    if (baseYield <= 0 || initialPrice <= 0 || offerPrice <= 0) {
      return const SizedBox();
    }

    final newYield = baseYield * (initialPrice / offerPrice);
    final premiumPercentage = ((offerPrice - initialPrice) / initialPrice) * 100;
    final roiWeeks = (premiumPercentage * 52) / baseYield;

    // Calcul du delta à partir des valeurs du token_value et tokenPrice de l'offre
    final double deltaValue = ((offer['token_value'] / offer['token_price'] - 1) * 100);

    // Détermination de la couleur selon le delta :
    // delta entre 1% et 7% -> orange, supérieur à 7% -> rouge, sinon vert
    Color customColor;
    if (deltaValue >= 1 && deltaValue <= 7) {
      customColor = Colors.orange;
    } else if (deltaValue > 7) {
      customColor = Colors.red;
    } else {
      customColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // Contenu principal de la carte
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning si non whitelisté
                    if (!isTokenWhitelisted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          S.of(context).not_whitelisted_warning,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                    // Comparaison des prix : Prix Actuel et Prix Offre
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Prix Actuel (en bleu)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prix Actuel:',
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${currencyUtils.formatCurrency(initialPrice, currencyUtils.currencySymbol)}',
                              style: TextStyle(
                                fontSize: 14 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        // Prix Offre (coloré selon customColor)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prix Offre:',
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${currencyUtils.formatCurrency(offerPrice, currencyUtils.currencySymbol)}',
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
                    // Comparaison des yields : Yield Actuel et Nouveau Yield (ce dernier coloré selon customColor)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yield Actuel:',
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
                              'Nouveau Yield:',
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
                    // Zone mise en valeur pour le ROI (en orange par défaut)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ROI: ${roiWeeks.toStringAsFixed(1)} semaines',
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
                                UrlUtils.launchURL(
                                  'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}',
                                );
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
              // Icône superposée dans le coin supérieur droit
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

// Delegate pour le header flottant (version non modale)
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _FilterHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

// Fonction pour récupérer les offres filtrées selon le type
Future<List<Map<String, dynamic>>> _getFilteredOffers(
  DataManager dataManager,
  String tokenUuid,
  String offerType,
) async {
  List<Map<String, dynamic>> filteredOffers = dataManager.yamMarket.where((offer) {
    bool matchToken = offer['token_to_sell'] == tokenUuid.toLowerCase() || offer['token_to_buy'] == tokenUuid.toLowerCase();
    if (!matchToken) return false;
    if (offerType == "vente") {
      return offer['token_to_buy'] == null;
    } else if (offerType == "achat") {
      return offer['token_to_buy'] != null;
    }
    return true;
  }).toList();

  return filteredOffers;
}
