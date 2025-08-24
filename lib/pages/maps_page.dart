import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/modals/token_details/showTokenDetails.dart';
import 'package:meprop_asset_tracker/utils/currency_utils.dart';
import 'package:meprop_asset_tracker/utils/ui_utils.dart';
import 'package:meprop_asset_tracker/utils/url_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meprop_asset_tracker/managers/data_manager.dart';
import 'package:show_network_image/show_network_image.dart';
import 'package:meprop_asset_tracker/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:meprop_asset_tracker/generated/l10n.dart';

// Marker and cluster coloration mode
enum ColorationMode { rental, apy }

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  MapsPageState createState() => MapsPageState(); // Replace _MapsPageState with MapsPageState
}

class MapsPageState extends State<MapsPage> {
  final PopupController _popupController = PopupController();
  bool _showAllTokens = false;
  bool _showWhitelistedTokens = false;
  final String _searchQuery = '';
  final String _sortOption = 'Name';
  final bool _isAscending = true;
  bool _forceLightMode = false;

  // Advanced filters
  bool _showHeatmapRent = false;
  bool _showHeatmapPerformance = false;
  bool _showYamOffers = false;
  bool _showRecentTransactions = false;
  bool _showMiniDashboard = false;

  // Profitability filters
  double _minApy = 0.0;
  double _maxApy = 50.0;
  bool _onlyWithRent = false;
  bool _onlyFullyRented = false;

  // Region filters
  String? _selectedCountry;
  List<String> _availableCountries = [];

  // Performance filters
  double _minRoi = -100.0; // Allow negative ROI
  double _maxRoi = 100.0;

  // Filter panel controller
  bool _showFiltersPanel = false;

  final MapController _mapController = MapController();

  // Variables for mini-dashboard dimming during interactions
  double _dashboardOpacity = 1.0;
  Timer? _dashboardTimer;

  // Marker and cluster coloration mode
  ColorationMode _colorationMode = ColorationMode.apy;

  @override
  void initState() {
    super.initState();
    _loadThemePreference(); // Load theme preference on init
    _loadColorationModePreference(); // Load coloration mode preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  void dispose() {
    _dashboardTimer?.cancel();
    super.dispose();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _forceLightMode = prefs.getBool('forceLightMode') ?? false; // Load forced mode
    });
  }

  // Save mode preference in SharedPreferences
  Future<void> _saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('forceLightMode', _forceLightMode); // Save forced mode
  }

  // Load coloration mode preference from SharedPreferences
  Future<void> _loadColorationModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final colorationModeString = prefs.getString('colorationMode') ?? 'apy';
    setState(() {
      _colorationMode = colorationModeString == 'rental' ? ColorationMode.rental : ColorationMode.apy;
    });
  }

  // Save coloration mode preference in SharedPreferences
  Future<void> _saveColorationModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('colorationMode', _colorationMode == ColorationMode.rental ? 'rental' : 'apy');
  }

  // Handle control panel dimming and close open panels
  void _onMapInteraction() {
    // Cancel previous timer if it exists
    _dashboardTimer?.cancel();

    // Close Statistics and Filters panels if they are open
    bool shouldUpdate = false;
    if (_showMiniDashboard) {
      _showMiniDashboard = false;
      shouldUpdate = true;
    }
    if (_showFiltersPanel) {
      _showFiltersPanel = false;
      shouldUpdate = true;
    }

    // Immediately dim the main control panel
    if (_dashboardOpacity == 1.0) {
      _dashboardOpacity = 0.3;
      shouldUpdate = true;
    }

    // Apply changes if necessary
    if (shouldUpdate) {
      setState(() {});
    }

    // Schedule return to normal opacity after 2.5 seconds
    _dashboardTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _dashboardOpacity = 1.0;
        });
      }
    });
  }

  // Optimized to avoid rent calculations on non-owned tokens
  double _getTokenRentSafely(String tokenUuid, DataManager dataManager) {
    // First check if it's in the portfolio
    final portfolioToken = dataManager.portfolio.firstWhere(
        (portfolioToken) => portfolioToken['uuid'].toLowerCase() == tokenUuid.toLowerCase(),
        orElse: () => <String, dynamic>{});

    // If not in portfolio, no rent
    if (portfolioToken.isEmpty) {
      return 0.0;
    }

    // Use precalculated data for all owned tokens (Wallet AND RMM)
    return dataManager.cumulativeRentsByToken[tokenUuid.toLowerCase()] ?? 0.0;
  }

  // Method to zoom on a cluster
  void _zoomToCluster(List<Marker> clusterMarkers) {
    if (clusterMarkers.isEmpty) return;

    // Calculate geographical bounds of the cluster
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in clusterMarkers) {
      final lat = marker.point.latitude;
      final lng = marker.point.longitude;

      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    // Calculate center and bounds with margin
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;

    // Add 20% margin around bounds
    final margin = 0.2;
    final boundsSouthWest = LatLng(minLat - latDiff * margin, minLng - lngDiff * margin);
    final boundsNorthEast = LatLng(maxLat + latDiff * margin, maxLng + lngDiff * margin);

    // Zoom on calculated area
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(boundsSouthWest, boundsNorthEast),
      padding: const EdgeInsets.all(50.0),
    ));
  }

  // Method to filter and sort tokens with advanced criteria
  List<Map<String, dynamic>> _filterAndSortTokens(List<Map<String, dynamic>> tokens, DataManager dataManager) {
    List<Map<String, dynamic>> filteredTokens = tokens.where((token) {
      // Exclude factoring_profitshare tokens (not real properties)
      final productType = token['productType']?.toString().toLowerCase() ?? '';
      if (productType == 'factoring_profitshare') {
        return false;
      }

      // Text search filter
      if (!token['fullName'].toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // APY filter
      final apy = token['annualPercentageYield'] ?? 0.0;
      if (apy < _minApy || apy > _maxApy) {
        return false;
      }

      // Only with rent filter
      if (_onlyWithRent) {
        final totalRent = _getTokenRentSafely(token['uuid'], dataManager);
        if (totalRent <= 0) {
          return false;
        }
      }

      // Only fully rented filter
      if (_onlyFullyRented) {
        final rentedUnits = token['rentedUnits'] ?? 0;
        final totalUnits = token['totalUnits'] ?? 1;
        if (rentedUnits < totalUnits) {
          return false;
        }
      }

      // Country filter
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
        if (!_matchesCountryFilter(token, _selectedCountry)) {
          return false;
        }
      }

      // ROI filter (if applicable)
      final initialValue = token['initialTotalValue'] ?? token['tokenPrice'];
      final currentValue = token['tokenPrice'] ?? 0.0;
      final roi = initialValue > 0 ? ((currentValue - initialValue) / initialValue * 100) : 0.0;
      if (roi < _minRoi || roi > _maxRoi) {
        return false;
      }

      return true;
    }).toList();

    // Sorting
    if (_sortOption == 'Name') {
      filteredTokens.sort(
          (a, b) => _isAscending ? a['shortName'].compareTo(b['shortName']) : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == 'Value') {
      filteredTokens.sort((a, b) =>
          _isAscending ? a['totalValue'].compareTo(b['totalValue']) : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == 'APY') {
      filteredTokens.sort((a, b) => _isAscending
          ? a['annualPercentageYield'].compareTo(b['annualPercentageYield'])
          : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
    } else if (_sortOption == 'ROI') {
      filteredTokens.sort((a, b) {
        final roiA = _calculateRoi(a);
        final roiB = _calculateRoi(b);
        return _isAscending ? roiA.compareTo(roiB) : roiB.compareTo(roiA);
      });
    } else if (_sortOption == 'Rent') {
      filteredTokens.sort((a, b) {
        final rentA = _getTokenRentSafely(a['uuid'], dataManager);
        final rentB = _getTokenRentSafely(b['uuid'], dataManager);
        return _isAscending ? rentA.compareTo(rentB) : rentB.compareTo(rentA);
      });
    }

    return filteredTokens;
  }

  double _calculateRoi(Map<String, dynamic> token) {
    final initialValue = token['initialTotalValue'] ?? token['tokenPrice'];
    final currentValue = token['tokenPrice'] ?? 0.0;
    return initialValue > 0 ? ((currentValue - initialValue) / initialValue * 100) : 0.0;
  }

  // Method to check if a token matches the country filter
  bool _matchesCountryFilter(Map<String, dynamic> token, String? selectedCountry) {
    if (selectedCountry == null) return true;

    String tokenCountry = token['country'] ?? "Unknown Country";

    // If "Series XX" is selected, filter all factoring_profitshare tokens with series
    if (selectedCountry == "Series XX") {
      return (token['productType']?.toString().toLowerCase() == 'factoring_profitshare') &&
          tokenCountry.toLowerCase().startsWith('series ');
    }

    // Normal filter
    return tokenCountry == selectedCountry;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    final sourceTokens = _showAllTokens ? dataManager.allTokens : dataManager.portfolio;

    final tokensToShow = _filterAndSortTokens(sourceTokens, dataManager);

    final displayedTokens = _showWhitelistedTokens
        ? tokensToShow
            .where((token) =>
                dataManager.whitelistTokens.any((w) => w['token'].toLowerCase() == token['uuid'].toLowerCase()))
            .toList()
        : tokensToShow;

    final List<Marker> markers = [];

    // Helper function to create markers
    Marker createMarker({
      required dynamic matchingToken,
      double? lat,
      double? lng,
    }) {
      final latValue = lat ?? double.tryParse(matchingToken['lat']?.toString() ?? '');
      final lngValue = lng ?? double.tryParse(matchingToken['lng']?.toString() ?? '');
      final rentedUnits = matchingToken['rentedUnits'] ?? 0;
      final totalUnits = matchingToken['totalUnits'] ?? 1;

      if (latValue != null && lngValue != null) {
        return Marker(
          width: 50.0,
          height: 60.0, // Higher to accommodate the pointer
          point: LatLng(latValue, lngValue),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                print("✅ Click detected on the pointer !");
                _showMarkerPopup(context, matchingToken);
              },
              child: _buildMapPointer(
                matchingToken: matchingToken,
                color: _getMarkerColor(matchingToken),
                rentedUnits: rentedUnits,
                totalUnits: totalUnits,
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

    // Group tokens by unique property (same coordinates)
    Map<String, Map<String, dynamic>> uniqueProperties = {};

    for (var token in displayedTokens) {
      // Verification like in showTokenDetails.dart
      final double? lat = double.tryParse(token['lat']?.toString() ?? '');
      final double? lng = double.tryParse(token['lng']?.toString() ?? '');

      if (lat != null && lng != null) {
        // Create unique key based on coordinates
        final String propertyKey = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';

        if (!uniqueProperties.containsKey(propertyKey)) {
          // First time seeing this property
          uniqueProperties[propertyKey] = {
            ...token,
            'tokens': [token], // List of tokens for this property
            'totalAmount': token['amount'] ?? 0.0,
            'totalValue': token['totalValue'] ?? 0.0,
            'hasWallet': token['source'] == 'wallet',
            'hasRMM': token['source'] != 'wallet',
          };
        } else {
          // Property already exists, add the token
          final existingProperty = uniqueProperties[propertyKey]!;
          (existingProperty['tokens'] as List).add(token);
          existingProperty['totalAmount'] = (existingProperty['totalAmount'] as double) + (token['amount'] ?? 0.0);
          existingProperty['totalValue'] = (existingProperty['totalValue'] as double) + (token['totalValue'] ?? 0.0);

          // Mark if we have wallet or RMM tokens
          if (token['source'] == 'wallet') {
            existingProperty['hasWallet'] = true;
          } else {
            existingProperty['hasRMM'] = true;
          }
        }
      }
    }

    // Create markers for each unique property
    for (var property in uniqueProperties.values) {
      final lat = double.tryParse(property['lat'].toString())!;
      final lng = double.tryParse(property['lng'].toString())!;

      // Determine color based on type of owned tokens
      Color markerColor;
      final hasWallet = property['hasWallet'] as bool;
      final hasRMM = property['hasRMM'] as bool;

      if (hasWallet && hasRMM) {
        markerColor = Colors.purple; // Mixed wallet + RMM
      } else if (hasWallet) {
        markerColor = Colors.green; // Only wallet
      } else {
        markerColor = Colors.blue; // Only RMM
      }

      markers.add(
        createMarker(
          matchingToken: property,
          lat: lat,
          lng: lng,
        ),
      );
    }

    // No markers.isEmpty check here - we always display the map

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Sets background color for the map
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(42.367476, -83.130921),
                initialZoom: 8.0,
                onTap: (_, __) => _popupController.hideAllPopups(),
                onPointerDown: (_, __) => _onMapInteraction(),
                onPointerHover: (_, __) => _onMapInteraction(),
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.scrollWheelZoom),
              ),
              children: [
                TileLayer(
                  // If _forceLightMode is activated, we use light mode
                  urlTemplate: _forceLightMode
                      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                      : Theme.of(context).brightness == Brightness.dark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  tileProvider: kIsWeb
                      ? NetworkTileProvider() // Used only for web
                      : FMTCStore('mapStore').getTileProvider(), // Used for iOS, Android, etc.
                  userAgentPackageName: 'com.byackee.meprop_asset_tracker',
                  retinaMode: true,
                ),
                MarkerClusterLayerWidget(
                  key: ValueKey('markerLayer_${_colorationMode.name}'),
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    disableClusteringAtZoom: 10,
                    size: const Size(50, 50),
                    markers: markers,
                    builder: (context, clusterMarkers) {
                      final clusterStats = _getClusterStats(clusterMarkers, dataManager);
                      final Color clusterColor = clusterStats['color'];
                      final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

                      return GestureDetector(
                        onTap: () {
                          _zoomToCluster(clusterMarkers);
                        },
                        onLongPress: () {
                          _showClusterPopup(context, clusterStats, clusterMarkers.length, dataManager);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                clusterColor.withOpacity(0.9),
                                clusterColor.withOpacity(0.2),
                              ],
                              stops: [0.4, 1.0],
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                clusterMarkers.length.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                ),
                              ),
                              Text(
                                '${clusterStats['averageApy'].toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Switch to toggle between dark/light mode and force light mode for the map
          Positioned(
            top: UIUtils.getAppBarHeight(context),
            right: 16,
            child: Column(
              children: [
                Transform.scale(
                  scale: 0.8, // Reduce switch size to 80%
                  child: CupertinoSwitch(
                    value: _forceLightMode,
                    onChanged: (value) {
                      setState(() {
                        _forceLightMode = value; // Update the switch to force light mode
                      });
                      _saveThemePreference(); // Save the preference
                    },
                    activeColor: Theme.of(context).primaryColor,
                    trackColor: Colors.grey.shade300,
                  ),
                ),
                Text(_forceLightMode ? S.of(context).light_mode : S.of(context).auto_mode),
              ],
            ),
          ),
          // Advanced control panel at top left
          Positioned(
            top: UIUtils.getAppBarHeight(context) + 8,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main controls with opacity animation
                AnimatedOpacity(
                  opacity: _dashboardOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 280, // Fixed width for the panel
                    padding: const EdgeInsets.fromLTRB(8, 4, 4, 4), // Reduced top/bottom and right padding
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Switch for Portfolio / All Tokens with indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.scale(
                                      scale: 0.7,
                                      child: CupertinoSwitch(
                                        value: _showAllTokens,
                                        onChanged: (value) {
                                          setState(() {
                                            _showAllTokens = value;
                                          });
                                        },
                                        activeColor: Theme.of(context).primaryColor,
                                        trackColor: Colors.grey.shade300,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _showAllTokens ? S.of(context).portfolioGlobal : S.of(context).portfolio,
                                          style: TextStyle(
                                              fontSize: 13 +
                                                  Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                              fontWeight: FontWeight.w600,
                                              height: 1.1),
                                        ),
                                        Text(
                                          _showAllTokens
                                              ? '${dataManager.allTokens.length} ${S.of(context).tokens}'
                                              : '${dataManager.portfolio.length} ${S.of(context).tokens}',
                                          style: TextStyle(
                                              fontSize: 11 +
                                                  Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                              color: Colors.grey[600],
                                              height: 1.1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Help button aligned to the right
                                IconButton(
                                  icon: Icon(Icons.help_outline, size: 14),
                                  onPressed: () => _showHelpDialog(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.shade100,
                                    foregroundColor: Colors.blue.shade700,
                                    minimumSize: Size(22, 22),
                                    padding: EdgeInsets.all(2),
                                  ),
                                ),
                              ],
                            ),

                            // Switch for whitelist with indicators
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.7,
                                  child: CupertinoSwitch(
                                    value: _showWhitelistedTokens,
                                    onChanged: (value) {
                                      setState(() {
                                        _showWhitelistedTokens = value;
                                      });
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                    trackColor: Colors.grey.shade300,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showWhitelistedTokens
                                          ? S.of(context).showOnlyWhitelisted
                                          : S.of(context).showAll,
                                      style: TextStyle(
                                          fontSize:
                                              13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                          fontWeight: FontWeight.w600,
                                          height: 1.1),
                                    ),
                                    Text(
                                      _getWhitelistDescription(dataManager),
                                      style: TextStyle(
                                          fontSize:
                                              11 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                          color: Colors.grey[600],
                                          height: 1.1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Advanced control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.filter_list, size: 16),
                                  label: Text(S.of(context).filterOptions,
                                      style: TextStyle(
                                          fontSize:
                                              12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                                  onPressed: () {
                                    setState(() {
                                      _showFiltersPanel = !_showFiltersPanel;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _showFiltersPanel ? Theme.of(context).primaryColor : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(55, 26),
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.dashboard, size: 16),
                                  label: Text(S.of(context).statistics,
                                      style: TextStyle(
                                          fontSize:
                                              12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                                  onPressed: () {
                                    setState(() {
                                      _showMiniDashboard = !_showMiniDashboard;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _showMiniDashboard ? Theme.of(context).primaryColor : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(55, 26),
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  ),
                                ),
                              ],
                            ),
                            // Bouton paramètres aligné à droite
                            IconButton(
                              icon: Icon(Icons.settings, size: 14),
                              onPressed: () => _showMapSettingsDialog(context),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.grey.shade700,
                                minimumSize: Size(22, 22),
                                padding: EdgeInsets.all(2),
                              ),
                              tooltip: "Map Settings",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Advanced filters panel
                if (_showFiltersPanel) ...[
                  const SizedBox(height: 8),
                  _buildFiltersPanel(context, dataManager),
                ],

                // Mini-dashboard (without dimming)
                if (_showMiniDashboard) ...[
                  const SizedBox(height: 8),
                  _buildMiniDashboard(context, dataManager, displayedTokens),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced function to determine cluster color and stats
  Map<String, dynamic> _getClusterStats(List<Marker> markers, DataManager dataManager) {
    int fullyRented = 0;
    int notRented = 0;
    double totalValue = 0;
    double totalRent = 0;
    double totalApy = 0;
    int apyCount = 0;

    for (var marker in markers) {
      if (marker.key is ValueKey) {
        final token = (marker.key as ValueKey).value as Map<String, dynamic>;

        final rentedUnits = token['rentedUnits'] ?? 0;
        final totalUnits = token['totalUnits'] ?? 1;
        final tokenPrice = token['tokenPrice'] ?? 0.0;
        final apy = token['annualPercentageYield'] ?? 0.0;

        // Calculations for statistics
        totalValue += tokenPrice;
        totalRent += _getTokenRentSafely(token['uuid'], dataManager);

        if (apy > 0) {
          totalApy += apy;
          apyCount++;
        }

        // Classification by rental status
        if (rentedUnits == 0) {
          notRented++;
        } else if (rentedUnits == totalUnits) {
          fullyRented++;
        }
      }
    }

    Color clusterColor;
    if (_colorationMode == ColorationMode.apy) {
      // APY mode: use color based on average APY
      final averageApy = apyCount > 0 ? totalApy / apyCount : 0.0;
      clusterColor = _getApyBasedColor(averageApy);
    } else {
      // Default rental mode
      if (fullyRented == markers.length) {
        clusterColor = Colors.green;
      } else if (notRented == markers.length) {
        clusterColor = Colors.red;
      } else {
        clusterColor = Colors.orange;
      }
    }

    return {
      'color': clusterColor,
      'totalValue': totalValue,
      'totalRent': totalRent,
      'averageApy': apyCount > 0 ? totalApy / apyCount : 0.0,
      'fullyRented': fullyRented,
      'notRented': notRented,
      'partiallyRented': markers.length - fullyRented - notRented,
    };
  }

  void _showClusterPopup(
      BuildContext context, Map<String, dynamic> clusterStats, int tokenCount, DataManager dataManager) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('${S.of(context).tokens} ($tokenCount)',
              style: TextStyle(fontSize: 18 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(S.of(context).totalTokens, '$tokenCount', Icons.location_on, Colors.blue),
              const Divider(height: 8),
              _buildInfoRow(
                  S.of(context).totalValue,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(clusterStats['totalValue']), currencyUtils.currencySymbol),
                  Icons.attach_money,
                  Colors.green),
              const Divider(height: 8),
              _buildInfoRow(S.of(context).averageApy, '${clusterStats['averageApy'].toStringAsFixed(2)}%',
                  Icons.trending_up, Colors.orange),
              const Divider(height: 8),
              _buildInfoRow(
                  S.of(context).totalRent,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(clusterStats['totalRent']), currencyUtils.currencySymbol),
                  Icons.account_balance,
                  Colors.purple),
              const Divider(height: 16),
              Text(S.of(context).rentalStatusDistribution,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
              const SizedBox(height: 8),
              _buildInfoRow(
                  S.of(context).fullyRented, '${clusterStats['fullyRented']}', Icons.check_circle, Colors.green),
              _buildInfoRow(S.of(context).partiallyRented, '${clusterStats['partiallyRented']}', Icons.pause_circle,
                  Colors.orange),
              _buildInfoRow(S.of(context).notRented, '${clusterStats['notRented']}', Icons.cancel, Colors.red),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).close),
            ),
          ],
        );
      },
    );
  }

  void _showMarkerPopup(BuildContext context, dynamic matchingToken) {
    // Retrieve DataManager to access portfolio and whitelist
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final bool isInWallet = dataManager.portfolio.any(
      (portfolioItem) => portfolioItem['uuid'].toLowerCase() == matchingToken['uuid'].toLowerCase(),
    );
    final bool isWhitelisted = dataManager.whitelistTokens.any(
      (whitelisted) => whitelisted['token'].toLowerCase() == matchingToken['uuid'].toLowerCase(),
    );

    // Enhanced financial data
    final String tokenId = matchingToken['uuid'].toLowerCase();
    final double totalRentReceived = _getTokenRentSafely(matchingToken['uuid'], dataManager);
    final int walletCount = dataManager.getWalletCountForToken(tokenId);
    final double yamTotalVolume = matchingToken['yamTotalVolume'] ?? 0.0;
    final double yamAverageValue = matchingToken['yamAverageValue'] ?? 0.0;
    final List<Map<String, dynamic>> transactions = dataManager.transactionsByToken[tokenId] ?? [];
    final double initialValue = matchingToken['initialTotalValue'] ?? matchingToken['tokenPrice'];
    final double currentValue = matchingToken['tokenPrice'] ?? 0.0;
    final double roi = initialValue > 0 ? ((currentValue - initialValue) / initialValue * 100) : 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
        final rentedUnits = matchingToken['rentedUnits'] ?? 0;
        final totalUnits = matchingToken['totalUnits'] ?? 1;
        final lat = double.tryParse(matchingToken['lat']) ?? 0.0;
        final lng = double.tryParse(matchingToken['lng']) ?? 0.0;

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          content: SingleChildScrollView(
            child: Column(
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
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    matchingToken['shortName'],
                    style: TextStyle(
                      fontSize: 18 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Basic information
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                            S.of(context).tokenPrice,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(matchingToken['tokenPrice']), currencyUtils.currencySymbol),
                            Icons.monetization_on,
                            Colors.green),
                        const Divider(height: 8),
                        _buildInfoRow(
                            S.of(context).annualPercentageYield,
                            '${matchingToken['annualPercentageYield'] != null ? matchingToken['annualPercentageYield'].toStringAsFixed(2) : 'N/A'}%',
                            Icons.trending_up,
                            Colors.blue),
                        const Divider(height: 8),
                        _buildInfoRow(S.of(context).rentedUnitsSimple, '$rentedUnits / $totalUnits', Icons.home,
                            UIUtils.getRentalStatusColor(rentedUnits, totalUnits)),
                      ],
                    ),
                  ),
                ),

                // Advanced financial data
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.of(context).finances,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            S.of(context).totalRentReceived,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(totalRentReceived), currencyUtils.currencySymbol),
                            Icons.account_balance,
                            Colors.green),
                        const Divider(height: 8),
                        _buildInfoRow(S.of(context).averageROI, '${roi.toStringAsFixed(2)}%', Icons.show_chart,
                            roi >= 0 ? Colors.green : Colors.red),
                        const Divider(height: 8),
                        _buildInfoRow(S.of(context).walletsContainingToken, '$walletCount',
                            Icons.account_balance_wallet, Colors.purple),
                        if (transactions.isNotEmpty) ...[
                          const Divider(height: 8),
                          _buildInfoRow(S.of(context).transactionCount, '${transactions.length}', Icons.swap_horiz,
                              Colors.orange),
                        ],
                      ],
                    ),
                  ),
                ),

                // YAM data if available
                if (yamTotalVolume > 0) ...[
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context).yam,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                              S.of(context).transactionVolume,
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(yamTotalVolume), currencyUtils.currencySymbol),
                              Icons.bar_chart,
                              Colors.indigo),
                          const Divider(height: 8),
                          _buildInfoRow(
                              S.of(context).initialPrice,
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(yamAverageValue), currencyUtils.currencySymbol),
                              Icons.trending_flat,
                              Colors.teal),
                        ],
                      ),
                    ),
                  ),
                ],

                // Portfolio status
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInWallet ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                              color: isInWallet ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isInWallet ? "Présent dans portefeuille" : "Non présent dans portefeuille",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isWhitelisted ? Icons.check_circle : Icons.cancel,
                              color: isWhitelisted ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isWhitelisted ? "Token whitelisté" : "Token non whitelisté",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.info, size: 16),
                      label: Text(S.of(context).details),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showTokenDetails(context, matchingToken);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.streetview, size: 16),
                      label: Text(S.of(context).street_view),
                      onPressed: () {
                        final googleStreetViewUrl =
                            'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat,$lng';
                        UrlUtils.launchURL(googleStreetViewUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
        ),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
      ],
    );
  }

  Widget _buildFiltersPanel(BuildContext context, DataManager dataManager) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
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
          Text(S.of(context).filterOptions,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
          const SizedBox(height: 12),

          // APY filter
          Text('APY ($_minApy% - $_maxApy%)',
              style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
          RangeSlider(
            values: RangeValues(_minApy, _maxApy),
            min: 0,
            max: 50,
            divisions: 50,
            onChanged: (values) {
              setState(() {
                _minApy = values.start;
                _maxApy = values.end;
              });
            },
          ),

          // Boolean filters
          CheckboxListTile(
            title: Text(S.of(context).rents,
                style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
            value: _onlyWithRent,
            onChanged: (value) {
              setState(() {
                _onlyWithRent = value ?? false;
              });
            },
            dense: true,
          ),

          CheckboxListTile(
            title: Text(S.of(context).fullyRented,
                style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
            value: _onlyFullyRented,
            onChanged: (value) {
              setState(() {
                _onlyFullyRented = value ?? false;
              });
            },
            dense: true,
          ),

          // Country filter
          Text(S.of(context).country,
              style: TextStyle(
                  fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: _selectedCountry,
            hint: Text(S.of(context).allCountries,
                style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
            isExpanded: true,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(S.of(context).allCountries,
                    style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
              ),
              ...dataManager.allTokens
                  .map((token) => token['country'])
                  .where((country) => country != null)
                  .toSet()
                  .map((country) => DropdownMenuItem<String>(
                        value: country,
                        child: Text(country,
                            style: TextStyle(
                                fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                      )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
              });
            },
          ),

          // ROI filter
          const SizedBox(height: 8),
          Text('ROI ($_minRoi% - $_maxRoi%)',
              style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
          RangeSlider(
            values: RangeValues(_minRoi, _maxRoi),
            min: -100,
            max: 100,
            divisions: 200,
            onChanged: (values) {
              setState(() {
                _minRoi = values.start;
                _maxRoi = values.end;
              });
            },
          ),

          // Reset button
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _minApy = 0.0;
                  _maxApy = 50.0;
                  _onlyWithRent = false;
                  _onlyFullyRented = false;
                  _selectedCountry = null;
                  _minRoi = -100.0;
                  _maxRoi = 100.0;
                });
              },
              child: Text('Reset',
                  style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(80, 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDashboard(
      BuildContext context, DataManager dataManager, List<Map<String, dynamic>> displayedTokens) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);

    // Calculate unique properties
    Set<String> uniquePropertiesSet = {};
    for (var token in displayedTokens) {
      if (token['lat'] != null && token['lng'] != null) {
        final lat = double.tryParse(token['lat'].toString());
        final lng = double.tryParse(token['lng'].toString());
        if (lat != null && lng != null) {
          uniquePropertiesSet.add('${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}');
        }
      }
    }

    // Calculate statistics
    final int totalTokens = displayedTokens.length;
    final int uniqueProperties = uniquePropertiesSet.length;
    final double totalValue = displayedTokens.fold(0.0, (sum, token) => sum + (token['tokenPrice'] ?? 0.0));
    final double averageApy = displayedTokens.isNotEmpty
        ? displayedTokens.fold(0.0, (sum, token) => sum + (token['annualPercentageYield'] ?? 0.0)) / totalTokens
        : 0.0;
    final double totalRent =
        displayedTokens.fold(0.0, (sum, token) => sum + _getTokenRentSafely(token['uuid'], dataManager));

    final int fullyRented =
        displayedTokens.where((token) => (token['rentedUnits'] ?? 0) >= (token['totalUnits'] ?? 1)).length;
    final int partiallyRented = displayedTokens
        .where((token) => (token['rentedUnits'] ?? 0) > 0 && (token['rentedUnits'] ?? 0) < (token['totalUnits'] ?? 1))
        .length;
    final int notRented = displayedTokens.where((token) => (token['rentedUnits'] ?? 0) == 0).length;

    // Country distribution
    final Map<String, int> countryDistribution = {};
    for (var token in displayedTokens) {
      final country = token['country'] ?? 'Unknown';
      countryDistribution[country] = (countryDistribution[country] ?? 0) + 1;
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
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
          Text(S.of(context).statistics,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 + appState.getTextSizeOffset())),
          const SizedBox(height: 8),

          // Main metrics
          _buildStatRow(S.of(context).tokensInMap, '$totalTokens', Icons.location_on,
              totalTokens == 0 ? Colors.orange : Colors.blue),
          _buildStatRow(S.of(context).totalProperties, '$uniqueProperties', Icons.map, Colors.indigo),
          _buildStatRow(
              S.of(context).totalValue,
              currencyUtils.formatCurrency(currencyUtils.convert(totalValue), currencyUtils.currencySymbol),
              Icons.attach_money,
              Colors.green),
          _buildStatRow(
              S.of(context).averageApy, '${averageApy.toStringAsFixed(2)}%', Icons.trending_up, Colors.orange),
          _buildStatRow(
              S.of(context).totalRent,
              currencyUtils.formatCurrency(currencyUtils.convert(totalRent), currencyUtils.currencySymbol),
              Icons.account_balance,
              Colors.purple),

          const Divider(height: 12),

          // Rental status
          Text(S.of(context).rentalStatus,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14 + appState.getTextSizeOffset())),
          const SizedBox(height: 6),
          _buildStatRow(S.of(context).fullyRented, '$fullyRented', Icons.check_circle, Colors.green),
          _buildStatRow(S.of(context).partiallyRented, '$partiallyRented', Icons.pause_circle, Colors.orange),
          _buildStatRow(S.of(context).notRented, '$notRented', Icons.cancel, Colors.red),

          const Divider(height: 12),

          // Country distribution (top 3)
          Text(S.of(context).country,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14 + appState.getTextSizeOffset())),
          const SizedBox(height: 6),
          ...() {
            final sortedEntries = countryDistribution.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return sortedEntries
                .take(3)
                .map((entry) => _buildStatRow(entry.key, '${entry.value}', Icons.flag, Colors.indigo))
                .toList();
          }(),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color iconColor) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 15 + appState.getTextSizeOffset(), color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
          ),
          Text(value, style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getWhitelistDescription(DataManager dataManager) {
    if (_showWhitelistedTokens) {
      final baseTokens = _showAllTokens ? dataManager.allTokens : dataManager.portfolio;
      final whitelistedCount = baseTokens
          .where((token) =>
              dataManager.whitelistTokens.any((w) => w['token'].toLowerCase() == token['uuid'].toLowerCase()))
          .length;
      return '$whitelistedCount whitelisted ${S.of(context).properties.toLowerCase()}';
    } else {
      final baseCount = _showAllTokens ? dataManager.allTokens.length : dataManager.portfolio.length;
      return '$baseCount available ${S.of(context).properties.toLowerCase()}';
    }
  }

  String _getCurrentModeDescription() {
    if (_showAllTokens && _showWhitelistedTokens) {
      return '🌍 Whitelisted ${S.of(context).properties} (${S.of(context).portfolioGlobal})';
    } else if (_showAllTokens && !_showWhitelistedTokens) {
      return '🌍 All ${S.of(context).properties.toLowerCase()}';
    } else if (!_showAllTokens && _showWhitelistedTokens) {
      return '💼 My whitelisted ${S.of(context).properties.toLowerCase()}';
    } else {
      return '💼 ${S.of(context).portfolio}';
    }
  }

  // Get APY-based color - red to green progression from 0 to 12%
  Color _getApyBasedColor(double apy) {
    if (apy <= 0) return Colors.red.shade700;

    // Distribute red-green from 0 to 12% with fine granularity on 9-12%
    if (apy < 3) {
      // Intense red to red-orange (0-3%)
      final ratio = (apy / 3.0).clamp(0.0, 1.0);
      return Color.lerp(Colors.red.shade700, Colors.deepOrange.shade600, ratio)!;
    } else if (apy < 6) {
      // Red-orange to orange (3-6%)
      final ratio = ((apy - 3) / 3.0).clamp(0.0, 1.0);
      return Color.lerp(Colors.deepOrange.shade600, Colors.orange.shade500, ratio)!;
    } else if (apy < 9.0) {
      // Orange to yellow (6-9%)
      final ratio = ((apy - 6) / 3.0).clamp(0.0, 1.0);
      return Color.lerp(Colors.orange.shade500, Colors.amber.shade600, ratio)!;
    } else if (apy < 9.5) {
      // Yellow to yellow-green (9.0-9.5%) - start fine granularity
      final ratio = ((apy - 9.0) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.amber.shade600, Colors.lime.shade500, ratio)!;
    } else if (apy < 10.0) {
      // Yellow-green to light green (9.5-10.0%)
      final ratio = ((apy - 9.5) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.lime.shade500, Colors.lightGreen.shade500, ratio)!;
    } else if (apy < 10.5) {
      // Light green to green (10.0-10.5%)
      final ratio = ((apy - 10.0) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.lightGreen.shade500, Colors.green.shade500, ratio)!;
    } else if (apy < 11.0) {
      // Green to medium green (10.5-11.0%)
      final ratio = ((apy - 10.5) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.green.shade500, Colors.green.shade600, ratio)!;
    } else if (apy < 11.5) {
      // Medium green to dark green (11.0-11.5%)
      final ratio = ((apy - 11.0) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.green.shade600, Colors.green.shade700, ratio)!;
    } else if (apy < 12.0) {
      // Dark green to very dark green (11.5-12.0%)
      final ratio = ((apy - 11.5) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.green.shade700, Colors.green.shade800, ratio)!;
    } else {
      // Excellence green for 12%+
      return Colors.green.shade900;
    }
  }

  // Get marker color according to coloration mode
  Color _getMarkerColor(Map<String, dynamic> token) {
    if (_colorationMode == ColorationMode.apy) {
      final apy = token['annualPercentageYield'] ?? 0.0;
      return _getApyBasedColor(apy);
    } else {
      // Default rental mode
      final rentedUnits = token['rentedUnits'] ?? 0;
      final totalUnits = token['totalUnits'] ?? 1;
      return UIUtils.getRentalStatusColor(rentedUnits, totalUnits);
    }
  }

  // Map settings dialog
  void _showMapSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.settings, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text("Map Settings"),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Coloration Mode",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rental option
                  RadioListTile<ColorationMode>(
                    title: Text("Rental Status"),
                    subtitle: Text("Colors based on rental rate"),
                    value: ColorationMode.rental,
                    groupValue: _colorationMode,
                    onChanged: (value) {
                      setDialogState(() {
                        _colorationMode = value!;
                      });
                      setState(() {});
                      _saveColorationModePreference(); // Save the choice
                    },
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                        const SizedBox(width: 4),
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange)),
                        const SizedBox(width: 4),
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
                      ],
                    ),
                  ),

                  // APY option
                  RadioListTile<ColorationMode>(
                    title: Text("APY Yield"),
                    subtitle: Text("Red→Green (0-12%), granularity 0.5% on 9-12%"),
                    value: ColorationMode.apy,
                    groupValue: _colorationMode,
                    onChanged: (value) {
                      setDialogState(() {
                        _colorationMode = value!;
                      });
                      setState(() {});
                      _saveColorationModePreference(); // Save the choice
                    },
                    secondary: Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade700, // 0-3%
                            Colors.deepOrange.shade600, // 3-6%
                            Colors.orange.shade500, // 6-9%
                            Colors.amber.shade600, // 9-9.5%
                            Colors.lime.shade500, // 9.5-10%
                            Colors.lightGreen.shade500, // 10-10.5%
                            Colors.green.shade500, // 10.5-11%
                            Colors.green.shade600, // 11-11.5%
                            Colors.green.shade700, // 11.5-12%
                            Colors.green.shade900, // 12%+
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('Display Modes Guide'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('The 4 available modes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildHelpRow('💼 ${S.of(context).portfolio}',
                    'Shows only your ${S.of(context).properties.toLowerCase()}', 'OFF + OFF'),
                const Divider(),
                _buildHelpRow('💼 My whitelisted ${S.of(context).properties.toLowerCase()}',
                    'Your ${S.of(context).properties.toLowerCase()} in the whitelist', 'OFF + ON'),
                const Divider(),
                _buildHelpRow('🌍 All ${S.of(context).properties.toLowerCase()}',
                    'All ${S.of(context).properties.toLowerCase()} on the market', 'ON + OFF'),
                const Divider(),
                _buildHelpRow('🌍 Global whitelisted ${S.of(context).properties}',
                    'All whitelisted ${S.of(context).properties.toLowerCase()}', 'ON + ON'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Tips:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text('• Use filters to refine analysis',
                          style: TextStyle(
                              fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                      Text('• Click Stats to see metrics',
                          style: TextStyle(
                              fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                      Text('• Clusters show count + average APY',
                          style: TextStyle(
                              fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpRow(String title, String description, String switches) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
          const SizedBox(height: 2),
          Text(description,
              style: TextStyle(
                  fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text('Switches: $switches',
              style: TextStyle(
                  fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  // Widget pour créer un pointeur de carte personnalisé avec photo
  Widget _buildMapPointer({
    required dynamic matchingToken,
    required Color color,
    required int rentedUnits,
    required int totalUnits,
  }) {
    // Use the calculated color according to the chosen coloration mode
    final markerColor = color;

    // Validation et nettoyage de l'URL d'image
    String? getValidImageUrl() {
      try {
        if (matchingToken['imageLink'] == null) {
          debugPrint("⚠️ imageLink est null pour ${matchingToken['shortName']}");
          return null;
        }

        var imageLink = matchingToken['imageLink'];
        String? imageUrl;

        if (imageLink is List && imageLink.isNotEmpty) {
          imageUrl = imageLink[0]?.toString();
        } else if (imageLink is String && imageLink.isNotEmpty) {
          imageUrl = imageLink;
        }

        if (imageUrl == null || imageUrl.isEmpty) {
          debugPrint("⚠️ URL d'image vide pour ${matchingToken['shortName']}");
          return null;
        }

        // Vérifier si l'URL est valide
        final uri = Uri.tryParse(imageUrl);
        if (uri == null || (!uri.hasScheme || (!uri.scheme.startsWith('http')))) {
          debugPrint("⚠️ URL d'image invalide pour ${matchingToken['shortName']}: $imageUrl");
          return null;
        }

        debugPrint("✅ URL d'image valide pour ${matchingToken['shortName']}: $imageUrl");
        return imageUrl;
      } catch (e) {
        debugPrint("❌ Erreur lors de la validation de l'image pour ${matchingToken['shortName']}: $e");
        return null;
      }
    }

    final String? validImageUrl = getValidImageUrl();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Ombre du pointeur
        Positioned(
          top: 2,
          child: Container(
            width: 36,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),

        // Corps principal du pointeur
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cercle avec la photo (décalé vers le bas)
            Transform.translate(
              offset: Offset(0, 1.5), // Décale le cercle de 3 pixels vers le bas
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: markerColor,
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: validImageUrl != null
                      ? kIsWeb
                          ? ShowNetworkImage(
                              imageSrc: validImageUrl,
                              mobileBoxFit: BoxFit.cover,
                              mobileWidth: 30,
                              mobileHeight: 30,
                            )
                          : CachedNetworkImage(
                              imageUrl: validImageUrl,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration(milliseconds: 300),
                              fadeOutDuration: Duration(milliseconds: 100),
                              placeholder: (context, url) => Container(
                                color: markerColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.home,
                                  color: markerColor.withOpacity(0.7),
                                  size: 16,
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint("❌ Erreur chargement image pour ${matchingToken['shortName']}: $error");
                                return Container(
                                  color: markerColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.home,
                                    color: markerColor,
                                    size: 20,
                                  ),
                                );
                              },
                              // Add headers to bypass potential CORS issues
                              httpHeaders: {
                                'User-Agent': 'Mozilla/5.0 (compatible; RealTokenApp/1.0)',
                              },
                            )
                      : Container(
                          color: markerColor.withOpacity(0.1),
                          child: Icon(
                            Icons.home,
                            color: markerColor,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ),

            // Pointe du pointeur
            CustomPaint(
              size: Size(16, 12),
              painter: _PointerTipPainter(markerColor),
            ),
          ],
        ),
      ],
    );
  }
}

// Painter personnalisé pour dessiner la pointe du pointeur
class _PointerTipPainter extends CustomPainter {
  final Color color;

  _PointerTipPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Créer la forme triangulaire de la pointe
    final path = ui.Path();
    path.moveTo(size.width / 2, size.height); // Point bas (pointe)
    path.lineTo(0, 0); // Point haut gauche
    path.lineTo(size.width, 0); // Point haut droit
    path.close();

    // Ombre de la pointe
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final shadowPath = ui.Path();
    shadowPath.moveTo(size.width / 2 + 1, size.height + 1);
    shadowPath.lineTo(1, 1);
    shadowPath.lineTo(size.width + 1, 1);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
