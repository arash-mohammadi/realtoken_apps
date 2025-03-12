import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/date_utils.dart';

class ApyHistoryGraph extends StatelessWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final bool apyIsBarChart;
  final Function(String) onPeriodChanged;
  final Function(bool) onChartTypeChanged;

  const ApyHistoryGraph({
    super.key,
    required this.dataManager,
    required this.selectedPeriod,
    required this.apyIsBarChart,
    required this.onPeriodChanged,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    List<BarChartGroupData> apyHistoryData =
        _buildApyHistoryBarChartData(context, dataManager, selectedPeriod);
    List<LineChartBarData> lineChartData =
        _buildApyHistoryLineChartData(context, dataManager, selectedPeriod);

    int? selectedIndex;

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
                  S.of(context).apyHistory,
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
                                leading: const Icon(Icons.bar_chart,
                                    color: Colors.blue),
                                title: Text(S.of(context).barChart),
                                onTap: () {
                                  onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.show_chart,
                                    color: Colors.green),
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
                  return apyIsBarChart
                      ? BarChart(
                          BarChartData(
                            gridData:
                                FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          fontSize: 10 +
                                              appState.getTextSizeOffset()),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> labels =
                                        _buildDateLabelsForApy(context,
                                            dataManager, selectedPeriod);
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < labels.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            labels[value.toInt()],
                                            style: TextStyle(
                                                fontSize: 10 +
                                                    appState
                                                        .getTextSizeOffset()),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const Text('');
                                    }
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                left: BorderSide(color: Colors.transparent),
                                bottom: BorderSide(
                                    color: Colors.blueGrey.shade700,
                                    width: 0.5),
                                right: BorderSide(color: Colors.transparent),
                                top: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            alignment: BarChartAlignment.center,
                            barGroups: apyHistoryData,
                            maxY: 20,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  // Affiche uniquement le tooltip si l'index est sélectionné
                                  if (selectedIndex == groupIndex) {
                                    String tooltip =
                                        '${S.of(context).brute}: ${group.barRods[0].rodStackItems[0].toY.toStringAsFixed(2)}%\n'
                                        '${S.of(context).net}: ${group.barRods[0].rodStackItems[1].toY.toStringAsFixed(2)}%';
                                    return BarTooltipItem(
                                      tooltip,
                                      const TextStyle(color: Colors.white),
                                    );
                                  }
                                  return null; // Aucun tooltip
                                },
                              ),
                              touchCallback:
                                  (FlTouchEvent event, barTouchResponse) {
                                // Met à jour l'index sélectionné en cas de clic
                                if (event is FlTapUpEvent &&
                                    barTouchResponse != null) {
                                  setState(() {
                                    selectedIndex = barTouchResponse
                                        .spot?.touchedBarGroupIndex;
                                  });
                                } else if (event is FlLongPressEnd ||
                                    event is FlPanEndEvent) {
                                  // Désélectionne si l'utilisateur annule l'interaction
                                  setState(() {
                                    selectedIndex = null;
                                  });
                                }
                              },
                              handleBuiltInTouches: true,
                            ),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData:
                                FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          fontSize: 10 +
                                              appState.getTextSizeOffset()),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> labels =
                                        _buildDateLabelsForApy(context,
                                            dataManager, selectedPeriod);
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < labels.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            labels[value.toInt()],
                                            style: TextStyle(
                                                fontSize: 10 +
                                                    appState
                                                        .getTextSizeOffset()),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const Text('');
                                    }
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                left: BorderSide(color: Colors.transparent),
                                bottom: BorderSide(
                                    color: Colors.blueGrey.shade700,
                                    width: 0.5),
                                right: BorderSide(color: Colors.transparent),
                                top: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            lineBarsData: lineChartData,
                            minY: 0,
                            maxY: 20,
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

  List<LineChartBarData> _buildApyHistoryLineChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    final groupedData = _groupApyByDate(context, dataManager, selectedPeriod);

    final grossSpots = <FlSpot>[];
    final netSpots = <FlSpot>[];

    int index = 0;
    groupedData.forEach((date, values) {
      grossSpots.add(FlSpot(index.toDouble(), values['gross']!));
      netSpots.add(FlSpot(index.toDouble(), values['net']!));
      index++;
    });

    return [
      LineChartBarData(
        spots: grossSpots,
        isCurved: true,
        color: Colors.blue,
        barWidth: 2,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.1),
        ),
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: netSpots,
        isCurved: true,
        color: Colors.green,
        barWidth: 2,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.green.withOpacity(0.1),
        ),
        dotData: FlDotData(show: false),
      ),
    ];
  }

  List<BarChartGroupData> _buildApyHistoryBarChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    final groupedData = _groupApyByDate(context, dataManager, selectedPeriod);
    final barGroups = <BarChartGroupData>[];

    int index = 0;
    groupedData.forEach((date, values) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barsSpace: 0,
          barRods: [
            BarChartRodData(
              toY: values['gross']!,
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
              rodStackItems: [
                BarChartRodStackItem(
                    0, values['gross']!, Colors.blue.withOpacity(0.8)),
                BarChartRodStackItem(
                    0, values['net']!, Colors.green.withOpacity(0.8)),
              ],
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      index++;
    });

    return barGroups;
  }

  Map<String, Map<String, double>> _groupApyByDate(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    Map<String, Map<String, double>> groupedData = {};

// Copie et tri de la liste par date croissante
    List sortedRecords = List.from(dataManager.apyHistory);
    sortedRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var record in sortedRecords) {
      DateTime date = record.timestamp;
      String periodKey;

      if (selectedPeriod == S.of(context).day) {
        periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
      } else if (selectedPeriod == S.of(context).week) {
        periodKey =
            "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
      } else if (selectedPeriod == S.of(context).month) {
        periodKey = DateFormat('yyyy/MM').format(date);
      } else {
        periodKey = date.year.toString();
      }

      if (!groupedData.containsKey(periodKey)) {
        groupedData[periodKey] = {'gross': 0, 'net': 0};
      }

      groupedData[periodKey]!['gross'] = record.grossApy;
      groupedData[periodKey]!['net'] = record.netApy;
    }

    return groupedData;
  }

  List<String> _buildDateLabelsForApy(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    final groupedData = _groupApyByDate(context, dataManager, selectedPeriod);
    return groupedData.keys.toList();
  }
}
