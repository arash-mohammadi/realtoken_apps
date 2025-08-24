// Google Maps implementation for the Maps page
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/managers/data_manager.dart';
import 'package:meprop_asset_tracker/utils/currency_utils.dart';
import 'package:meprop_asset_tracker/utils/ui_utils.dart';
import 'package:meprop_asset_tracker/modals/token_details/showTokenDetails.dart';
import 'package:meprop_asset_tracker/app_state.dart';

enum ColorationMode { rental, apy }

class MapsPageGoogle extends StatefulWidget {
  const MapsPageGoogle({super.key});
  @override
  State<MapsPageGoogle> createState() => _MapsPageGoogleState();
}

class _MapsPageGoogleState extends State<MapsPageGoogle> {
  GoogleMapController? _googleMapController;
  Timer? _fadeTimer;

  double _minApy = 0, _maxApy = 50;
  double _minRoi = -100, _maxRoi = 100;
  bool _onlyWithRent = false, _onlyFullyRented = false;
  String? _selectedCountry;
  bool _showAllTokens = false, _showWhitelistedTokens = false;
  bool _forceLightMode = false;
  bool _showFiltersPanel = false, _showMiniDashboard = false;
  double _dashboardOpacity = 1.0;
  ColorationMode _colorationMode = ColorationMode.rental;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _fadeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _forceLightMode = prefs.getBool('maps_force_light') ?? false;
      final mode = prefs.getString('maps_coloration_mode') ?? 'rental';
      _colorationMode = mode == 'apy' ? ColorationMode.apy : ColorationMode.rental;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('maps_force_light', _forceLightMode);
    await prefs.setString('maps_coloration_mode', _colorationMode == ColorationMode.apy ? 'apy' : 'rental');
  }

  void _onMapInteraction() {
    // Avoid updating widget tree during pointer device update by deferring
    // the state changes to the next frame.
    _fadeTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _dashboardOpacity = 1.0);
      _fadeTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _dashboardOpacity = 0.0);
      });
    });
  }

  Color _apyColor(double apy) {
    final t = (apy.clamp(0.0, 50.0)) / 50.0;
    if (t < 0.33) return Color.lerp(Colors.blue, Colors.green, t / 0.33)!;
    if (t < 0.66) return Color.lerp(Colors.green, Colors.orange, (t - 0.33) / 0.33)!;
    return Color.lerp(Colors.orange, Colors.red, (t - 0.66) / 0.34)!;
  }

  Color _markerColor(Map<String, dynamic> prop) {
    if (_colorationMode == ColorationMode.apy) {
      final tokens = (prop['tokens'] as List).cast<Map<String, dynamic>>();
      if (tokens.isEmpty) return Colors.blue;
      final avg = tokens.fold<double>(0.0, (s, t) => s + ((t['annualPercentageYield'] ?? 0.0) as num)) / tokens.length;
      return _apyColor(avg);
    }
    final tokens = (prop['tokens'] as List).cast<Map<String, dynamic>>();
    if (tokens.isEmpty) return Colors.blue;
    final first = tokens.first;
    final rentedUnits = ((first['rentedUnits'] ?? 0) as num).toInt();
    final totalUnits = ((first['totalUnits'] ?? 1) as num).toInt();
    return UIUtils.getRentalStatusColor(rentedUnits, totalUnits);
  }

  double _tokenRent(String uuid, DataManager dm) {
    try {
      final tx = dm.transactionsByToken[uuid] ?? [];
      return tx.fold<double>(0.0, (s, t) => s + ((t['amount'] ?? 0) as num).toDouble());
    } catch (_) {
      return 0.0;
    }
  }

  List<Map<String, dynamic>> _filterAndSort(List<dynamic> source, DataManager dm) {
    final tokens = source.cast<Map<String, dynamic>>();
    final out = tokens.where((t) {
      final apy = ((t['annualPercentageYield'] ?? 0) as num).toDouble();
      if (apy < _minApy || apy > _maxApy) return false;
      final lat = double.tryParse(t['lat']?.toString() ?? '');
      final lng = double.tryParse(t['lng']?.toString() ?? '');
      if (lat == null || lng == null) return false;
      if (_onlyWithRent && _tokenRent(t['uuid'], dm) <= 0) return false;
      final rented = ((t['rentedUnits'] ?? 0) as num).toInt();
      final total = ((t['totalUnits'] ?? 1) as num).toInt();
      if (_onlyFullyRented && rented < total) return false;
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty && (t['country'] ?? '') != _selectedCountry)
        return false;
      final init = ((t['initialTotalValue'] ?? t['tokenPrice'] ?? 0) as num).toDouble();
      final cur = ((t['tokenPrice'] ?? 0) as num).toDouble();
      final roi = init > 0 ? ((cur - init) / init * 100) : 0.0;
      if (roi < _minRoi || roi > _maxRoi) return false;
      return true;
    }).toList();

    if (_showWhitelistedTokens) {
      return out
          .where((t) => dm.whitelistTokens
              .any((w) => (w['token'] ?? '').toString().toLowerCase() == (t['uuid'] ?? '').toString().toLowerCase()))
          .toList();
    }

    out.sort((a, b) => (((b['totalValue'] ?? 0) as num).compareTo((a['totalValue'] ?? 0) as num)));
    return out;
  }

  void _showPopup(BuildContext ctx, Map<String, dynamic> prop) {
    final dm = Provider.of<DataManager>(ctx, listen: false);
    final tokens = (prop['tokens'] as List).cast<Map<String, dynamic>>();
    final primary = tokens.isNotEmpty ? tokens.first : <String, dynamic>{};
    final rent = _tokenRent(primary['uuid'] ?? '', dm);
    final currency = Provider.of<CurrencyProvider>(ctx, listen: false);

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (primary['imageLink'] != null)
              CachedNetworkImage(imageUrl: primary['imageLink'][0], width: 200, fit: BoxFit.cover),
            const SizedBox(height: 8),
            Text(primary['shortName'] ?? '',
                style: TextStyle(
                    fontSize: 18 + Provider.of<AppState>(ctx, listen: false).getTextSizeOffset(),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _infoRow(
                S.of(ctx).tokenPrice,
                currency.formatCurrency(currency.convert(primary['tokenPrice'] ?? 0), currency.currencySymbol),
                Icons.monetization_on,
                Colors.green),
            const SizedBox(height: 8),
            _infoRow(
                S.of(ctx).totalRentReceived,
                currency.formatCurrency(currency.convert(rent), currency.currencySymbol),
                Icons.account_balance,
                Colors.purple),
            const SizedBox(height: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.info),
                label: Text(S.of(ctx).details),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showTokenDetails(ctx, primary);
                })
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, Color c) {
    final app = Provider.of<AppState>(context, listen: false);
    return Row(children: [
      Icon(icon, size: 16 + app.getTextSizeOffset(), color: c),
      const SizedBox(width: 8),
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
    ]);
  }

  Widget _buildFiltersPanel(BuildContext context, DataManager dataManager) {
    final app = Provider.of<AppState>(context, listen: false);
    final countries =
        dataManager.allTokens.map((t) => t['country'] ?? '').where((c) => (c ?? '').isNotEmpty).toSet().toList();

    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(S.of(context).filterOptions,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 + app.getTextSizeOffset())),
        const SizedBox(height: 8),
        Text('APY', style: TextStyle(fontSize: 12 + app.getTextSizeOffset())),
        RangeSlider(
            values: RangeValues(_minApy, _maxApy),
            min: 0,
            max: 50,
            divisions: 50,
            onChanged: (r) => setState(() {
                  _minApy = r.start;
                  _maxApy = r.end;
                })),
        CheckboxListTile(
            title: Text(S.of(context).rents),
            value: _onlyWithRent,
            onChanged: (v) => setState(() => _onlyWithRent = v ?? false),
            dense: true),
        CheckboxListTile(
            title: Text(S.of(context).fullyRented),
            value: _onlyFullyRented,
            onChanged: (v) => setState(() => _onlyFullyRented = v ?? false),
            dense: true),
        const SizedBox(height: 8),
        Text(S.of(context).country,
            style: TextStyle(fontSize: 12 + app.getTextSizeOffset(), fontWeight: FontWeight.w500)),
        DropdownButton<String?>(
            value: _selectedCountry,
            hint: Text(S.of(context).allCountries),
            items: [
              DropdownMenuItem(value: null, child: Text(S.of(context).allCountries)),
              ...countries.map((c) => DropdownMenuItem(value: c, child: Text(c)))
            ],
            onChanged: (v) => setState(() => _selectedCountry = v)),
        const SizedBox(height: 8),
        Text('ROI', style: TextStyle(fontSize: 12 + app.getTextSizeOffset())),
        RangeSlider(
            values: RangeValues(_minRoi, _maxRoi),
            min: -100,
            max: 100,
            divisions: 200,
            onChanged: (r) => setState(() {
                  _minRoi = r.start;
                  _maxRoi = r.end;
                })),
        const SizedBox(height: 8),
        Center(
            child: ElevatedButton(
                child: Text('Reset'),
                onPressed: () => setState(() {
                      _minApy = 0;
                      _maxApy = 50;
                      _onlyWithRent = false;
                      _onlyFullyRented = false;
                      _selectedCountry = null;
                      _minRoi = -100;
                      _maxRoi = 100;
                    }))),
      ]),
    );
  }

  Widget _buildMiniDashboard(
      BuildContext context, DataManager dataManager, List<Map<String, dynamic>> displayedTokens) {
    final currency = Provider.of<CurrencyProvider>(context, listen: false);
    final app = Provider.of<AppState>(context, listen: false);
    final unique = <String>{};
    for (var t in displayedTokens) {
      if (t['lat'] != null && t['lng'] != null) {
        final lat = double.tryParse(t['lat'].toString());
        final lng = double.tryParse(t['lng'].toString());
        if (lat != null && lng != null) unique.add('${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}');
      }
    }

    final totalTokens = displayedTokens.length;
    final uniqueProps = unique.length;
    final totalValue = displayedTokens.fold(0.0, (s, t) => s + ((t['tokenPrice'] ?? 0) as num));
    final avgApy = displayedTokens.isNotEmpty
        ? displayedTokens.fold(0.0, (s, t) => s + ((t['annualPercentageYield'] ?? 0) as num)) / totalTokens
        : 0.0;
    final totalRent = displayedTokens.fold(0.0, (s, t) => s + _tokenRent(t['uuid'], dataManager));

    return Container(
      width: 320,
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(S.of(context).statistics,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 + app.getTextSizeOffset())),
        const SizedBox(height: 8),
        _infoRow(S.of(context).tokensInMap, '$totalTokens', Icons.location_on, Colors.blue),
        _infoRow(S.of(context).totalProperties, '$uniqueProps', Icons.map, Colors.indigo),
        _infoRow(
            S.of(context).totalValue,
            currency.formatCurrency(currency.convert(totalValue), currency.currencySymbol),
            Icons.attach_money,
            Colors.green),
        _infoRow(S.of(context).averageApy, '${avgApy.toStringAsFixed(2)}%', Icons.trending_up, Colors.orange),
        _infoRow(S.of(context).totalRent, currency.formatCurrency(currency.convert(totalRent), currency.currencySymbol),
            Icons.account_balance, Colors.purple),
      ]),
    );
  }

  void _showMapSettings(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(S.of(ctx).maps),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          RadioListTile<ColorationMode>(
              value: ColorationMode.rental,
              groupValue: _colorationMode,
              title: const Text('Rental Status'),
              onChanged: (v) {
                setState(() => _colorationMode = v!);
              }),
          RadioListTile<ColorationMode>(
              value: ColorationMode.apy,
              groupValue: _colorationMode,
              title: const Text('APY'),
              onChanged: (v) {
                setState(() => _colorationMode = v!);
              }),
          SwitchListTile(
              value: _forceLightMode,
              title: Text(S.of(ctx).light_mode),
              onChanged: (v) => setState(() => _forceLightMode = v)),
        ]),
        actions: [
          TextButton(
              onPressed: () {
                _savePreferences();
                Navigator.of(ctx).pop();
              },
              child: Text(S.of(ctx).save))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dm = Provider.of<DataManager>(context);
    final source = _showAllTokens ? dm.allTokens : dm.portfolio;
    final tokens = _filterAndSort(source, dm);

    final Map<String, Map<String, dynamic>> props = {};
    for (var t in tokens) {
      final lat = double.tryParse(t['lat']?.toString() ?? '');
      final lng = double.tryParse(t['lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      final key = '${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';
      if (!props.containsKey(key))
        props[key] = {
          ...t,
          'tokens': [t],
          'totalValue': t['totalValue'] ?? 0.0
        };
      else {
        (props[key]!['tokens'] as List).add(t);
        props[key]!['totalValue'] = (props[key]!['totalValue'] as num) + (t['totalValue'] ?? 0.0);
      }
    }

    final markers = props.values.map((p) {
      final lat = double.tryParse(p['lat'].toString()) ?? 0.0;
      final lng = double.tryParse(p['lng'].toString()) ?? 0.0;
      final color = _markerColor(p);
      final hue = HSVColor.fromColor(color).hue;
      return Marker(
          markerId: MarkerId(p['uuid'] ?? p.hashCode.toString()),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () => _showPopup(context, p));
    }).toSet();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(42.367476, -83.130921), zoom: 5.5),
            onMapCreated: (c) => _googleMapController = c,
            markers: markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onTap: (_) => _onMapInteraction(),
          ),

          // Right top switch for light mode
          Positioned(
            top: UIUtils.getAppBarHeight(context),
            right: 16,
            child: Column(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: _forceLightMode,
                    onChanged: (v) {
                      setState(() => _forceLightMode = v);
                      _savePreferences();
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                Text(_forceLightMode ? S.of(context).light_mode : S.of(context).auto_mode),
              ],
            ),
          ),

          // Left top dashboard and filters
          Positioned(
            top: UIUtils.getAppBarHeight(context) + 8,
            left: 8,
            child: AnimatedOpacity(
              opacity: _dashboardOpacity,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                              value: _showAllTokens, onChanged: (v) => setState(() => _showAllTokens = v)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_showAllTokens ? S.of(context).portfolioGlobal : S.of(context).portfolio)),
                      ],
                    ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                              value: _showWhitelistedTokens,
                              onChanged: (v) => setState(() => _showWhitelistedTokens = v)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                                _showWhitelistedTokens ? S.of(context).showOnlyWhitelisted : S.of(context).showAll)),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ElevatedButton.icon(
                            icon: const Icon(Icons.filter_list),
                            label: Text(S.of(context).filterOptions),
                            onPressed: () => setState(() => _showFiltersPanel = !_showFiltersPanel)),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.dashboard),
                            label: Text(S.of(context).statistics),
                            onPressed: () => setState(() => _showMiniDashboard = !_showMiniDashboard)),
                        IconButton(icon: const Icon(Icons.settings), onPressed: () => _showMapSettings(context)),
                      ],
                    ),
                    if (_showFiltersPanel) const SizedBox(height: 8),
                    if (_showFiltersPanel) _buildFiltersPanel(context, dm),
                    if (_showMiniDashboard) const SizedBox(height: 8),
                    if (_showMiniDashboard) _buildMiniDashboard(context, dm, tokens),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
