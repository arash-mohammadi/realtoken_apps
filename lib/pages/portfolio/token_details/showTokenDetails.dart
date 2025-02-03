import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens/pages/portfolio/token_details/tabs/others_tab.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/url_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../FullScreenCarousel.dart';
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
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    final googleStreetViewUrl = 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latitude,$longitude';
                    UrlUtils.launchURL(googleStreetViewUrl);
                  },
                  backgroundColor: Colors.blue,
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

Future<void> showTokenDetails(BuildContext context, Map<String, dynamic> token) async {
  final dataManager = Provider.of<DataManager>(context, listen: false);
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
                          final List<String> imageLinks = token['imageLink'] is String
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
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                  child: Text(
                    token['fullName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15 + appState.getTextSizeOffset(),
                    ),
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
                              CurrencyUtils.formatCurrency(dataManager.convert(token['totalValue']), dataManager.currencySymbol),
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
                TabBar(
                  labelColor: Colors.blue,
                  indicatorColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                  tabs: [
                    Tab(icon: Icon(Icons.home)),
                    Tab(icon: Icon(Icons.attach_money)),
                    Tab(icon: Icon(Icons.store)),
                    Tab(icon: Icon(Icons.info)),
                    Tab(icon: Icon(Icons.insights)),
                    Tab(icon: Icon(Icons.history)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: TabBarView(
                    children: [
    buildPropertiesTab(context, token, convertToSquareMeters),
    buildFinanceTab(context, token, convertToSquareMeters),
    buildMarketTab(context, token),
        buildOthersTab(context, token), // Ajoutez l'onglet Autres ici
    buildInsightsTab(context, token),
    buildHistoryTab(context, token),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => UrlUtils.launchURL(token['marketplaceLink']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              textStyle: TextStyle(
                                fontSize: 13 + appState.getTextSizeOffset(),
                              ),
                            ),
                            child: Text(S.of(context).viewOnRealT),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _openMapModal(context, token['lat'], token['lng']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              textStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
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