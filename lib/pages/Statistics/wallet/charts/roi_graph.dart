import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/models/roi_record.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/date_utils.dart';

class RoiHistoryGraph extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool roiIsBarChart;
  final Function(bool) onChartTypeChanged;

  const RoiHistoryGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.roiIsBarChart,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);

    // Récupérer les données pour les graphiques
    List<FlSpot> roiHistoryData =
        _buildRoiHistoryChartData(context, dataManager, selectedPeriod);
    List<BarChartGroupData> barChartData =
        _buildRoiHistoryBarChartData(context, dataManager, selectedPeriod);
    List<String> dateLabels =
        _buildDateLabelsForRoi(context, dataManager, selectedPeriod);

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
                  S.of(context).roiHistory, // Titre principal
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
                                  color: const Color(0xFF5AC8FA),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).barChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                trailing: roiIsBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF5AC8FA),
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
                                  color: const Color(0xFF5856D6),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).lineChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                trailing: !roiIsBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF5856D6),
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
                    return roiIsBarChart
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
                                    showTitles: false,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < dateLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 10.0),
                                          child: Transform.rotate(
                                            angle: -0.5,
                                            child: Text(
                                              dateLabels[value.toInt()],
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
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 35,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          '${value.toInt()}%',
                                          style: TextStyle(
                                            fontSize: 10 + appState.getTextSizeOffset(),
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: barChartData.map((group) {
                                return BarChartGroupData(
                                  x: group.x,
                                  barRods: [
                                    BarChartRodData(
                                      toY: group.barRods.first.toY,
                                      color: const Color(0xFF5AC8FA),
                                      width: 12,
                                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: 100,
                                        color: Colors.grey.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    if (groupIndex >= 0 && groupIndex < dateLabels.length) {
                                      return BarTooltipItem(
                                        '${dateLabels[groupIndex]}\n${rod.toY.toInt()}%',
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
                                  tooltipRoundedRadius: 12,
                                  tooltipPadding: const EdgeInsets.all(12),
                                ),
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
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      List<String> labels =
                                          _buildDateLabelsForRoi(context,
                                              dataManager, selectedPeriod);

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
                                    reservedSize: 30,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 35,
                                    getTitlesWidget: (value, meta) {
                                      final highestValue = roiHistoryData
                                          .map((e) => e.y)
                                          .reduce((a, b) => a > b ? a : b);

                                      if (value == highestValue) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          '${value.toInt()}%',
                                          style: TextStyle(
                                            fontSize: 10 + appState.getTextSizeOffset(),
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (roiHistoryData.length - 1).toDouble(),
                              minY: 0,
                              maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: roiHistoryData,
                                  isCurved: true,
                                  curveSmoothness: 0.3,
                                  barWidth: 3,
                                  color: const Color(0xFF5856D6),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 3,
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: const Color(0xFF5856D6),
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
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF5856D6).withOpacity(0.3),
                                        const Color(0xFF5856D6).withOpacity(0.05),
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
                                      
                                      // Récupération de la date correspondante
                                      final String periodLabel = _buildDateLabelsForRoi(
                                          context, dataManager, selectedPeriod)[index];
                                      
                                      return LineTooltipItem(
                                        '$periodLabel\n${value.toInt()}%',
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

  List<FlSpot> _buildRoiHistoryChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<RoiRecord> roiHistory = dataManager.roiHistory;

    // Grouper les données en fonction de la période sélectionnée
    Map<String, List<double>> groupedData = {};
    for (var record in roiHistory) {
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

      groupedData.putIfAbsent(periodKey, () => []).add(record.roi);
    }

    // Calculer la moyenne pour chaque période et trier les clés en ordre chronologique
    List<FlSpot> spots = [];
    List<String> sortedKeys = groupedData.keys.toList();
    if (selectedPeriod == S.of(context).day) {
      sortedKeys.sort((a, b) => DateFormat('yyyy/MM/dd')
          .parse(a)
          .compareTo(DateFormat('yyyy/MM/dd').parse(b)));
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
      sortedKeys.sort((a, b) => DateFormat('yyyy/MM')
          .parse(a)
          .compareTo(DateFormat('yyyy/MM').parse(b)));
    } else {
      sortedKeys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }

    for (int i = 0; i < sortedKeys.length; i++) {
      String periodKey = sortedKeys[i];
      List<double> rois = groupedData[periodKey]!;
      double averageRoi =
          rois.reduce((a, b) => a + b) / rois.length; // Calcul de la moyenne
      spots.add(FlSpot(i.toDouble(), averageRoi));
    }

    return spots;
  }

  List<BarChartGroupData> _buildRoiHistoryBarChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<FlSpot> roiHistoryData =
        _buildRoiHistoryChartData(context, dataManager, selectedPeriod);
    return roiHistoryData
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: const Color(0xFF5AC8FA),
                width: 8,
              ),
            ],
          ),
        )
        .toList();
  }

  List<String> _buildDateLabelsForRoi(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<RoiRecord> roiHistory = dataManager.roiHistory;

    // Grouper les données en fonction de la période sélectionnée
    Map<String, List<double>> groupedData = {};
    for (var record in roiHistory) {
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

      groupedData.putIfAbsent(periodKey, () => []).add(record.roi);
    }

    // Trier les clés en ordre croissant
    List<String> sortedKeys = groupedData.keys.toList();
    if (selectedPeriod == S.of(context).day) {
      sortedKeys.sort((a, b) => DateFormat('yyyy/MM/dd')
          .parse(a)
          .compareTo(DateFormat('yyyy/MM/dd').parse(b)));
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
      sortedKeys.sort((a, b) => DateFormat('yyyy/MM')
          .parse(a)
          .compareTo(DateFormat('yyyy/MM').parse(b)));
    } else {
      sortedKeys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }

    return sortedKeys;
  }
}
