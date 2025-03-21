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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      shadowColor: Colors.black.withOpacity(0.1),
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
                  S.of(context).apyHistory,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 24.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
                                child: Text(
                                  'S.of(context).chartType',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.bar_chart_rounded,
                                  color: Colors.blue.shade400,
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).barChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                trailing: apyIsBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.blue.shade400,
                                      )
                                    : null,
                                onTap: () {
                                  onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.show_chart_rounded,
                                  color: Colors.green.shade400,
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).lineChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                trailing: !apyIsBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade400,
                                      )
                                    : null,
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
            const SizedBox(height: 12),
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SizedBox(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return apyIsBarChart
                        ? BarChart(
                          BarChartData(
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
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        '${value.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 10 + appState.getTextSizeOffset(),
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> labels = _buildDateLabelsForApy(
                                        context, dataManager, selectedPeriod);
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
                              show: false,
                            ),
                            alignment: BarChartAlignment.center,
                            barGroups: apyHistoryData,
                            maxY: 20,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  if (selectedIndex == groupIndex) {
                                    String tooltip =
                                        '${S.of(context).brute}: ${group.barRods[0].rodStackItems[0].toY.toStringAsFixed(2)}%\n'
                                        '${S.of(context).net}: ${group.barRods[0].rodStackItems[1].toY.toStringAsFixed(2)}%';
                                    return BarTooltipItem(
                                      tooltip,
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return null;
                                },
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipMargin: 8,
                                tooltipHorizontalOffset: 0,
                                tooltipRoundedRadius: 12,
                                tooltipPadding: const EdgeInsets.all(12),
                                getTooltipColor: (group) => Colors.black87,                              ),
                              touchCallback: (FlTouchEvent event, barTouchResponse) {
                                if (event is FlTapUpEvent &&
                                    barTouchResponse != null) {
                                  setState(() {
                                    selectedIndex = barTouchResponse
                                        .spot?.touchedBarGroupIndex;
                                  });
                                } else if (event is FlLongPressEnd ||
                                    event is FlPanEndEvent) {
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
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        '${value.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 10 + appState.getTextSizeOffset(),
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> labels = _buildDateLabelsForApy(
                                        context, dataManager, selectedPeriod);
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
                              show: false,
                            ),
                            lineBarsData: lineChartData,
                            minY: 0,
                            maxY: 20,
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final index = touchedSpot.x.toInt();
                                    final value = touchedSpot.y;
                                    final periodLabel = _buildDateLabelsForApy(
                                        context, dataManager, selectedPeriod)[index];
                                    
                                    final formattedValue = '${value.toStringAsFixed(2)}%';
                                    
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
                                getTooltipColor: (group) => Colors.black87,                              ),
                              handleBuiltInTouches: true,
                              touchSpotThreshold: 20,
                            ),
                          ),
                        );
                  },
                ),
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
        curveSmoothness: 0.3,
        color: Colors.blue.shade400,
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400.withOpacity(0.3),
              Colors.blue.shade400.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: Colors.blue.shade400,
            );
          },
          checkToShowDot: (spot, barData) {
            // Montrer les points uniquement aux extrémités et peut-être un au milieu
            final isFirst = spot.x == 0;
            final isLast = spot.x == barData.spots.length - 1;
            final isMiddle = spot.x == (barData.spots.length / 2).round();
            return isFirst || isLast || isMiddle;
          },
        ),
      ),
      LineChartBarData(
        spots: netSpots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: Colors.green.shade400,
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400.withOpacity(0.3),
              Colors.green.shade400.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: Colors.green.shade400,
            );
          },
          checkToShowDot: (spot, barData) {
            // Montrer les points uniquement aux extrémités et peut-être un au milieu
            final isFirst = spot.x == 0;
            final isLast = spot.x == barData.spots.length - 1;
            final isMiddle = spot.x == (barData.spots.length / 2).round();
            return isFirst || isLast || isMiddle;
          },
        ),
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
              rodStackItems: [
                BarChartRodStackItem(
                  0, 
                  values['gross']!, 
                  Colors.blue.shade400.withOpacity(0.85)
                ),
                BarChartRodStackItem(
                  0, 
                  values['net']!, 
                  Colors.green.shade400.withOpacity(0.85)
                ),
              ],
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 20,
                color: Colors.grey.withOpacity(0.1),
              ),
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
