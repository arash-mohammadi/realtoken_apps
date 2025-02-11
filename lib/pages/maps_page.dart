import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:realtokens/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/pages/portfolio/token_details/showTokenDetails.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/utils/url_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/managers/data_manager.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  MapsPageState createState() => MapsPageState(); // Remplacer _MapsPageState par MapsPageState
}

class MapsPageState extends State<MapsPage> {
  final PopupController _popupController = PopupController();
  bool _showAllTokens = false;
  final String _searchQuery = '';
  final String _sortOption = 'Name';
  final bool _isAscending = true;
  bool _forceLightMode = false; // Nouveau switch pour forcer le mode clair

  @override
  void initState() {
    super.initState();
    _loadThemePreference(); // Charger la préférence du thème à l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  // Charger la préférence du thème à partir de SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _forceLightMode = prefs.getBool('forceLightMode') ?? false; // Charger le mode forcé
    });
  }

  // Sauvegarder la préférence du mode dans SharedPreferences
  Future<void> _saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('forceLightMode', _forceLightMode); // Sauvegarder le mode forcé
  }

  // Méthode pour filtrer et trier les tokens (même approche que PortfolioPage)
  List<Map<String, dynamic>> _filterAndSortTokens(List<Map<String, dynamic>> tokens) {
    List<Map<String, dynamic>> filteredTokens = tokens.where((token) => token['fullName'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (_sortOption == 'Name') {
      filteredTokens.sort((a, b) => _isAscending ? a['shortName'].compareTo(b['shortName']) : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == 'Value') {
      filteredTokens.sort((a, b) => _isAscending ? a['totalValue'].compareTo(b['totalValue']) : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == 'APY') {
      filteredTokens
          .sort((a, b) => _isAscending ? a['annualPercentageYield'].compareTo(b['annualPercentageYield']) : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
    }

    return filteredTokens;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context); // Accéder à AppState

    final tokensToShow = _showAllTokens ? _filterAndSortTokens(dataManager.allTokens) : _filterAndSortTokens(dataManager.portfolio);

    if (tokensToShow.isEmpty) {
      return const Center(child: Text('No tokens available'));
    }

    final List<Marker> markers = [];

    // Helper function to create markers
    Marker createMarker({
      required dynamic matchingToken,
      required Color color,
    }) {
      final lat = double.tryParse(matchingToken['lat']);
      final lng = double.tryParse(matchingToken['lng']);
      final rentedUnits = matchingToken['rentedUnits'] ?? 0;
      final totalUnits = matchingToken['totalUnits'] ?? 1;

      if (lat != null && lng != null) {
        return Marker(
          width: 40.0, // Augmentez cette valeur pour une image plus grande
          height: 40.0, // Augmentez cette valeur pour une image plus grande
          point: LatLng(lat, lng),
          child: GestureDetector(
            onTap: () => _showMarkerPopup(context, matchingToken),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: UIUtils.getRentalStatusColor(rentedUnits, totalUnits), width: 3.0),
              ),
              child: ClipOval(
                child: matchingToken['imageLink'] != null
                    ? CachedNetworkImage(
                        imageUrl: matchingToken['imageLink'][0],
                        fit: BoxFit.cover, // Cette propriété remplit tout l'espace
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      )
                    : Icon(
                        Icons.location_on,
                        color: color,
                        size: 40.0,
                      ),
              ),
            ),
          ),
          key: ValueKey(matchingToken),
        );
      } else {
        return Marker(
          point: LatLng(0, 0),
          child: const SizedBox.shrink(),
        );
      }
    }

    for (var token in tokensToShow) {
      final isWallet = token['source'] == 'Wallet';
      final isRMM = token['source'] == 'RMM';

      if (token['lat'] != null) {
        markers.add(
          createMarker(
            matchingToken: token,
            color: isWallet
                ? Colors.green
                : isRMM
                    ? Colors.blue
                    : Colors.grey,
          ),
        );
      }
    }

    if (markers.isEmpty) {
      return const Center(child: Text('No tokens with valid coordinates found on the map'));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Définit la couleur de fond pour la carte
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(42.367476, -83.130921),
                initialZoom: 8.0,
                onTap: (_, __) => _popupController.hideAllPopups(),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.scrollWheelZoom),
              ),
              children: [
                TileLayer(
                  // Si _forceLightMode est activé, on utilise le mode clair
                  urlTemplate: _forceLightMode
                      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                      : Theme.of(context).brightness == Brightness.dark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  tileProvider: kIsWeb
                      ? NetworkTileProvider() // Utilisé uniquement pour le web
                      : FMTCStore('mapStore').getTileProvider(), // Utilisé pour iOS, Android, etc.
                  userAgentPackageName: 'com.byackee.realtokens',
                  retinaMode: true,
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 40,
                    disableClusteringAtZoom: 14,
                    size: const Size(40, 40),
                    markers: markers,
                    builder: (context, clusterMarkers) {
                      Color clusterColor = _getClusterColor(clusterMarkers);
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              clusterColor.withOpacity(0.9),
                              clusterColor.withOpacity(0.2),
                            ],
                            stops: [0.4, 1.0],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            clusterMarkers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Switch pour basculer entre le mode sombre/clair et forcer le mode clair pour la carte
          Positioned(
            top: UIUtils.getAppBarHeight(context),
            right: 16,
            child: Row(
              children: [
                Text(_forceLightMode ? 'Light' : 'Auto'),
                Transform.scale(
                  scale: 0.8, // Réduire la taille du switch à 80%
                  child: Switch(
                    value: _forceLightMode,
                    onChanged: (value) {
                      setState(() {
                        _forceLightMode = value; // Mettre à jour le switch pour forcer le mode clair
                      });
                      _saveThemePreference(); // Sauvegarder la préférence
                    },
                    activeColor: Theme.of(context).primaryColor,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          // Switch en haut à gauche pour basculer entre les tokens du portefeuille et tous les tokens
          Positioned(
            top: UIUtils.getAppBarHeight(context), // Positionner juste en dessous de l'AppBar
            left: 16,
            child: Row(
              children: [
                Transform.scale(
                  scale: 0.8, // Réduit la taille du Switch à 80%
                  child: Switch(
                    value: _showAllTokens,
                    onChanged: (value) {
                      setState(() {
                        _showAllTokens = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor, // Couleur du bouton en mode activé
                    inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                  ),
                ),
                Text(_showAllTokens ? 'All Tokens' : 'Portfolio'),
              ],
            ),
          ),
          // Légende en bas à gauche
          Positioned(
            bottom: 90, // Remonter la légende pour la placer au-dessus de la BottomBar
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "Fully Rented",
                        style: TextStyle(
                          fontSize: 13, // Taille du texte ajustée
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        "Partially Rented",
                        style: TextStyle(
                          fontSize: 13, // Taille du texte ajustée
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        "Not Rented",
                        style: TextStyle(
                          fontSize: 13, // Taille du texte ajustée
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour déterminer la couleur du cluster en fonction des marqueurs qu'il contient
  Color _getClusterColor(List<Marker> markers) {
    int fullyRented = 0;
    int notRented = 0;

    for (var marker in markers) {
      if (marker.key is ValueKey) {
        final token = (marker.key as ValueKey).value as Map<String, dynamic>;

        final rentedUnits = token['rentedUnits'] ?? 0;
        final totalUnits = token['totalUnits'] ?? 1;

        if (rentedUnits == 0) {
          notRented++;
        } else if (rentedUnits == totalUnits) {
          fullyRented++;
        }
      }
    }

    if (fullyRented == markers.length) {
      return Colors.green;
    } else if (notRented == markers.length) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  void _showMarkerPopup(BuildContext context, dynamic matchingToken) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final rentedUnits = matchingToken['rentedUnits'] ?? 0;
        final totalUnits = matchingToken['totalUnits'] ?? 1;
        final lat = double.tryParse(matchingToken['lat']) ?? 0.0;
        final lng = double.tryParse(matchingToken['lng']) ?? 0.0;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (matchingToken['imageLink'] != null)
                GestureDetector(
                  onTap: () => showTokenDetails(context, matchingToken),
                  child: CachedNetworkImage(
                    imageUrl: matchingToken['imageLink'][0],
                    width: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  matchingToken['shortName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Token Price: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${matchingToken['tokenPrice'] ?? 'N/A'}'),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Token Yield: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${matchingToken['annualPercentageYield'] != null ? matchingToken['annualPercentageYield'].toStringAsFixed(2) : 'N/A'}'),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Units Rented: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$rentedUnits / $totalUnits'),
                ],
              ),
              const SizedBox(height: 16.0),
              IconButton(
                icon: const Icon(Icons.streetview, color: Colors.blue),
                onPressed: () {
                  final googleStreetViewUrl = 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat,$lng';
                  UrlUtils.launchURL(googleStreetViewUrl);
                },
              ),
              const Text('View in Street View'),
            ],
          ),
        );
      },
    );
  }
}
