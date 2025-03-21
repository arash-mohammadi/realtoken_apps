import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  const MarketTab({super.key, required this.token, this.isModal = false});

  @override
  _MarketTabState createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  String selectedOfferType = "tout";
  String selectedSortOption = "delta";
  bool ascending = true;

  // Définition des couleurs iOS
  final Color _iosPrimaryColor = const Color(0xFF007AFF); // Bleu iOS
  final Color _iosSuccessColor = const Color(0xFF34C759); // Vert iOS
  final Color _iosWarningColor = const Color(0xFFFF9500); // Orange iOS
  final Color _iosDangerColor = const Color(0xFFFF3B30);  // Rouge iOS
  final Color _iosLabelColor = const Color(0xFF000000);   // Noir iOS pour text
  final Color _iosSecondaryLabelColor = const Color(0xFF8E8E93); // Gris iOS
  final Color _iosBackgroundColor = const Color(0xFFF2F2F7); // Background iOS
  final Color _iosSurfaceColor = const Color(0xFFFFFFFF);  // Surface iOS

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    
    // Utilisation des couleurs du thème si disponibles
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    return Column(
      children: [
        // Header pour la vue modale
        if (widget.isModal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : _iosSurfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).offers_list_header,
                  style: TextStyle(
                    fontSize: 17 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : _iosLabelColor,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: isDarkMode ? Colors.white : _iosLabelColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        
        // Contenu principal
        Expanded(
          child: Container(
            color: isDarkMode ? Colors.black : _iosBackgroundColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(), // iOS-like scroll physics
              slivers: [
                // Header avec filtres (persistent)
                SliverPersistentHeader(
                  floating: true,
                  pinned: true,
                  delegate: _IOSStyleFilterHeaderDelegate(
                    height: 38,
                    backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : _iosSurfaceColor,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                      alignment: Alignment.topCenter,
                      child: Transform.translate(
                        offset: const Offset(0, -3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Filtres
                            Row(
                              children: [
                                _buildIOSSegmentedControl(),
                              ],
                            ),
                            
                            // Options de tri
                            Row(
                              children: [
                                Text(
                                  S.of(context).sort_label,
                                  style: TextStyle(
                                    fontSize: 13 + appState.getTextSizeOffset(),
                                    color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildIOSDropdown(context, isDarkMode),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minSize: 0,
                                  child: Icon(
                                    ascending
                                        ? CupertinoIcons.arrow_up
                                        : CupertinoIcons.arrow_down,
                                    size: 18,
                                    color: isDarkMode ? Colors.white : _iosPrimaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      ascending = !ascending;
                                    });
                                  },
                                ),
                                
                                // Bouton pour ouvrir en plein écran
                                if (!widget.isModal)
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minSize: 0,
                                    child: Icon(
                                      CupertinoIcons.fullscreen,
                                      size: 18,
                                      color: isDarkMode ? Colors.white : _iosPrimaryColor,
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (BuildContext context) {
                                          return Container(
                                            height: MediaQuery.of(context).size.height * 0.9,
                                            decoration: BoxDecoration(
                                              color: isDarkMode ? Colors.black : _iosSurfaceColor,
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                              child: MarketTab(token: widget.token, isModal: true),
                                            ),
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
                ),
                
                // Titre de la section (stylisé iOS)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 10),
                    child: Text(
                      S.of(context).secondary_offers_related_to_token,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20 + appState.getTextSizeOffset(),
                        letterSpacing: -0.5,
                        color: isDarkMode ? Colors.white : _iosLabelColor,
                      ),
                    ),
                  ),
                ),
                
                // Liste des offres
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getFilteredOffers(
                      dataManager, widget.token['uuid'], selectedOfferType),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverFillRemaining(
                        child: Center(
                          child: CupertinoActivityIndicator(), // iOS-style loading indicator
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_circle,
                                size: 50,
                                color: _iosDangerColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                S.of(context).error_occurred(snapshot.error.toString()),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.search,
                                size: 50,
                                color: isDarkMode ? Colors.white30 : Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                S.of(context).no_market_offers_available,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final offers = snapshot.data!;
                      // Tri des offres
                      offers.sort((a, b) {
                        if (selectedSortOption == "date") {
                          final dateA = a['creationDate'];
                          final dateB = b['creationDate'];
                          return ascending
                              ? dateA.compareTo(dateB)
                              : dateB.compareTo(dateA);
                        } else {
                          final deltaA = ((a['token_value'] / a['token_price'] - 1) * 100);
                          final deltaB = ((b['token_value'] / b['token_price'] - 1) * 100);
                          return ascending
                              ? deltaA.compareTo(deltaB)
                              : deltaB.compareTo(deltaA);
                        }
                      });

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final offer = offers[index];
                            final bool isTokenWhitelisted =
                                dataManager.whitelistTokens.any(
                              (whitelisted) =>
                                  whitelisted['token'].toLowerCase() ==
                                  widget.token['uuid'].toLowerCase(),
                            );

                            // Render appropriate card based on offer type
                            if (selectedOfferType == "vente") {
                              return _buildIOSSaleOfferCard(
                                  context, appState, currencyUtils, offer, isTokenWhitelisted, isDarkMode);
                            } else if (selectedOfferType == "achat") {
                              return _buildIOSPurchaseOfferCard(
                                  context, appState, currencyUtils, offer, isTokenWhitelisted, isDarkMode);
                            } else {
                              if (offer['token_to_buy'] == null) {
                                return _buildIOSSaleOfferCard(
                                    context, appState, currencyUtils, offer, isTokenWhitelisted, isDarkMode);
                              } else {
                                return _buildIOSPurchaseOfferCard(
                                    context, appState, currencyUtils, offer, isTokenWhitelisted, isDarkMode);
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
        ),
      ],
    );
  }

  // iOS-style segmented control
  Widget _buildIOSSegmentedControl() {
    return CupertinoSegmentedControl<String>(
      children: {
        "tout": Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            CupertinoIcons.rectangle_grid_1x2_fill,
            size: 16,
          ),
        ),
        "vente": Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            CupertinoIcons.shopping_cart,
            size: 16,
          ),
        ),
        "achat": Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            CupertinoIcons.tag_fill,
            size: 16,
          ),
        ),
      },
      groupValue: selectedOfferType,
      onValueChanged: (value) {
        setState(() {
          selectedOfferType = value;
        });
      },
    );
  }

  // iOS-style dropdown
  Widget _buildIOSDropdown(BuildContext context, bool isDarkMode) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Text(
            selectedSortOption == "date" 
                ? S.of(context).sort_date 
                : S.of(context).sort_delta,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white : _iosPrimaryColor,
            ),
          ),
          Icon(
            CupertinoIcons.chevron_down,
            size: 14,
            color: isDarkMode ? Colors.white : _iosPrimaryColor,
          ),
        ],
      ),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                child: Text(S.of(context).sort_date),
                onPressed: () {
                  setState(() {
                    selectedSortOption = "date";
                  });
                  Navigator.pop(context);
                },
              ),
              CupertinoActionSheetAction(
                child: Text(S.of(context).sort_delta),
                onPressed: () {
                  setState(() {
                    selectedSortOption = "delta";
                  });
                  Navigator.pop(context);
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  // iOS-style sale offer card
  Widget _buildIOSSaleOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
    bool isDarkMode,
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

    final double deltaValue = ((offer['token_value'] / offer['token_price'] - 1) * 100);

    // Détermination de la couleur selon le delta
    Color deltaColor;
    if (deltaValue >= 1 && deltaValue <= 7) {
      deltaColor = _iosWarningColor;
    } else if (deltaValue > 7) {
      deltaColor = _iosDangerColor;
    } else {
      deltaColor = _iosSuccessColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : _iosSurfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Contenu principal
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning si non whitelisté
                      if (!isTokenWhitelisted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _iosDangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _iosDangerColor.withOpacity(0.3), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: _iosDangerColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  S.of(context).not_whitelisted_warning,
                                  style: TextStyle(
                                    color: _iosDangerColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12 + appState.getTextSizeOffset(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // En-tête : ID et date
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/logo.png',
                              height: 28,
                              width: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${S.of(context).offer_id}: ${offer['id_offer']}',
                                style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : _iosLabelColor,
                                ),
                              ),
                              Text(
                                CustomDateUtils.formatReadableDate(offer['creationDate']),
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // Informations sur le token
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3) 
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Token amount
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.number_square,
                                  size: 14,
                                  color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${offer['token_amount']?.toStringAsFixed(3)}',
                                  style: TextStyle(
                                    fontSize: 13 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : _iosLabelColor,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Delta price
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: deltaColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    deltaValue > 0 
                                        ? CupertinoIcons.arrow_up_right 
                                        : CupertinoIcons.arrow_down_right,
                                    size: 12,
                                    color: deltaColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${deltaValue.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 13 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.w600,
                                      color: deltaColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // Comparaison des prix
                      Row(
                        children: [
                          Expanded(
                            child: _buildIOSInfoBox(
                              context,
                              appState,
                              'Prix Actuel',
                              currencyUtils.formatCurrency(initialPrice, currencyUtils.currencySymbol),
                              _iosPrimaryColor,
                              isDarkMode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildIOSInfoBox(
                              context,
                              appState,
                              'Prix Offre',
                              currencyUtils.formatCurrency(offerPrice, currencyUtils.currencySymbol),
                              deltaColor,
                              isDarkMode,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Comparaison des yields
                      Row(
                        children: [
                          Expanded(
                            child: _buildIOSInfoBox(
                              context,
                              appState,
                              'Yield Actuel',
                              '${baseYield.toStringAsFixed(2)}%',
                              _iosPrimaryColor,
                              isDarkMode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildIOSInfoBox(
                              context,
                              appState,
                              'Nouveau Yield',
                              '${newYield.toStringAsFixed(2)}%',
                              deltaColor,
                              isDarkMode,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // Zone ROI
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: _iosWarningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _iosWarningColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'ROI: ${roiWeeks.toStringAsFixed(1)} semaines',
                            style: TextStyle(
                              fontSize: 15 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.w600,
                              color: _iosWarningColor,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Bouton d'action
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          color: _iosPrimaryColor,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: isTokenWhitelisted
                              ? () {
                                  UrlUtils.launchURL(
                                    'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}',
                                  );
                                }
                              : null,
                          child: Text(
                            S.of(context).buy_token,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icône de paiement
                Positioned(
                  top: 12,
                  right: 12,
                  child: Builder(
                    builder: (context) {
                      Widget icon = const SizedBox();
                      
                      if (offer['token_to_pay'] == '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                          offer['token_to_pay'] == '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                        icon = Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/xdai.png',
                            width: 20,
                            height: 20,
                          ),
                        );
                      } else if (offer['token_to_pay'] == '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' ||
                                 offer['token_to_pay'] == '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1') {
                        icon = Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/usdc.png',
                            width: 20,
                            height: 20,
                          ),
                        );
                      }
                      
                      return icon;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSPurchaseOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
    bool isDarkMode,
  ) {
    final double deltaValue = ((offer['token_value'] / offer['token_price'] - 1) * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : _iosSurfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Contenu principal
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning si non whitelisté
                      if (!isTokenWhitelisted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _iosDangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _iosDangerColor.withOpacity(0.3), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: _iosDangerColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  S.of(context).not_whitelisted_warning,
                                  style: TextStyle(
                                    color: _iosDangerColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12 + appState.getTextSizeOffset(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // En-tête : ID et date
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/logo.png',
                              height: 28,
                              width: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${S.of(context).offer_id}: ${offer['id_offer']}',
                                style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : _iosLabelColor,
                                ),
                              ),
                              Text(
                                CustomDateUtils.formatReadableDate(offer['creationDate']),
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Informations sur le token
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3) 
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Token amount
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.number_square,
                                      size: 14,
                                      color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${offer['token_amount']?.toStringAsFixed(3)}',
                                      style: TextStyle(
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.white : _iosLabelColor,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Delta price
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (deltaValue < 0 ? _iosSuccessColor : _iosDangerColor).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        deltaValue < 0 
                                            ? CupertinoIcons.arrow_down_right 
                                            : CupertinoIcons.arrow_up_right,
                                        size: 12,
                                        color: deltaValue < 0 ? _iosSuccessColor : _iosDangerColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${deltaValue.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          fontSize: 13 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w600,
                                          color: deltaValue < 0 ? _iosSuccessColor : _iosDangerColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${S.of(context).token_value}:',
                                  style: TextStyle(
                                    fontSize: 13 + appState.getTextSizeOffset(),
                                    color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                                  ),
                                ),
                                Text(
                                  currencyUtils.formatCurrency(
                                      currencyUtils.convert(offer['token_value']), 
                                      currencyUtils.currencySymbol),
                                  style: TextStyle(
                                    fontSize: 13 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : _iosLabelColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Bouton d'action
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          color: _iosSuccessColor,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: isTokenWhitelisted
                              ? () {
                                  UrlUtils.launchURL(
                                    'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}',
                                  );
                                }
                              : null,
                          child: Text(
                            S.of(context).sell_token,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icône de paiement
                Positioned(
                  top: 12,
                  right: 12,
                  child: Builder(
                    builder: (context) {
                      Widget icon = const SizedBox();
                      
                      if (offer['token_to_pay'] == '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                          offer['token_to_pay'] == '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                        icon = Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/xdai.png',
                            width: 20,
                            height: 20,
                          ),
                        );
                      } else if (offer['token_to_pay'] == '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' ||
                                 offer['token_to_pay'] == '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1') {
                        icon = Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/usdc.png',
                            width: 20,
                            height: 20,
                          ),
                        );
                      }
                      
                      return icon;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget pour les boîtes d'information
  Widget _buildIOSInfoBox(
    BuildContext context,
    AppState appState,
    String label,
    String value,
    Color valueColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : valueColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: valueColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12 + appState.getTextSizeOffset(),
              color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Delegate iOS-style pour le header flottant
class _IOSStyleFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  final Color backgroundColor;
  
  _IOSStyleFilterHeaderDelegate({
    required this.height, 
    required this.child,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      color: backgroundColor.withOpacity(overlapsContent ? 0.95 : 1.0),
      child: ClipRect(
        child: BackdropFilter(
          filter: overlapsContent 
              ? ImageFilter.blur(sigmaX: 10, sigmaY: 10) 
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _IOSStyleFilterHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || 
           oldDelegate.child != child || 
           oldDelegate.backgroundColor != backgroundColor;
  }
}

// Fonction pour récupérer les offres filtrées selon le type
Future<List<Map<String, dynamic>>> _getFilteredOffers(
  DataManager dataManager,
  String tokenUuid,
  String offerType,
) async {
  List<Map<String, dynamic>> filteredOffers =
      dataManager.yamMarket.where((offer) {
    bool matchToken = offer['token_to_sell'] == tokenUuid.toLowerCase() ||
        offer['token_to_buy'] == tokenUuid.toLowerCase();
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