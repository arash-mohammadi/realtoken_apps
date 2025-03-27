import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import des fichiers de graphiques
import 'charts/apy_graph.dart';
import 'charts/rent_graph.dart';
import 'charts/roi_graph.dart';
import 'charts/wallet_balance_graph.dart';
import 'charts/rent_distribution_by_wallet_chart.dart';

class WalletStats extends StatefulWidget {
  const WalletStats({super.key});

  @override
  _WalletStats createState() => _WalletStats();
}

class _WalletStats extends State<WalletStats> {
  late String _selectedRentPeriod;
  late String _selectedWalletPeriod;
  late String _selectedRoiPeriod;
  late String _selectedApyPeriod;
  String _selectedApyTimeRange = 'all';
  String _selectedWalletTimeRange = 'all';
  String _selectedRoiTimeRange = 'all';
  String _selectedRentTimeRange = 'all';

  bool apyIsBarChart = true;
  bool roiIsBarChart = false;
  bool walletIsBarChart = false;
  bool rentIsBarChart = false;
  bool showCumulativeRent = false;
  late SharedPreferences prefs;

  int _walletTimeOffset = 0;
  int _roiTimeOffset = 0;
  int _apyTimeOffset = 0;
  int _rentTimeOffset = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();

      setState(() {
        // Charger les types de graphiques
        apyIsBarChart = prefs.getBool('apyIsBarChart') ?? true;
        roiIsBarChart = prefs.getBool('roiIsBarChart') ?? false;
        walletIsBarChart = prefs.getBool('walletIsBarChart') ?? false;
        rentIsBarChart = prefs.getBool('rentIsBarChart') ?? false;
        showCumulativeRent = prefs.getBool('showCumulativeRent') ?? false;
        
        // Charger les périodes sélectionnées
        _selectedRentPeriod = prefs.getString('rentPeriod') ?? S.of(context).week;
        _selectedWalletPeriod = prefs.getString('walletPeriod') ?? S.of(context).week;
        _selectedRoiPeriod = prefs.getString('roiPeriod') ?? S.of(context).week;
        _selectedApyPeriod = prefs.getString('apyPeriod') ?? S.of(context).week;
        
        // Charger les plages de temps
        _selectedRentTimeRange = prefs.getString('rentTimeRange') ?? 'all';
        _selectedWalletTimeRange = prefs.getString('walletTimeRange') ?? 'all';
        _selectedRoiTimeRange = prefs.getString('roiTimeRange') ?? 'all';
        _selectedApyTimeRange = prefs.getString('apyTimeRange') ?? 'all';
        
        // Charger les offsets
        _rentTimeOffset = prefs.getInt('rentTimeOffset') ?? 0;
        _walletTimeOffset = prefs.getInt('walletTimeOffset') ?? 0;
        _roiTimeOffset = prefs.getInt('roiTimeOffset') ?? 0;
        _apyTimeOffset = prefs.getInt('apyTimeOffset') ?? 0;
      });

      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);
        
        // Vérifier si les données sont déjà disponibles
        if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && 
            dataManager.walletBalanceHistory.isNotEmpty && dataManager.roiHistory.isNotEmpty &&
            dataManager.apyHistory.isNotEmpty) {
          debugPrint("📈 WalletStats: données déjà chargées, skip chargement");
          // Vérifier si les données de propriétés doivent être chargées
          if (dataManager.propertyData.isEmpty) {
            dataManager.fetchPropertyData();
          }
        } else {
          debugPrint("📈 WalletStats: chargement des données nécessaire");
          await DataFetchUtils.loadDataWithCache(context);
          dataManager.fetchPropertyData();
        }
      } catch (e, stacktrace) {
        debugPrint("Error during initState: $e");
        debugPrint("Stacktrace: $stacktrace");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ne pas initialiser les périodes ici car elles sont chargées depuis les préférences
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;
    final double fixedCardHeight = 380;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 80.0, left: 8.0, right: 8.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 2 : 1,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                mainAxisExtent: fixedCardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  switch (index) {
                    case 0:
                      return RentGraph(
                        groupedData: [],
                        dataManager: dataManager,
                        showCumulativeRent: showCumulativeRent,
                        selectedPeriod: _selectedRentPeriod,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedRentPeriod = period;
                            _savePeriodPreference('rentPeriod', period);
                          });
                        },
                        onCumulativeRentChanged: (value) {
                          setState(() {
                            showCumulativeRent = value;
                            _saveChartPreference('showCumulativeRent', showCumulativeRent);
                          });
                        },
                        selectedTimeRange: _selectedRentTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            _selectedRentTimeRange = newRange;
                            _saveTimeRangePreference('rentTimeRange', newRange);
                            _rentTimeOffset = 0; // Réinitialiser l'offset lors d'un changement de plage
                            _saveTimeOffsetPreference('rentTimeOffset', 0);
                          });
                        },
                        timeOffset: _rentTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            _rentTimeOffset = newOffset;
                            _saveTimeOffsetPreference('rentTimeOffset', newOffset);
                          });
                        },
                        rentIsBarChart: rentIsBarChart,
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            rentIsBarChart = isBarChart;
                            _saveChartPreference('rentIsBarChart', rentIsBarChart);
                          });
                        },
                      );
                    case 1:
                      return RentDistributionByWalletChart(
                        dataManager: dataManager,
                      );
                    case 2:
                      return WalletBalanceGraph(
                        selectedPeriod: _selectedWalletPeriod,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedWalletPeriod = period;
                            _savePeriodPreference('walletPeriod', period);
                          });
                        },
                        balanceIsBarChart: walletIsBarChart,
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            walletIsBarChart = isBarChart;
                            _saveChartPreference('walletIsBarChart', walletIsBarChart);
                          });
                        },
                        selectedTimeRange: _selectedWalletTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            _selectedWalletTimeRange = newRange;
                            _saveTimeRangePreference('walletTimeRange', newRange);
                            _walletTimeOffset = 0;
                            _saveTimeOffsetPreference('walletTimeOffset', 0);
                          });
                        },
                        timeOffset: _walletTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            _walletTimeOffset = newOffset;
                            _saveTimeOffsetPreference('walletTimeOffset', newOffset);
                          });
                        },
                      );
                    case 3:
                      return RoiHistoryGraph(
                        selectedPeriod: _selectedRoiPeriod,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedRoiPeriod = period;
                            _savePeriodPreference('roiPeriod', period);
                          });
                        },
                        roiIsBarChart: roiIsBarChart,
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            roiIsBarChart = isBarChart;
                            _saveChartPreference('roiIsBarChart', roiIsBarChart);
                          });
                        },
                        selectedTimeRange: _selectedRoiTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            _selectedRoiTimeRange = newRange;
                            _saveTimeRangePreference('roiTimeRange', newRange);
                            _roiTimeOffset = 0; // Réinitialiser l'offset lors d'un changement de plage
                            _saveTimeOffsetPreference('roiTimeOffset', 0);
                          });
                        },
                        timeOffset: _roiTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            _roiTimeOffset = newOffset;
                            _saveTimeOffsetPreference('roiTimeOffset', newOffset);
                          });
                        },
                      );
                    case 4:
                      return ApyHistoryGraph(
                        dataManager: dataManager,
                        selectedPeriod: _selectedApyPeriod,
                        apyIsBarChart: apyIsBarChart,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedApyPeriod = period;
                            _savePeriodPreference('apyPeriod', period);
                          });
                        },
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            apyIsBarChart = isBarChart;
                            _saveChartPreference('apyIsBarChart', apyIsBarChart);
                          });
                        },
                        selectedTimeRange: _selectedApyTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            _selectedApyTimeRange = newRange;
                            _saveTimeRangePreference('apyTimeRange', newRange);
                            _apyTimeOffset = 0; // Réinitialiser l'offset lors d'un changement de plage
                            _saveTimeOffsetPreference('apyTimeOffset', 0);
                          });
                        },
                        timeOffset: _apyTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            _apyTimeOffset = newOffset;
                            _saveTimeOffsetPreference('apyTimeOffset', newOffset);
                          });
                        },
                      );
                    default:
                      return Container();
                  }
                },
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes pour sauvegarder les différentes préférences
  void _saveChartPreference(String key, bool value) {
    prefs.setBool(key, value);
  }
  
  void _savePeriodPreference(String key, String value) {
    prefs.setString(key, value);
  }
  
  void _saveTimeRangePreference(String key, String value) {
    prefs.setString(key, value);
  }
  
  void _saveTimeOffsetPreference(String key, int value) {
    prefs.setInt(key, value);
  }
}
