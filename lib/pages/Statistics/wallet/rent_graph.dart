import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RentGraph extends StatefulWidget {
  final List<Map<String, dynamic>> groupedData;
  final DataManager dataManager;
  final bool showCumulativeRent;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<bool> onCumulativeRentChanged;

  const RentGraph({
    super.key,
    required this.groupedData,
    required this.dataManager,
    required this.showCumulativeRent,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onCumulativeRentChanged,
  });

  @override
  _RentGraphState createState() => _RentGraphState();
}

class _RentGraphState extends State<RentGraph> {
  late String _selectedRentPeriod;
  bool _showCumulativeRent = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();
      _selectedRentPeriod = S.of(context).month;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    DataManager? dataManager;
    try {
      dataManager = Provider.of<DataManager>(context);
    } catch (e) {
      debugPrint("Error accessing DataManager: $e");
      return Center(child: Text("DataManager is unavailable"));
    }
    const int maxPoints = 1000;

    List<Map<String, dynamic>> groupedData = _groupRentDataByPeriod(dataManager);

    List<Map<String, dynamic>> limitedData = groupedData.length > maxPoints ? groupedData.sublist(0, maxPoints) : groupedData;

    List<Map<String, dynamic>> convertedData = limitedData.map((entry) {
      double convertedRent = currencyUtils.convert(entry['rent'] ?? 0.0);
      return {
        'date': entry['date'],
        'rent': convertedRent,
        'cumulativeRent': entry['cumulativeRent'] ?? 0.0,
      };
    }).toList();
    // Trier les données par date croissante
    convertedData.sort((a, b) => a['date'].compareTo(b['date']));

    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _showCumulativeRent ? S.of(context).cumulativeRentGraph : S.of(context).groupedRentGraph,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Transform.scale(
                  scale: 0.8, // Réduit la taille à 80% de la taille originale
                  child: Switch(
                    value: _showCumulativeRent,
                    onChanged: (value) {
                      setState(() {
                        _showCumulativeRent = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor, // Couleur d'accentuation en mode activé
                    inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                  ),
                )
              ],
            ),
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: _selectedRentPeriod,
              onPeriodChanged: (period) {
                setState(() {
                  _selectedRentPeriod = period;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          final highestValue = convertedData.map((entry) => entry['rent']).reduce((a, b) => a > b ? a : b);

                          if (value == highestValue) {
                            return const SizedBox.shrink();
                          }

                          final formattedValue = currencyUtils.getFormattedAmount(
                            value,
                            currencyUtils.currencySymbol,
                            appState.showAmounts, // Appliquer le masquage des montants
                          );

                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              formattedValue,
                              style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          List<String> labels = _buildDateLabels(convertedData);
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  labels[value.toInt()],
                                  style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.transparent),
                      bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _showCumulativeRent ? _buildCumulativeChartData(convertedData) : _buildChartData(convertedData),
                      isCurved: false,
                      barWidth: 2,
                      color: _showCumulativeRent ? Colors.green : Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0.4),
                            (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          final periodLabel = _buildDateLabels(convertedData)[index];

                          final formattedValue = currencyUtils.getFormattedAmount(
                            touchedSpot.y,
                            currencyUtils.currencySymbol,
                            appState.showAmounts, // Applique le masquage des montants
                          );

                          return LineTooltipItem(
                            '$periodLabel\n$formattedValue',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupRentDataByPeriod(DataManager dataManager) {
    if (_selectedRentPeriod == S.of(context).day) {
      return _groupByDay(dataManager.rentData);
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
  // Conversion de la Map en liste
  List<Map<String, dynamic>> list =
      groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  // Trier la liste par date croissante
  list.sort((a, b) =>
      DateFormat('yyyy/MM/dd').parse(a['date']).compareTo(DateFormat('yyyy/MM/dd').parse(b['date'])));
  return list;
}


List<Map<String, dynamic>> _groupByWeek(List<Map<String, dynamic>> data) {
  Map<String, double> groupedData = {};

  for (var entry in data) {
    if (entry.containsKey('date') && entry.containsKey('rent')) {
      try {
        DateTime date = DateTime.parse(entry['date']);
        String weekKey = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
        groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
      } catch (e) {
        debugPrint("❌ Erreur lors de la conversion de la date : ${entry['date']}");
      }
    }
  }

  // Conversion de la Map en liste de maps
  List<Map<String, dynamic>> list = groupedData.entries
      .map((entry) => {'date': entry.key, 'rent': entry.value})
      .toList();

  // Tri de la liste par année puis par numéro de semaine
  list.sort((a, b) {
    final aParts = a['date'].split('-S');
    final bParts = b['date'].split('-S');
    int aYear = int.parse(aParts[0]);
    int bYear = int.parse(bParts[0]);
    int aWeek = int.parse(aParts[1]);
    int bWeek = int.parse(bParts[1]);
    int cmp = aYear.compareTo(bYear);
    if (cmp == 0) {
      cmp = aWeek.compareTo(bWeek);
    }
    return cmp;
  });

  return list;
}

 List<Map<String, dynamic>> _groupByMonth(List<Map<String, dynamic>> data) {
  Map<String, double> groupedData = {};
  for (var entry in data) {
    DateTime date = DateTime.parse(entry['date']);
    String monthKey = DateFormat('yyyy/MM').format(date);
    groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
  }
  // Conversion en liste et tri par date croissante
  List<Map<String, dynamic>> list = groupedData.entries
      .map((entry) => {'date': entry.key, 'rent': entry.value})
      .toList();
  list.sort((a, b) => DateFormat('yyyy/MM')
      .parse(a['date'])
      .compareTo(DateFormat('yyyy/MM').parse(b['date'])));
  return list;
}

List<Map<String, dynamic>> _groupByYear(List<Map<String, dynamic>> data) {
  Map<String, double> groupedData = {};
  for (var entry in data) {
    DateTime date = DateTime.parse(entry['date']);
    String yearKey = date.year.toString();
    groupedData[yearKey] = (groupedData[yearKey] ?? 0) + entry['rent'];
  }
  // Conversion en liste et tri par année croissante
  List<Map<String, dynamic>> list = groupedData.entries
      .map((entry) => {'date': entry.key, 'rent': entry.value})
      .toList();
  list.sort((a, b) => int.parse(a['date']).compareTo(int.parse(b['date'])));
  return list;
}

  List<FlSpot> _buildChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> spots = [];
    for (var i = 0; i < data.length; i++) {
      double rentValue = data[i]['rent']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), rentValue));
    }
    return spots;
  }

  List<String> _buildDateLabels(List<Map<String, dynamic>> data) {
    return data.map((entry) => entry['date'].toString()).toList();
  }

  List<FlSpot> _buildCumulativeChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> spots = [];
    double cumulativeRent = 0.0;

    for (var i = 0; i < data.length; i++) {
      cumulativeRent += data[i]['rent']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), cumulativeRent));
    }
    return spots;
  }
}
