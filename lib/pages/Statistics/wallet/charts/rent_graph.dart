import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

    List<Map<String, dynamic>> groupedData =
        _groupRentDataByPeriod(dataManager);

    List<Map<String, dynamic>> limitedData = groupedData.length > maxPoints
        ? groupedData.sublist(0, maxPoints)
        : groupedData;

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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _showCumulativeRent
                      ? S.of(context).cumulativeRentGraph
                      : S.of(context).groupedRentGraph,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: _showCumulativeRent,
                  onChanged: (value) {
                    setState(() {
                      _showCumulativeRent = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  trackColor: Colors.grey.shade300,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: _selectedRentPeriod,
              onPeriodChanged: (period) {
                setState(() {
                  _selectedRentPeriod = period;
                });
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SizedBox(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.15),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            final highestValue = convertedData
                                .map((entry) => entry['rent'])
                                .reduce((a, b) => a > b ? a : b);

                            if (value == highestValue) {
                              return const SizedBox.shrink();
                            }

                            final formattedValue =
                                currencyUtils.getFormattedAmount(
                              value,
                              currencyUtils.currencySymbol,
                              appState.showAmounts,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                formattedValue,
                                style: TextStyle(
                                  fontSize: 10 + appState.getTextSizeOffset(),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            List<String> labels = _buildDateLabels(convertedData);
                            if (value.toInt() >= 0 &&
                                value.toInt() < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(
                                      fontSize: 10 + appState.getTextSizeOffset(),
                                      color: Colors.grey.shade600,
                                    ),
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
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _showCumulativeRent
                            ? _buildCumulativeChartData(convertedData)
                            : _buildChartData(convertedData),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        barWidth: 3,
                        color: _showCumulativeRent
                            ? const Color(0xFF34C759) // iOS green
                            : const Color(0xFF007AFF), // iOS blue
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: _showCumulativeRent
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFF007AFF),
                            );
                          },
                          checkToShowDot: (spot, barData) {
                            // Montrer les points uniquement aux extrémités et éventuellement quelques points intermédiaires
                            final isFirst = spot.x == 0;
                            final isLast = spot.x == barData.spots.length - 1;
                            final isInteresting = spot.x % (barData.spots.length > 10 ? 5 : 2) == 0;
                            return isFirst || isLast || isInteresting;
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              (_showCumulativeRent
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFF007AFF))
                                  .withOpacity(0.3),
                              (_showCumulativeRent
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFF007AFF))
                                  .withOpacity(0.05),
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
                            final value = touchedSpot.y;
                            final String periodLabel = _buildDateLabelsForRent(
                                context, dataManager, _selectedRentPeriod)[index];
                            
                            final formattedValue = currencyUtils.getFormattedAmount(
                              value,
                              currencyUtils.currencySymbol,
                              appState.showAmounts,
                            );
                            
                            return LineTooltipItem(
                              '$periodLabel\n$formattedValue',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipMargin: 8,
                        tooltipHorizontalOffset: 0,
                        tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.all(12),
                      ),
                      handleBuiltInTouches: true,
                      touchSpotThreshold: 20,
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
    List<Map<String, dynamic>> list = groupedData.entries
        .map((entry) => {'date': entry.key, 'rent': entry.value})
        .toList();
    // Trier la liste par date croissante
    list.sort((a, b) => DateFormat('yyyy/MM/dd')
        .parse(a['date'])
        .compareTo(DateFormat('yyyy/MM/dd').parse(b['date'])));
    return list;
  }

  List<Map<String, dynamic>> _groupByWeek(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};

    for (var entry in data) {
      if (entry.containsKey('date') && entry.containsKey('rent')) {
        try {
          DateTime date = DateTime.parse(entry['date']);
          String weekKey =
              "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
          groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
        } catch (e) {
          debugPrint(
              "❌ Erreur lors de la conversion de la date : ${entry['date']}");
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

  List<String> _buildDateLabelsForRent(BuildContext context, DataManager? dataManager, String selectedPeriod) {
    if (dataManager == null) return [];
    
    List<Map<String, dynamic>> groupedData = _groupRentDataByPeriod(dataManager);
    return _buildDateLabels(groupedData);
  }
}
