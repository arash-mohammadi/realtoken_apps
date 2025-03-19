import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/date_utils.dart';

class HealthAndLtvHistoryGraph extends StatefulWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final bool healthAndLtvIsBarChart;
  final Function(String) onPeriodChanged;
  final Function(bool) onChartTypeChanged;

  const HealthAndLtvHistoryGraph({
    super.key,
    required this.dataManager,
    required this.selectedPeriod,
    required this.healthAndLtvIsBarChart,
    required this.onPeriodChanged,
    required this.onChartTypeChanged,
  });

  @override
  _HealthAndLtvHistoryGraphState createState() =>
      _HealthAndLtvHistoryGraphState();
}

class _HealthAndLtvHistoryGraphState extends State<HealthAndLtvHistoryGraph> {
  /// true : afficher le healthFactor (échelle de 10)
  /// false : afficher le LTV (en pourcentage)
  bool showHealthFactor = true;
  
  // Variable pour suivre le point sélectionné
  int? _selectedSpotIndex;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Regroupement des données selon la période sélectionnée.
    Map<String, Map<String, double>> groupedData = _groupHealthAndLtvByDate(
      context,
      widget.dataManager,
      widget.selectedPeriod,
    );

    // Préparation des données pour le graphique linéaire.
    List<LineChartBarData> lineChartData = [];
    List<FlSpot> spots = [];
    int index = 0;
    groupedData.forEach((date, values) {
      double metricValue =
          showHealthFactor ? values['healtFactor']! : values['ltv']!;
      spots.add(FlSpot(index.toDouble(), metricValue));
      index++;
    });
    lineChartData.add(
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: showHealthFactor ? Colors.blue : Colors.green,
        barWidth: 2,
        belowBarData: BarAreaData(
          show: true,
          color:
              (showHealthFactor ? Colors.blue : Colors.green).withOpacity(0.1),
        ),
        dotData: FlDotData(show: false),
      ),
    );

    // Préparation des données pour le graphique en barres.
    List<BarChartGroupData> barGroups = [];
    index = 0;
    groupedData.forEach((date, values) {
      double metricValue =
          showHealthFactor ? values['healtFactor']! : values['ltv']!;
      barGroups.add(
        BarChartGroupData(
          x: index,
          barsSpace: 0,
          barRods: [
            BarChartRodData(
              toY: metricValue,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              rodStackItems: [
                BarChartRodStackItem(
                  0,
                  metricValue,
                  (showHealthFactor ? Colors.blue : Colors.green)
                      .withOpacity(0.8),
                ),
              ],
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      index++;
    });

    // Définition de la valeur maxY en fonction du métrique affiché.
    double maxY = showHealthFactor ? 10 : 100;

    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête et réglages
            Row(
              children: [
                Text(
                  'RMM health',
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HF',
                        style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset()),
                      ),
                      Switch(
                        value: showHealthFactor,
                        onChanged: (val) {
                          setState(() {
                            showHealthFactor = val;
                            _selectedSpotIndex = null;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                        inactiveThumbColor: Colors.grey,
                      ),
                      Text(
                        'LTV',
                        style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset()),
                      ),
                    ],
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
                                  setState(() {
                                    _selectedSpotIndex = null;
                                  });
                                  widget.onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.show_chart,
                                    color: Colors.green),
                                title: Text(S.of(context).lineChart),
                                onTap: () {
                                  setState(() {
                                    _selectedSpotIndex = null;
                                  });
                                  widget.onChartTypeChanged(false);
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
            // Sélecteur de période
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: widget.selectedPeriod,
              onPeriodChanged: (String newPeriod) {
                setState(() {
                  _selectedSpotIndex = null;
                });
                widget.onPeriodChanged(newPeriod);
              },
            ),
            const SizedBox(height: 20),
            // Affichage du graphique (barres ou lignes)
            SizedBox(
              height: 250,
              child: widget.healthAndLtvIsBarChart
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
                                  showHealthFactor
                                      ? value.toStringAsFixed(0)
                                      : '${value.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      fontSize:
                                          10 + appState.getTextSizeOffset()),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels =
                                    _buildDateLabelsForHealthAndLtv(
                                  context,
                                  widget.dataManager,
                                  widget.selectedPeriod,
                                );
                                if (value.toInt() >= 0 &&
                                    value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(
                                            fontSize: 10 +
                                                appState.getTextSizeOffset()),
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
                            bottom: BorderSide(
                                color: Colors.blueGrey.shade700, width: 0.5),
                            right: BorderSide(color: Colors.transparent),
                            top: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        alignment: BarChartAlignment.center,
                        barGroups: barGroups,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              // Vérifier si c'est le groupe sélectionné
                              if (_selectedSpotIndex != groupIndex) return null;
                              
                              List<String> dates =
                                  _buildDateLabelsForHealthAndLtv(
                                context,
                                widget.dataManager,
                                widget.selectedPeriod,
                              );
                              if (groupIndex < 0 || groupIndex >= dates.length) {
                                return null;
                              }
                              final date = dates[groupIndex];
                              final value = rod.toY;
                              return BarTooltipItem(
                                '$date\n${showHealthFactor ? 'Health Factor' : 'LTV'}: ${value.toStringAsFixed(2)}${showHealthFactor ? '' : '%'}',
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10 + appState.getTextSizeOffset(),
                                ),
                              );
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipMargin: 8,
                            tooltipHorizontalOffset: 0,
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                          ),
                          handleBuiltInTouches: true,
                          touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                            setState(() {
                              if (event is FlTapUpEvent) {
                                if (touchResponse?.spot != null) {
                                  _selectedSpotIndex = touchResponse!.spot!.touchedBarGroupIndex;
                                }
                              } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
                                _selectedSpotIndex = null;
                              }
                            });
                          },
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
                                  showHealthFactor
                                      ? value.toStringAsFixed(0)
                                      : '${value.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      fontSize:
                                          10 + appState.getTextSizeOffset()),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels =
                                    _buildDateLabelsForHealthAndLtv(
                                  context,
                                  widget.dataManager,
                                  widget.selectedPeriod,
                                );
                                if (value.toInt() >= 0 &&
                                    value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(
                                            fontSize: 10 +
                                                appState.getTextSizeOffset()),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        maxY: maxY,
                        minY: 0,
                        lineBarsData: lineChartData,
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                              if (touchedBarSpots.isEmpty) return [];
                              final spot = touchedBarSpots.first;
                              final spotIndex = spot.spotIndex;
                              
                              // Vérifier si le spot est celui sélectionné
                              if (_selectedSpotIndex != spotIndex) return [];
                              
                              List<String> dates =
                                  _buildDateLabelsForHealthAndLtv(
                                context,
                                widget.dataManager,
                                widget.selectedPeriod,
                              );
                              if (spotIndex < 0 || spotIndex >= dates.length) {
                                return [];
                              }
                              final date = dates[spotIndex];
                              return [
                                LineTooltipItem(
                                  '$date\n${showHealthFactor ? 'Health Factor' : 'LTV'}: ${spot.y.toStringAsFixed(2)}${showHealthFactor ? '' : '%'}',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10 + appState.getTextSizeOffset(),
                                  ),
                                ),
                              ];
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipMargin: 8,
                            tooltipHorizontalOffset: 0,
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                          ),
                          handleBuiltInTouches: true,
                          touchSpotThreshold: 20,
                          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                            setState(() {
                              if (event is FlTapUpEvent) {
                                if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                                  _selectedSpotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                                }
                              } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
                                _selectedSpotIndex = null;
                              }
                            });
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, double>> _groupHealthAndLtvByDate(
    BuildContext context,
    DataManager dataManager,
    String selectedPeriod,
  ) {
    Map<String, Map<String, double>> groupedData = {};
    List sortedRecords = List.from(dataManager.healthAndLtvHistory);
    sortedRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var record in sortedRecords) {
      DateTime date = record.timestamp;
      String periodKey;
      if (selectedPeriod == S.of(context).day) {
        periodKey = DateFormat('yyyy/MM/dd').format(date);
      } else if (selectedPeriod == S.of(context).week) {
        periodKey =
            "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
      } else if (selectedPeriod == S.of(context).month) {
        periodKey = DateFormat('yyyy/MM').format(date);
      } else {
        periodKey = date.year.toString();
      }

      if (!groupedData.containsKey(periodKey)) {
        groupedData[periodKey] = {'healtFactor': 0, 'ltv': 0};
      }
      groupedData[periodKey]!['healtFactor'] = record.healthFactor;
      groupedData[periodKey]!['ltv'] = record.ltv;
    }
    return groupedData;
  }

  List<String> _buildDateLabelsForHealthAndLtv(
    BuildContext context,
    DataManager dataManager,
    String selectedPeriod,
  ) {
    final groupedData =
        _groupHealthAndLtvByDate(context, dataManager, selectedPeriod);
    return groupedData.keys.toList();
  }
}
