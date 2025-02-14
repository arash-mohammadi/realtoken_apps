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
import 'graphs/apy_graph.dart';
import 'graphs/rent_graph.dart';
import 'graphs/roi_graph.dart';
import 'graphs/wallet_balance_graph.dart';

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

  bool apyIsBarChart = true;
  bool roiIsBarChart = false;
  bool walletIsBarChart = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();

      setState(() {
        apyIsBarChart = prefs.getBool('apyIsBarChart') ?? true;
        roiIsBarChart = prefs.getBool('roiIsBarChart') ?? false;
        walletIsBarChart = prefs.getBool('walletIsBarChart') ?? false;
      });

      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);
        DataFetchUtils.loadData(context);
        dataManager.fetchPropertyData();
      } catch (e, stacktrace) {
        debugPrint("Error during initState: $e");
        debugPrint("Stacktrace: $stacktrace");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedRentPeriod = S.of(context).week;
    _selectedWalletPeriod = S.of(context).week;
    _selectedRoiPeriod = S.of(context).week;
    _selectedApyPeriod = S.of(context).week;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    List<Map<String, dynamic>> groupedData = _groupRentDataByPeriod(dataManager);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;
    final double fixedCardHeight = 380;
    bool showCumulativeRent = false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 80.0, left: 8.0, right: 8.0),
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
                        groupedData: groupedData,
                        dataManager: dataManager,
                        showCumulativeRent: showCumulativeRent,
                        selectedPeriod: _selectedRentPeriod,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedRentPeriod = period;
                          });
                        },
                        onCumulativeRentChanged: (value) {
                          setState(() {
                            showCumulativeRent = value;
                          });
                        },
                      );

                    case 1:
                      return WalletBalanceGraph(
                        dataManager: dataManager,
                        selectedPeriod: _selectedWalletPeriod,
                        isBarChart: walletIsBarChart,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedWalletPeriod = period;
                          });
                        },
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            walletIsBarChart = isBarChart;
                            _saveChartPreference('walletIsBarChart', walletIsBarChart);
                          });
                        },
                      );
                    case 2:
                      return RoiHistoryGraph(
                        selectedPeriod: _selectedRoiPeriod,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedRoiPeriod = period;
                          });
                        },
                        roiIsBarChart: roiIsBarChart,
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            roiIsBarChart = isBarChart;
                            _saveChartPreference('roiIsBarChart', roiIsBarChart);
                          });
                        },
                      );
                    case 3:
                      return ApyHistoryGraph(
                        dataManager: dataManager,
                        selectedPeriod: _selectedApyPeriod,
                        apyIsBarChart: apyIsBarChart, // Utilisation du bon paramètre
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedApyPeriod = period;
                          });
                        },
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            apyIsBarChart = isBarChart;
                            _saveChartPreference('apyIsBarChart', apyIsBarChart);
                          });
                        },
                      );

                    default:
                      return Container();
                  }
                },
                childCount: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupRentDataByPeriod(DataManager dataManager) {
    if (_selectedRentPeriod == S.of(context).day) {
      return _groupByDay(dataManager.rentData); // Ajouter une méthode _groupByDay
    } else if (_selectedRentPeriod == S.of(context).week) {
      return _groupByWeek(dataManager.rentData);
    } else if (_selectedRentPeriod == S.of(context).month) {
      return _groupByMonth(dataManager.rentData);
    } else {
      return _groupByYear(dataManager.rentData);
    }
  }

  List<Map<String, dynamic>> _groupByDay(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String dayKey = DateFormat('yyyy/MM/dd').format(date); // Format jour
      groupedData[dayKey] = (groupedData[dayKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByWeek(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};

    for (var entry in data) {
      if (entry.containsKey('date') && entry.containsKey('rent')) {
        try {
          DateTime date = DateTime.parse(entry['date']);
          String weekKey = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}"; // Semaine formatée avec deux chiffres
          groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
        } catch (e) {
          // En cas d'erreur de parsing de date ou autre, vous pouvez ignorer cette entrée ou la traiter différemment
          debugPrint("❌ Erreur lors de la conversion de la date : ${entry['date']}");
        }
      }
    }

    // Conversion de groupedData en une liste de maps
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByMonth(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String monthKey = DateFormat('yyyy/MM').format(date);
      groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByYear(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String yearKey = date.year.toString();
      groupedData[yearKey] = (groupedData[yearKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  void _saveChartPreference(String key, bool value) {
    prefs.setBool(key, value);
  }
}
