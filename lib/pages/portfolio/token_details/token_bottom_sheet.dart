import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Import pour les coordonnées géographiques
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import 'package:realtokens/api/data_manager.dart'; // Import de DataManager
import 'package:realtokens/generated/l10n.dart'; // Import pour les traductions
import 'package:carousel_slider/carousel_slider.dart';
import '../FullScreenCarousel.dart';
import 'package:realtokens/utils/utils.dart';
import 'package:realtokens/app_state.dart';

Future<List<Map<String, dynamic>>> _getFilteredOffers(DataManager dataManager, String tokenUuid) async {
  return dataManager.yamMarket.where((offer) => offer['token_to_sell'] == tokenUuid.toLowerCase() || offer['token_to_buy'] == tokenUuid.toLowerCase()).toList();
}

void _openMapModal(BuildContext context, dynamic lat, dynamic lng) {
  // Convertir les valeurs lat et lng en double
  final double? latitude = double.tryParse(lat.toString());
  final double? longitude = double.tryParse(lng.toString());

  if (latitude == null || longitude == null) {
    // Afficher un message d'erreur si les coordonnées ne sont pas valides
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
        heightFactor: 0.85, // Ajuste la hauteur de la modale
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).viewOnMap), // Titre de la carte
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
                  initialCenter: LatLng(latitude, longitude), // Utilise les valeurs converties
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
                        point: LatLng(latitude, longitude), // Coordonnées du marqueur
                        width: 50, // Largeur du marqueur
                        height: 50, // Hauteur du marqueur
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40, // Taille de l'icône de localisation
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
                    // Lancer Google Street View
                    final googleStreetViewUrl = 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latitude,$longitude';
                    Utils.launchURL(googleStreetViewUrl);
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

// Fonction pour convertir les sqft en m²
String _formatSquareFeet(double sqft, bool convertToSquareMeters) {
  if (convertToSquareMeters) {
    double squareMeters = sqft * 0.092903; // Conversion des pieds carrés en m²
    return '${squareMeters.toStringAsFixed(2)} m²';
  } else {
    return '${sqft.toStringAsFixed(2)} sqft';
  }
}

// Fonction réutilisable pour afficher la BottomModalSheet avec les détails du token
Future<void> showTokenDetails(BuildContext context, Map<String, dynamic> token) async {
  final dataManager = Provider.of<DataManager>(context, listen: false);

  final prefs = await SharedPreferences.getInstance();
  bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
  final appState = Provider.of<AppState>(context, listen: false);
  final ValueNotifier<bool> showDetailsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showRentDetailsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showTextField = ValueNotifier<bool>(false); // Contrôle de la visibilité
  final Color listingFeeColor = Colors.red;
  final Color maintenanceReserveColor = Colors.orange;
  final Color renovationReserveColor = Colors.purple;
  final Color miscellaneousCostsColor = Colors.amber;
  final Color othersColor = Colors.grey;

// Calculate the total for the selected fields
  double totalCosts = (token['realtListingFee']?.toDouble() ?? 0.0) +
      (token['initialMaintenanceReserve']?.toDouble() ?? 0.0) +
      (token['renovationReserve']?.toDouble() ?? 0.0) +
      (token['miscellaneousCosts']?.toDouble() ?? 0.0);

  double totalRentCosts = (token['propertyMaintenanceMonthly']?.toDouble() ?? 0.0) +
      (token['propertyManagement']?.toDouble() ?? 0.0) +
      (token['realtPlatform']?.toDouble() ?? 0.0) +
      (token['insurance']?.toDouble() ?? 0.0) +
      (token['propertyTaxes']?.toDouble() ?? 0.0);

// Variable pour stocker la valeur modifiable du prix initial
  final TextEditingController initPriceController = TextEditingController(
    text: token['initPrice']?.toString() ?? '0.00',
  );

  showModalBottomSheet(
    backgroundColor: Theme.of(context).cardColor,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DefaultTabController(
        length: 6, // Quatre onglets
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du token
                token['imageLink'] != null && token['imageLink'].isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          // Vérifier si c'est une chaîne ou une liste
                          final List<String> imageLinks = token['imageLink'] is String
                              ? [token['imageLink']] // Convertir en liste si c'est une chaîne
                              : List<String>.from(token['imageLink']); // Garder la liste si c'est déjà une liste

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
                                  ? [token['imageLink']] // Convertir en liste si c'est une chaîne
                                  : List<String>.from(token['imageLink'])) // Utiliser la liste directement
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

                // Titre du token
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
                            const SizedBox(width: 8), // Espace entre les deux éléments
                            Text(
                              Utils.formatCurrency(dataManager.convert(token['totalValue']), dataManager.currencySymbol),
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
                // TabBar pour les différents onglets
                TabBar(
                  labelColor: Colors.blue,
                  indicatorColor: Colors.blue, // Couleur de l'indicateur sous l'onglet sélectionné

                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold), // Taille du texte des onglets sélectionnés
                  unselectedLabelStyle: TextStyle(fontSize: 13 + appState.getTextSizeOffset()), // Taille du texte des onglets non sélectionnés
                  tabs: [
                    Tab(icon: Icon(Icons.home)), // Propriétés
                    Tab(icon: Icon(Icons.attach_money)), // Finances
                    Tab(icon: Icon(Icons.store)), // Market
                    Tab(icon: Icon(Icons.info)), // Autres (icône d'information)
                    Tab(icon: Icon(Icons.insights)), // Insights
                    Tab(icon: Icon(Icons.history)), // Insights
                  ],
                ),

                const SizedBox(height: 10),

// --------------------------------------------------------------------------------------------------------
// -------------------------------- TabBarView pour le contenu de chaque onglet ---------------------------
// --------------------------------------------------------------------------------------------------------

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: TabBarView(
                    children: [
                      // Onglet Propriétés
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).characteristics,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              context,
                              S.of(context).constructionYear,
                              token['constructionYear']?.toString() ?? S.of(context).notSpecified,
                              icon: Icons.calendar_today, // Icône pour l'année de construction
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).propertyType,
                              Parameters.getPropertyTypeName(token['propertyType'] ?? -1, context),
                              icon: Icons.home,
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).rentalType,
                              token['rentalType']?.toString() ?? S.of(context).notSpecified,
                              icon: Icons.assignment, // Icône pour le type de location
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).bedroomBath,
                              token['bedroomBath']?.toString() ?? S.of(context).notSpecified,
                              icon: Icons.bed, // Icône pour les chambres et les salles de bain
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).lotSize,
                              _formatSquareFeet(
                                token['lotSize']?.toDouble() ?? 0,
                                convertToSquareMeters,
                              ),
                              icon: Icons.landscape, // Icône pour la taille du terrain
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).squareFeet,
                              _formatSquareFeet(
                                token['squareFeet']?.toDouble() ?? 0,
                                convertToSquareMeters,
                              ),
                              icon: Icons.square_foot, // Icône pour la surface en pieds carrés
                            ),
                            const SizedBox(height: 10),
                            Text(
                              S.of(context).rents,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.apartment, // Choisissez une icône appropriée pour les unités louées
                                      size: 18, // Taille de l'icône
                                      color: Colors.blueGrey, // Couleur en fonction du thème
                                    ),
                                    const SizedBox(width: 8), // Espacement entre l'icône et le texte
                                    Text(
                                      ' ${S.of(context).rentedUnits}',
                                      style: TextStyle(
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Spacer(),
                                Text(
                                  '${token['rentedUnits'] ?? 0.0} / ${token['totalUnits'] ?? 0.0}',
                                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Utils.getRentalStatusColor(
                                      token['rentedUnits'] ?? 0,
                                      token['totalUnits'] ?? 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.date_range, // Icône pour représenter la date de début de location
                                      size: 18, // Taille de l'icône
                                      color: Colors.blueGrey, // Couleur bleue pour l'icône // Couleur basée sur le thème
                                    ),
                                    const SizedBox(width: 8), // Espacement entre l'icône et le texte
                                    Text(
                                      ' ${S.of(context).rentStartDate}',
                                      style: TextStyle(
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Spacer(),
                                Text(
                                  Utils.formatReadableDate(token['rentStartDate'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 13 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: DateTime.parse(token['rentStartDate'] ?? '').isBefore(DateTime.now()) ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildDetailRow(
                              context,
                              S.of(context).section8paid,
                              '${((token['section8paid']) / (token['grossRentMonth']) * 100).toStringAsFixed(2)}%',
                              icon: Icons.attach_money, // Icône pour le montant payé par Section 8
                            ),
                          ],
                        ),
                      ),

// --------------------------------------------------------------------------------------------------------
// ------------------------------------- Onglet Finances --------------------------------------------------
// --------------------------------------------------------------------------------------------------------

                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailRow(context, S.of(context).totalInvestment,
                                Utils.formatCurrency(dataManager.convert(token['totalInvestment']), dataManager.currencySymbol),
                                icon: Icons.monetization_on),

                            GestureDetector(
                              onTap: () => showDetailsNotifier.value = !showDetailsNotifier.value,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        S.of(context).totalExpenses, // Label pour le texte
                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold), // Optional styling
                                      ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: showDetailsNotifier,
                                        builder: (context, showDetails, child) {
                                          return Icon(
                                            showDetails ? Icons.expand_less : Icons.expand_more,
                                            color: Colors.grey, // Optionnel : couleur de l'icône
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    Utils.formatCurrency(dataManager.convert(token['totalInvestment'] - token['underlyingAssetPrice']),
                                        dataManager.currencySymbol), // Affichage du montant total
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            // Details rows wrapped in ValueListenableBuilder
                            ValueListenableBuilder<bool>(
                              valueListenable: showDetailsNotifier,
                              builder: (context, showDetails, child) {
                                return Visibility(
                                  visible: showDetails,
                                  child: Column(
                                    children: [
                                      _buildDetailRow(
                                        context,
                                        S.of(context).realtListingFee,
                                        Utils.formatCurrency(dataManager.convert(token['realtListingFee'] ?? 0), dataManager.currencySymbol),
                                        isNegative: true,
                                        color: listingFeeColor, // Couleur spécifique
                                      ),
                                      _buildDetailRow(
                                        context,
                                        S.of(context).initialMaintenanceReserve,
                                        Utils.formatCurrency(dataManager.convert(token['initialMaintenanceReserve'] ?? 0), dataManager.currencySymbol),

                                        isNegative: true,
                                        color: maintenanceReserveColor, // Couleur spécifique
                                      ),
                                      _buildDetailRow(
                                        context,
                                        S.of(context).renovationReserve,
                                        Utils.formatCurrency(dataManager.convert(token['renovationReserve'] ?? 0), dataManager.currencySymbol),
                                        isNegative: true,
                                        color: renovationReserveColor, // Couleur spécifique
                                      ),
                                      _buildDetailRow(
                                        context,
                                        S.of(context).miscellaneousCosts,
                                        Utils.formatCurrency(dataManager.convert(token['miscellaneousCosts'] ?? 0), dataManager.currencySymbol),
                                        isNegative: true,
                                        color: miscellaneousCostsColor, // Couleur spécifique
                                      ),
                                      _buildDetailRow(
                                        context,
                                        S.of(context).others,
                                        Utils.formatCurrency(dataManager.convert((token['totalInvestment'] - token['underlyingAssetPrice'] - totalCosts) ?? 0),
                                            dataManager.currencySymbol),
                                        isNegative: true,
                                        color: othersColor, // Couleur spécifique
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Ajouter la jauge horizontale pour la répartition des coûts
                            Row(
                              children: totalCosts > 0
                                  ? [
                                      // Listing Fee
                                      Expanded(
                                        flex: ((token['realtListingFee'] ?? 0) / totalCosts * 100).round(),
                                        child: Container(
                                          height: 10,
                                          color: listingFeeColor, // Couleur représentant le coût de 'realtListingFee'
                                        ),
                                      ),
                                      // Maintenance Reserve
                                      Expanded(
                                        flex: ((token['initialMaintenanceReserve'] ?? 0) / totalCosts * 100).round(),
                                        child: Container(
                                          height: 10,
                                          color: maintenanceReserveColor, // Couleur représentant le coût de 'initialMaintenanceReserve'
                                        ),
                                      ),
                                      // Renovation Reserve
                                      Expanded(
                                        flex: ((token['renovationReserve'] ?? 0) / totalCosts * 100).round(),
                                        child: Container(
                                          height: 10,
                                          color: renovationReserveColor, // Couleur représentant le coût de 'renovationReserve'
                                        ),
                                      ),
                                      // Miscellaneous Costs
                                      Expanded(
                                        flex: ((token['miscellaneousCosts'] ?? 0) / totalCosts * 100).round(),
                                        child: Container(
                                          height: 10,
                                          color: miscellaneousCostsColor, // Couleur représentant le coût de 'miscellaneousCosts'
                                        ),
                                      ),
                                      // Autres
                                      Expanded(
                                        flex:
                                            (((token['totalInvestment'] ?? 0) - (token['underlyingAssetPrice'] ?? 0) - totalCosts) / totalCosts * 100).round(),
                                        child: Container(
                                          height: 10,
                                          color: Colors.grey, // Couleur pour les coûts restants
                                        ),
                                      ),
                                    ]
                                  : [
                                      // Barre grise unique en cas de totalCosts égal à zéro
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 10,
                                          color: Colors.grey, // Couleur grise pour indiquer qu'il n'y a pas de coût
                                        ),
                                      ),
                                    ],
                            ),

                            SizedBox(height: 2), // Espace sous la jauge pour séparatio
                            _buildDetailRow(context, S.of(context).underlyingAssetPrice,
                                Utils.formatCurrency(dataManager.convert(token['underlyingAssetPrice'] ?? 0), dataManager.currencySymbol)),
                            SizedBox(height: 2), // Espace sous la jauge pour séparatio

                            Divider(),

                            _buildDetailRow(context, S.of(context).grossRentMonth,
                                Utils.formatCurrency(dataManager.convert(token['grossRentMonth'] ?? 0), dataManager.currencySymbol),
                                icon: Icons.attach_money),
                            // Total row with tap to show/hide details
                            GestureDetector(
                              onTap: () => showRentDetailsNotifier.value = !showRentDetailsNotifier.value,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        S.of(context).totalExpenses, // Label pour le texte
                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold), // Optional styling
                                      ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: showRentDetailsNotifier,
                                        builder: (context, showDetails, child) {
                                          return Icon(
                                            showDetails ? Icons.expand_less : Icons.expand_more,
                                            color: Colors.grey, // Optionnel : couleur de l'icône
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '- ${Utils.formatCurrency(dataManager.convert(token['grossRentMonth'] - token['netRentMonth']), dataManager.currencySymbol)}', // Affichage du montant total
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            // Details rows wrapped in ValueListenableBuilder
                            ValueListenableBuilder<bool>(
                              valueListenable: showRentDetailsNotifier,
                              builder: (context, showDetails, child) {
                                return Visibility(
                                  visible: showDetails,
                                  child: Column(
                                    children: [
                                      _buildDetailRow(context, S.of(context).propertyMaintenanceMonthly,
                                          Utils.formatCurrency(dataManager.convert(token['propertyMaintenanceMonthly'] ?? 0), dataManager.currencySymbol),
                                          isNegative: true, color: Colors.deepOrange),
                                      _buildDetailRow(context, S.of(context).propertyManagement,
                                          Utils.formatCurrency(dataManager.convert(token['propertyManagement'] ?? 0), dataManager.currencySymbol),
                                          isNegative: true, color: Colors.amber),
                                      _buildDetailRow(context, S.of(context).realtPlatform,
                                          Utils.formatCurrency(dataManager.convert(token['realtPlatform'] ?? 0), dataManager.currencySymbol),
                                          isNegative: true, color: Colors.orange),
                                      _buildDetailRow(context, S.of(context).insurance,
                                          Utils.formatCurrency(dataManager.convert(token['insurance'] ?? 0), dataManager.currencySymbol),
                                          isNegative: true, color: Colors.purple),
                                      _buildDetailRow(context, S.of(context).propertyTaxes,
                                          Utils.formatCurrency(dataManager.convert(token['propertyTaxes'] ?? 0), dataManager.currencySymbol),
                                          isNegative: true, color: Colors.red),
                                      _buildDetailRow(
                                          context,
                                          S.of(context).others,
                                          Utils.formatCurrency((dataManager.convert(token['grossRentMonth'] - token['netRentMonth'] - totalRentCosts) ?? 0),
                                              dataManager.currencySymbol),
                                          isNegative: true,
                                          color: Colors.grey),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Ajouter une jauge pour afficher la répartition des coûts
                            SizedBox(height: 2), // Espace entre les éléments
                            Row(
                              children: [
                                // Property Maintenance Monthly
                                Expanded(
                                  flex: totalRentCosts != 0 ? ((token['propertyMaintenanceMonthly'] ?? 0) / totalRentCosts * 100).round() : 0,
                                  child: Container(
                                    height: 10,
                                    color: Colors.deepOrange, // Couleur pour 'propertyMaintenanceMonthly'
                                  ),
                                ),
                                // Property Management
                                Expanded(
                                  flex: totalRentCosts != 0 ? ((token['propertyManagement'] ?? 0) / totalRentCosts * 100).round() : 0,
                                  child: Container(
                                    height: 10,
                                    color: Colors.amber, // Couleur pour 'propertyManagement'
                                  ),
                                ),
                                // Realt Platform
                                Expanded(
                                  flex: totalRentCosts != 0 ? ((token['realtPlatform'] ?? 0) / totalRentCosts * 100).round() : 0,
                                  child: Container(
                                    height: 10,
                                    color: Colors.orange, // Couleur pour 'realtPlatform'
                                  ),
                                ),
                                // Insurance
                                Expanded(
                                  flex: totalRentCosts != 0 ? ((token['insurance'] ?? 0) / totalRentCosts * 100).round() : 0,
                                  child: Container(
                                    height: 10,
                                    color: Colors.purple, // Couleur pour 'insurance'
                                  ),
                                ),
                                // Property Taxes
                                Expanded(
                                  flex: totalRentCosts != 0 ? ((token['propertyTaxes'] ?? 0) / totalRentCosts * 100).round() : 0,
                                  child: Container(
                                    height: 10,
                                    color: Colors.red, // Couleur pour 'propertyTaxes'
                                  ),
                                ),
                                // Autres
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? (((token['grossRentMonth'] ?? 0.0) - (token['netRentMonth'] ?? 0.0) - totalRentCosts) / totalRentCosts * 100).round()
                                      : 0,
                                  child: Container(
                                    height: 10,
                                    color: Colors.grey, // Couleur pour les autres coûts
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 2), // Espace sous la jauge pour séparation visuelle

                            _buildDetailRow(context, S.of(context).netRentMonth,
                                Utils.formatCurrency(dataManager.convert(token['netRentMonth'] ?? 0), dataManager.currencySymbol)),
                            SizedBox(height: 2), // Espace sous la jauge pour séparation visuelle

                            Divider(),

                            _buildDetailRow(
                              context,
                              S.of(context).initialPrice,
                              Utils.formatCurrency(dataManager.convert(token['tokenPrice']), dataManager.currencySymbol),
                              icon: Icons.price_change_sharp,
                              trailing: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.edit, color: Colors.grey, size: 16 + appState.getTextSizeOffset()),
                                onPressed: () {
                                  showTextField.value = !showTextField.value; // Basculer la visibilité du champ de texte
                                },
                              ),
                            ),

                            // Bloc TextFormField et boutons en dessous
                            ValueListenableBuilder<bool>(
                              valueListenable: showTextField,
                              builder: (context, isVisible, child) {
                                return Visibility(
                                  visible: isVisible,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0), // Espace entre le texte/icone et le bloc
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Alignement des éléments à gauche
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: initPriceController,
                                                keyboardType: TextInputType.text,
                                                decoration: InputDecoration(
                                                  labelText: S.of(context).initialPrice, // Libellé principal
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), // Réduire le padding interne
                                                  isDense: true, // Compacte le champ
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.check, color: Colors.green),
                                              onPressed: () {
                                                final newPrice = double.tryParse(initPriceController.text);
                                                if (newPrice != null) {
                                                  Provider.of<DataManager>(context).setCustomInitPrice(token['uuid'], newPrice);
                                                  showTextField.value = false; // Masque le champ et les icônes
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(S.of(context).initialPriceUpdated)),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(S.of(context).enterValidNumber)),
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                Provider.of<DataManager>(context).removeCustomInitPrice(token['uuid']);
                                                initPriceController.clear(); // Efface le champ de texte
                                                showTextField.value = false; // Masque le champ et les icônes
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(S.of(context).initialPriceRemoved)),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        // Ajout du texte explicatif en plusieurs lignes
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0), // Espacement au-dessus du texte explicatif
                                          child: Text(
                                            S.of(context).initialPriceModified_description,
                                            style: TextStyle(
                                              fontSize: 12 + appState.getTextSizeOffset(), // Taille de texte ajustée
                                              color: Colors.grey, // Couleur grise pour le texte explicatif
                                            ),
                                            maxLines: null, // Permet au texte de s'étendre sur plusieurs lignes
                                            overflow: TextOverflow.visible, // Empêche le texte de se couper
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            Row(children: [
                              Icon(Icons.price_change_sharp, size: 18, color: Colors.blueGrey),
                              Text('  YAM ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 + appState.getTextSizeOffset())),
                              Spacer(),
                              Text(
                                '${Utils.formatCurrency(dataManager.convert((token['yamAverageValue'])), dataManager.currencySymbol)} (${((token['yamAverageValue'] / token['tokenPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  color: (token['yamAverageValue'] * token['amount']) > token['totalValue']
                                      ? Colors.green // Texte vert si la condition est vraie
                                      : Colors.red, // Texte rouge si la condition est fausse
                                ),
                              )
                            ]),
                            _buildDetailRow(
                              context,
                              S.of(context).annualPercentageYield,
                              '${token['annualPercentageYield']?.toStringAsFixed(2) ?? S.of(context).notSpecified} %',
                              icon: Icons.percent, // Icône pour rendement annuel en pourcentage
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).totalRentReceived,
                              Utils.formatCurrency(dataManager.convert(token['totalRentReceived'] ?? 0), dataManager.currencySymbol),
                              icon: Icons.receipt_long, // Icône pour le total des loyers reçus
                            ),
                            _buildDetailRow(
                              context,
                              S.of(context).roiPerProperties,
                              "${(token['totalRentReceived'] / token['initialTotalValue'] * 100).toStringAsFixed(2)} %",
                              icon: Icons.show_chart,
                              color: Colors.blue, // Icône pour le retour sur investissement (ROI)
                            ),
                          ],
                        ),
                      ),

// --------------------------------------------------------------------------------------------------------
// -------------------------------------------- Onglet Market ---------------------------------------------
// --------------------------------------------------------------------------------------------------------

                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Affichage des offres YAM correspondant au token
                            Text(
                              S.of(context).secondary_offers_related_to_token,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Filtrer et afficher les offres avec FutureBuilder et ListView.builder
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getFilteredOffers(dataManager, token['uuid']), // Future pour charger les offres filtrées
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text(S.of(context).error_occurred(snapshot.error.toString())));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Center(child: Text(S.of(context).no_market_offers_available));
                                } else {
                                  final offers = snapshot.data!;

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(), // Empêche le défilement de ListView
                                    itemCount: offers.length,
                                    itemBuilder: (context, index) {
                                      final offer = offers[index];
                                      final delta = (offer['token_to_buy'] == null)
                                          ? ((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100) // Formule inversée
                                          : ((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100); // Formule originale

                                      return Card(
                                        color: Colors.grey.withOpacity(0.1),
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Text(
                                                  '${S.of(context).offer_id}: ${offer['id_offer']}',
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
                                                      Utils.formatReadableDate(offer['creationDate']),
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
                                              ]),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${S.of(context).token_amount}: ${offer['tokenAmount'].toStringAsFixed(3)}',
                                                style: TextStyle(
                                                  fontSize: 12 + appState.getTextSizeOffset(),
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                '${S.of(context).token_value}: ${Utils.formatCurrency(dataManager.convert(offer['tokenValue']), dataManager.currencySymbol)}',
                                                style: TextStyle(
                                                  fontSize: 12 + appState.getTextSizeOffset(),
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${S.of(context).delta_price}: ', // Partie fixe, sans changement de couleur
                                                    style: TextStyle(
                                                      fontSize: 12 + appState.getTextSizeOffset(),
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${delta.toStringAsFixed(2)}%', // Partie variable en couleur
                                                    style: TextStyle(
                                                      fontSize: 12 + appState.getTextSizeOffset(),
                                                      color: offer['token_to_buy'] == null
                                                          ? (delta < 0 ? Colors.green : Colors.red)
                                                          : (delta < 0 ? Colors.red : Colors.green),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Center(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Utils.launchURL('https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    foregroundColor: Colors.white,
                                                    backgroundColor: offer['token_to_buy'] == null
                                                        ? Colors.blue
                                                        : Colors.green, // Rouge pour "acheter" et bleu pour "vendre"
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size(80, 30),
                                                  ),
                                                  child: Text(
                                                    offer['token_to_buy'] == null ? S.of(context).buy_token : S.of(context).sell_token,
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
                              },
                            ),
                          ],
                        ),
                      ),

// --------------------------------------------------------------------------------------------------------
                      // Onglet Autres avec section Blockchain uniquement
// --------------------------------------------------------------------------------------------------------

                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).blockchain,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Ethereum Contract avec icône de lien
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/ethereum.png', // Chemin de l'image
                                      width: 18, // Largeur de l'image
                                      height: 18, // Hauteur de l'image
                                    ),
                                    const SizedBox(width: 8), // Espacement entre l'image et le texte
                                    Text(
                                      S.of(context).ethereumContract,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.link),
                                  onPressed: () {
                                    final ethereumAddress = token['ethereumContract'] ?? '';
                                    if (ethereumAddress.isNotEmpty) {
                                      Utils.launchURL('https://etherscan.io/address/$ethereumAddress');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(S.of(context).notSpecified)),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              token['ethereumContract'] ?? S.of(context).notSpecified,
                              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                            ),

                            const SizedBox(height: 10),

                            // Gnosis Contract avec icône de lien
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/gnosis.png', // Chemin de l'image
                                      width: 18, // Largeur de l'image
                                      height: 18, // Hauteur de l'image
                                    ),
                                    const SizedBox(width: 8), // Espacement entre l'image et le texte
                                    Text(
                                      S.of(context).gnosisContract,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.link),
                                  onPressed: () {
                                    final gnosisAddress = token['gnosisContract'] ?? '';
                                    if (gnosisAddress.isNotEmpty) {
                                      Utils.launchURL('https://gnosisscan.io/address/$gnosisAddress');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(S.of(context).notSpecified)),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              token['gnosisContract'] ?? S.of(context).notSpecified,
                              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                            ),
                            Divider(), // Réduisez la hauteur pour minimiser l’espace
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Aligne le texte et l'icône à gauche
                              children: [],
                            ),
                          ],
                        ),
                      ),

// --------------------------------------------------------------------------------------------------------
                      // Onglet Insights
// --------------------------------------------------------------------------------------------------------

                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // Jauge verticale du ROI de la propriété
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assessment, // Choisissez une icône appropriée
                                      size: 18, // Taille de l'icône
                                      color: Colors.blueGrey, // Couleur basée sur le thème actuel
                                    ),
                                    const SizedBox(width: 8), // Espacement entre l'icône et le texte
                                    Text(
                                      S.of(context).roiPerProperties, // Titre de la jauge
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15 + appState.getTextSizeOffset(),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 8), // Espace entre le texte et l'icône
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(S.of(context).roiPerProperties), // Titre du popup
                                          content: Text(S.of(context).roiAlertInfo), // Texte du popup
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Fermer le popup
                                              },
                                              child: Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Icon(
                                    Icons.help_outline, // Icône "?"
                                    color: Colors.grey,
                                    size: 20 + appState.getTextSizeOffset(), // Ajustez la taille en fonction du texte
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),
                            _buildGaugeForROI(
                              token['totalRentReceived'] / token['initialTotalValue'] * 100, // Calcul du ROI
                              context,
                            ),
                            const SizedBox(height: 8), // Espacement entre l'icône et le texte
                            // Graphique du rendement (Yield)
                            Row(
                              children: [
                                Icon(Icons.trending_up, size: 18, color: Colors.blueGrey), // Icône devant le texte
                                const SizedBox(width: 8), // Espacement entre l'icône et le texte
                                Text(
                                  S.of(context).yieldEvolution, // Utilisation de la traduction
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15 + appState.getTextSizeOffset(), // Réduction de la taille du texte pour Android
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildYieldChartOrMessage(context, token['historic']?['yields'] ?? [], token['historic']?['init_yield']),

                            const SizedBox(height: 20),

                            // Graphique des prix
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money, // Icône pour représenter l'évolution des prix
                                  size: 18, // Taille de l'icône
                                  color: Colors.blueGrey, // Couleur en fonction du thème
                                ),
                                const SizedBox(width: 8), // Espacement entre l'icône et le texte
                                Text(
                                  S.of(context).priceEvolution, // Texte avec traduction
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15 + appState.getTextSizeOffset(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            _buildPriceChartOrMessage(context, token['historic']?['prices'] ?? [], token['initPrice']),
                          ],
                        ),
                      ),

// --------------------------------------------------------------------------------------------------------
                      // Ajout de l'onglet Historique des transactions
// --------------------------------------------------------------------------------------------------------

                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).transactionHistory,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            token['transactions'] != null && token['transactions'].isNotEmpty
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: token['transactions'].length,
                                    itemBuilder: (context, index) {
                                      final transaction = token['transactions'][index];
                                      final amount = transaction['amount'] ?? 0.0;
                                      final dateTime = transaction['dateTime'] != null
                                          ? DateFormat('yyyy-MM-dd HH:mm').format(transaction['dateTime'])
                                          : S.of(context).unknownDate;

                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.attach_money,
                                            color: Colors.green,
                                          ),
                                          title: Text(
                                            '${S.of(context).amount}: $amount',
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${S.of(context).date}: $dateTime',
                                            style: TextStyle(
                                              fontSize: 12 + appState.getTextSizeOffset(),
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      S.of(context).noTransactionsAvailable,
                                      style: TextStyle(
                                        fontSize: 13 + appState.getTextSizeOffset(),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton pour voir sur RealT
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Ajoute un padding de 16 pixels autour des boutons
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Centre les boutons
                      children: [
                        // Bouton pour voir sur RealT
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => Utils.launchURL(token['marketplaceLink']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue, // Bouton bleu pour RealT
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              textStyle: TextStyle(
                                fontSize: 13 + appState.getTextSizeOffset(), // Rendre TextStyle non const
                              ),
                            ),
                            child: Text(S.of(context).viewOnRealT),
                          ),
                        ),

                        const SizedBox(width: 10), // Espacement entre les deux boutons
                        // Bouton pour voir sur la carte
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _openMapModal(context, token['lat'], token['lng']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green, // Bouton vert pour la carte
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

Widget _buildGaugeForROI(double roiValue, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // Aligner la jauge à gauche
    children: [
      const SizedBox(height: 5),
      LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth; // Largeur disponible

          return Stack(
            children: [
              // Fond gris
              Container(
                height: 15,
                width: maxWidth, // Largeur maximale disponible
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3), // Couleur du fond grisé
                  borderRadius: BorderRadius.circular(5), // Bordure arrondie
                ),
              ),
              // Barre bleue représentant le ROI
              Container(
                height: 15,
                width: roiValue.clamp(0, 100) / 100 * maxWidth, // Largeur de la barre bleue en fonction du ROI
                decoration: BoxDecoration(
                  color: Colors.blue, // Couleur de la barre
                  borderRadius: BorderRadius.circular(5), // Bordure arrondie
                ),
              ),
              // Texte centré sur la jauge
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${roiValue.toStringAsFixed(1)} %", // Afficher avec 1 chiffre après la virgule
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Couleur du texte pour contraster avec la jauge
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

// Méthode pour construire les lignes de détails
Widget _buildDetailRow(BuildContext context, String label, String value, {IconData? icon, bool isNegative = false, Color? color, Widget? trailing}) {
  final appState = Provider.of<AppState>(context, listen: false);

  // Ajout du signe "-" et de la couleur rouge si isNegative est true
  final displayValue = isNegative ? '-$value' : value;
  final valueStyle = TextStyle(
    fontSize: 13 + appState.getTextSizeOffset(),
    color: isNegative ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color, // couleur rouge si isNegative
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) // Affiche l'icône si elle est spécifiée
              Icon(icon, size: 18, color: Colors.blueGrey),
            if (isNegative) // Affiche la puce rouge uniquement si isNegative est true
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: color ?? Colors.red,
                ),
              ),
            SizedBox(width: icon != null || isNegative ? 8 : 0), // Espacement conditionnel entre l'icône et le texte
            Text(
              label,
              style: TextStyle(
                fontWeight: isNegative ? FontWeight.normal : FontWeight.bold,
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
            SizedBox(
              height: 16 + appState.getTextSizeOffset(), // Hauteur constante pour le trailing
              child: trailing ?? SizedBox(), // Si trailing est null, on met un espace vide
            ),
          ],
        ),
        Row(
          children: [
            Text(displayValue, style: valueStyle), // Texte avec style conditionnel
          ],
        ),
      ],
    ),
  );
}

// Méthode pour afficher soit le graphique du yield, soit un message, avec % évolution
Widget _buildYieldChartOrMessage(BuildContext context, List<dynamic> yields, double? initYield) {
  final appState = Provider.of<AppState>(context, listen: false);

  if (yields.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return RichText(
  text: TextSpan(
    text: "${S.of(context).noYieldEvolution} ", // Texte avant la valeur
    style: TextStyle(
      fontSize: 13 + appState.getTextSizeOffset(),
      color: Theme.of(context).textTheme.bodyMedium?.color, // Couleur par défaut
    ),
    children: [
      TextSpan(
        text: yields.isNotEmpty
            ? yields.first['yield'].toStringAsFixed(2) // La valeur en gras
            : S.of(context).notSpecified,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color, // Gras uniquement pour cette partie
        ),
      ),
      TextSpan(
        text: " %", // Texte après la valeur
      ),
    ],
  ),
);
  } else {
    // Calculer l'évolution en pourcentage
    double lastYield = yields.last['yield']?.toDouble() ?? 0;
    double percentageChange = ((lastYield - (initYield ?? lastYield)) / (initYield ?? lastYield)) * 100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYieldChart(context, yields),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            text: S.of(context).yieldEvolutionPercentage, // Texte avec la couleur par défaut
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            children: [
              TextSpan(
                text: " ${percentageChange.toStringAsFixed(2)} %", // Affiche la valeur avec une couleur conditionnelle
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: percentageChange < 0 ? Colors.red : Colors.green, // Rouge si négatif, vert sinon
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

// Méthode pour afficher soit le graphique des prix, soit un message, avec % évolution
Widget _buildPriceChartOrMessage(BuildContext context, List<dynamic> prices, double? initPrice) {
  final appState = Provider.of<AppState>(context, listen: false);

  if (prices.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return RichText(
  text: TextSpan(
    text: "${S.of(context).noPriceEvolution} ", // Texte avant la valeur
    style: TextStyle(
      fontSize: 13 + appState.getTextSizeOffset(),
      color: Theme.of(context).textTheme.bodyMedium?.color, // Couleur par défaut
    ),
    children: [
      TextSpan(
        text: prices.isNotEmpty
            ? prices.first['price'].toStringAsFixed(2) // La valeur en gras
            : S.of(context).notSpecified,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color, // Gras uniquement pour cette partie
        ),
      ),
      TextSpan(
        text: " \$", // Texte après la valeur
      ),
    ],
  ),
);

  } else {
    // Calculer l'évolution en pourcentage
    double lastPrice = prices.last['price']?.toDouble() ?? 0;
    double percentageChange = ((lastPrice - (initPrice ?? lastPrice)) / (initPrice ?? lastPrice)) * 100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceChart(context, prices),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            text: S.of(context).priceEvolutionPercentage, // Texte avec la couleur par défaut
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            children: [
              TextSpan(
                text: " ${percentageChange.toStringAsFixed(2)} %", // Affiche la valeur avec une couleur conditionnelle
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: percentageChange < 0 ? Colors.red : Colors.green, // Rouge si négatif, vert sinon
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

// Méthode pour construire le graphique du yield
Widget _buildYieldChart(BuildContext context, List<dynamic> yields) {
  final appState = Provider.of<AppState>(context, listen: false);

  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < yields.length; i++) {
    if (yields[i]['timsync'] != null && yields[i]['timsync'] is String) {
      DateTime date = DateTime.parse(yields[i]['timsync']);
      double x = i.toDouble(); // Utiliser un indice pour l'axe X
      double y = yields[i]['yield'] != null ? double.tryParse(yields[i]['yield'].toString()) ?? 0 : 0;
      y = double.parse(y.toStringAsFixed(2)); // Limiter la valeur de `y` à 2 décimales

      spots.add(FlSpot(x, y));
      dateLabels.add(DateFormat('MM/yyyy').format(date)); // Ajouter la date formatée en mois/année
    }
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double minYValue = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) : 0;
  double maxYValue = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) : 0;

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.2; // Marge pour l'axe X
  const double marginY = 0.5; // Marge pour l'axe Y

  return SizedBox(
    height: 180,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe du haut
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(), // Réduction de la taille pour Android
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1, // Afficher une date à chaque intervalle
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10 + appState.getTextSizeOffset(),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe de droite
          ),
        ),
        minX: minXValue - marginX,
        maxX: maxXValue + marginX,
        minY: minYValue - marginY,
        maxY: maxYValue + marginY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.blue,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}

// Méthode pour construire le graphique des prix
Widget _buildPriceChart(BuildContext context, List<dynamic> prices) {
  final appState = Provider.of<AppState>(context, listen: false);

  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < prices.length; i++) {
    DateTime date = DateTime.parse(prices[i]['timsync']);
    double x = i.toDouble(); // Utiliser un indice pour l'axe X
    double y = prices[i]['price']?.toDouble() ?? 0;

    spots.add(FlSpot(x, y));
    dateLabels.add(DateFormat('MM/yyyy').format(date)); // Ajouter la date formatée en mois/année
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double minYValue = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) : 0;
  double maxYValue = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) : 0;

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.1; // Marge pour l'axe X
  const double marginY = 0.2; // Marge pour l'axe Y

  return SizedBox(
    height: 180,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe du haut
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1, // Afficher une date à chaque intervalle
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10 + appState.getTextSizeOffset(), // Réduction de la taille pour Android
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Désactiver l'axe de droite
          ),
        ),
        minX: minXValue - marginX,
        maxX: maxXValue + marginX,
        minY: minYValue - marginY,
        maxY: maxYValue + marginY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.blue,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}
