import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/models/rented_record.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/date_utils.dart';

class RentedHistoryGraph extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool rentedIsBarChart;
  final Function(bool) onChartTypeChanged;

  const RentedHistoryGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.rentedIsBarChart,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);

    // Récupérer les données pour les graphiques
    List<FlSpot> rentedHistoryData = _buildRentedHistoryChartData(context, dataManager, selectedPeriod);
    List<BarChartGroupData> barChartData = _buildRentedHistoryBarChartData(context, dataManager, selectedPeriod);
    List<String> dateLabels = _buildDateLabelsForRented(context, dataManager, selectedPeriod);

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
                  'S.of(context).rentedHistory', // Titre principal
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20.0),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.bar_chart, color: Colors.blue),
                                title: Text(S.of(context).barChart),
                                onTap: () {
                                  onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.show_chart, color: Colors.green),
                                title: Text(S.of(context).lineChart),
                                onTap: () {
                                  onChartTypeChanged(false);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return rentedIsBarChart
                      ? BarChart(
                          BarChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toStringAsFixed(0)}%',
                                      style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10.0),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            dateLabels[value.toInt()],
                                            style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                  reservedSize: 30,
                                  interval: (dateLabels.length / 10).ceil().toDouble(), // Afficher une étiquette toutes les N barres
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
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
                            barGroups: barChartData,
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    final highestValue = rentedHistoryData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

                                    if (value == highestValue) {
                                      return const SizedBox.shrink();
                                    }

                                    return Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        '${value.toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> labels = _buildDateLabelsForRented(context, dataManager, selectedPeriod);

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
                                  reservedSize: 30,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
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
                            minX: 0,
                            maxX: (rentedHistoryData.length - 1).toDouble(),
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: rentedHistoryData,
                                isCurved: false,
                                barWidth: 2,
                                color: Colors.cyan,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.cyan.withOpacity(0.4),
                                      Colors.cyan.withOpacity(0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 8,
                                tooltipMargin: 8,
                                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final index = touchedSpot.x.toInt();
                                    final value = touchedSpot.y;
                                    final date = _buildDateLabelsForRented(context, dataManager, selectedPeriod)[index];

                                    final formattedValue = '${value.toStringAsFixed(2)}%';

                                    return LineTooltipItem(
                                      '$date\n$formattedValue',
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                if (touchResponse != null && touchResponse.lineBarSpots != null) {
                                  debugPrint('Point touché : ${touchResponse.lineBarSpots?.first.x}');
                                }
                              },
                              handleBuiltInTouches: true,
                            ),
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildRentedHistoryChartData(BuildContext context, DataManager dataManager, String selectedPeriod) {
  List<RentedRecord> rentedHistory = dataManager.rentedHistory;

  // Grouper les données en fonction de la période sélectionnée
  Map<String, List<double>> groupedData = {};
  for (var record in rentedHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }

    groupedData.putIfAbsent(periodKey, () => []).add(record.percentage);
  }

  // Calculer la moyenne pour chaque période et trier les clés en ordre chronologique
  List<FlSpot> spots = [];
  List<String> sortedKeys = groupedData.keys.toList();
  if (selectedPeriod == S.of(context).day) {
    sortedKeys.sort((a, b) =>
        DateFormat('yyyy/MM/dd').parse(a).compareTo(DateFormat('yyyy/MM/dd').parse(b)));
  } else if (selectedPeriod == S.of(context).week) {
    sortedKeys.sort((a, b) {
      final partsA = a.split('-S');
      final partsB = b.split('-S');
      int yearA = int.parse(partsA[0]);
      int weekA = int.parse(partsA[1]);
      int yearB = int.parse(partsB[0]);
      int weekB = int.parse(partsB[1]);
      int cmp = yearA.compareTo(yearB);
      if (cmp == 0) {
        cmp = weekA.compareTo(weekB);
      }
      return cmp;
    });
  } else if (selectedPeriod == S.of(context).month) {
    sortedKeys.sort((a, b) =>
        DateFormat('yyyy/MM').parse(a).compareTo(DateFormat('yyyy/MM').parse(b)));
  } else {
    sortedKeys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  }

  for (int i = 0; i < sortedKeys.length; i++) {
    String periodKey = sortedKeys[i];
    List<double> renteds = groupedData[periodKey]!;
    double averageRented = renteds.reduce((a, b) => a + b) / renteds.length; // Calcul de la moyenne
    spots.add(FlSpot(i.toDouble(), averageRented));
  }

  return spots;
}

  List<BarChartGroupData> _buildRentedHistoryBarChartData(BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<FlSpot> rentedHistoryData = _buildRentedHistoryChartData(context, dataManager, selectedPeriod);
    return rentedHistoryData
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: Colors.cyan,
                width: 8,
              ),
            ],
          ),
        )
        .toList();
  }

  List<String> _buildDateLabelsForRented(BuildContext context, DataManager dataManager, String selectedPeriod) {
  List<RentedRecord> rentedHistory = dataManager.rentedHistory;

  // Grouper les données en fonction de la période sélectionnée
  Map<String, List<double>> groupedData = {};
  for (var record in rentedHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }

    groupedData.putIfAbsent(periodKey, () => []).add(record.percentage);
  }

  // Trier les clés en ordre crentedssant
  List<String> sortedKeys = groupedData.keys.toList();
  if (selectedPeriod == S.of(context).day) {
    sortedKeys.sort((a, b) =>
        DateFormat('yyyy/MM/dd').parse(a).compareTo(DateFormat('yyyy/MM/dd').parse(b)));
  } else if (selectedPeriod == S.of(context).week) {
    sortedKeys.sort((a, b) {
      final partsA = a.split('-S');
      final partsB = b.split('-S');
      int yearA = int.parse(partsA[0]);
      int weekA = int.parse(partsA[1]);
      int yearB = int.parse(partsB[0]);
      int weekB = int.parse(partsB[1]);
      int cmp = yearA.compareTo(yearB);
      if (cmp == 0) {
        cmp = weekA.compareTo(weekB);
      }
      return cmp;
    });
  } else if (selectedPeriod == S.of(context).month) {
    sortedKeys.sort((a, b) =>
        DateFormat('yyyy/MM').parse(a).compareTo(DateFormat('yyyy/MM').parse(b)));
  } else {
    sortedKeys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  }

  return sortedKeys;
}
}
