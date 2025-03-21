import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens/modals/token_details/tabs/others_tab.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/url_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:show_network_image/show_network_image.dart';
import '../../pages/portfolio/FullScreenCarousel.dart';
import 'package:realtokens/app_state.dart';

import 'tabs/property_tab.dart';
import 'tabs/finance_tab.dart';
import 'tabs/market_tab.dart';
import 'tabs/insights_tab.dart';
import 'tabs/history_tab.dart';

void _openMapModal(BuildContext context, dynamic lat, dynamic lng) {
  final double? latitude = double.tryParse(lat.toString());
  final double? longitude = double.tryParse(lng.toString());

  if (latitude == null || longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid coordinates for the property')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.85,
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).viewOnMap),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    final googleStreetViewUrl =
                        'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latitude,$longitude';
                    UrlUtils.launchURL(googleStreetViewUrl);
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.streetview,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showTokenDetails(
    BuildContext context, Map<String, dynamic> token) async {
  final dataManager = Provider.of<DataManager>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
  final prefs = await SharedPreferences.getInstance();
  bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
  final appState = Provider.of<AppState>(context, listen: false);

  showModalBottomSheet(
    backgroundColor: Theme.of(context).cardColor,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DefaultTabController(
        length: 6,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                token['imageLink'] != null && token['imageLink'].isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          final List<String> imageLinks =
                              token['imageLink'] is String
                                  ? [token['imageLink']]
                                  : List<String>.from(token['imageLink']);

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullScreenCarousel(
                                imageLinks: imageLinks,
                              ),
                            ),
                          );
                        },
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: MediaQuery.of(context).size.height * 0.22,
                            enableInfiniteScroll: true,
                            enlargeCenterPage: true,
                          ),
                          items: (token['imageLink'] is String
                                  ? [token['imageLink']]
                                  : List<String>.from(token['imageLink']))
                              .map<Widget>((imageUrl) {
                            return Stack(
                              // ✅ Superposition pour capturer le clic uniquement sur Web
                              children: [
                                // ✅ Image affichée normalement
                                kIsWeb
                                    ? ShowNetworkImage(
                                        imageSrc: imageUrl,
                                        mobileBoxFit: BoxFit.cover,
                                        mobileWidth: double.infinity)
                                    : CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),

                                // ✅ Superposition d'un GestureDetector transparent uniquement sur Web
                                if (kIsWeb)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior
                                          .translucent, // Capture le clic même sur les parties transparentes
                                      onTap: () {
                                        print("✅ Image cliquée sur Web !");
                                        final List<String> imageLinks =
                                            token['imageLink'] is String
                                                ? [token['imageLink']]
                                                : List<String>.from(
                                                    token['imageLink']);

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FullScreenCarousel(
                                              imageLinks: imageLinks,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey,
                        child: const Center(
                          child: Text("No image available"),
                        ),
                      ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Ajuste la taille au contenu
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Centre horizontalement
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Centre verticalement
                    children: [
                      if (token['country'] != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Image.asset(
                            'assets/country/${token['country'].toLowerCase()}.png',
                            width: 26 + appState.getTextSizeOffset(),
                            height: 26 + appState.getTextSizeOffset(),
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.flag, size: 24);
                            },
                          ),
                        ),
                      Flexible(
                        // Remplace `Expanded`
                        child: Text(
                          token['fullName'] ?? S.of(context).nameUnavailable,
                          style: TextStyle(
                            fontSize: 15 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                token['amount'] != null
                    ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${S.of(context).amount}: ${token['amount']?.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                                fontSize: 13 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(token['totalValue']),
                                  currencyUtils.currencySymbol),
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                                fontSize: 13 + appState.getTextSizeOffset(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),
                const SizedBox(height: 5),
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black12
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) => null),
                    labelStyle: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      _buildTabSegment(
                        icon: Icons.home_outlined,
                        label: "Property",
                      ),
                      _buildTabSegment(
                        icon: Icons.attach_money_outlined,
                        label: "Finance",
                      ),
                      _buildTabSegment(
                        icon: Icons.store_outlined,
                        label: "Market",
                      ),
                      _buildTabSegment(
                        icon: Icons.info_outline,
                        label: "Info",
                      ),
                      _buildTabSegment(
                        icon: Icons.insights_outlined,
                        label: "Insights",
                      ),
                      _buildTabSegment(
                        icon: Icons.history_outlined,
                        label: "History",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: TabBarView(
                    children: [
                      buildPropertiesTab(context, token, convertToSquareMeters),
                      buildFinanceTab(context, token, convertToSquareMeters),
                      MarketTab(token: token),
                      buildOthersTab(
                          context, token), // Ajoutez l'onglet Autres ici
                      buildInsightsTab(context, token),
                      buildHistoryTab(
                          context, token, dataManager.isLoadingTransactions),
                    ],
                  ),
                ),
                const SizedBox(height: 0),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () =>
                                UrlUtils.launchURL(token['marketplaceLink']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 8),
                              textStyle: TextStyle(
                                fontSize: 13 + appState.getTextSizeOffset(),
                              ),
                            ),
                            child: Text(S.of(context).viewOnRealT),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _openMapModal(
                                context, token['lat'], token['lng']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 8),
                              textStyle: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset()),
                            ),
                            child: Text(S.of(context).viewOnMap),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildTabSegment({required IconData icon, required String label}) {
  return Tab(
    height: 40,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}
