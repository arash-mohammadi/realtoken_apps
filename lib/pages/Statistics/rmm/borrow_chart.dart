// borrow_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart'; // Pour CustomDateUtils

/// Classe privée représentant un groupe d'emprunt agrégé selon la période.
class _BorrowGroup {
  final DateTime groupDate;
  final double usdc;
  final double xdai;
  _BorrowGroup({
    required this.groupDate,
    required this.usdc,
    required this.xdai,
  });
}

class BorrowChart extends StatelessWidget {
  final Map<String, List<BalanceRecord>> allHistories;
  final String selectedPeriod;

  const BorrowChart({
    required this.allHistories,
    required this.selectedPeriod,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Regroupe les données d'emprunt par période.
    final groups = _groupBorrows(context);
    final minX = 0.0;
    final maxX = groups.isNotEmpty ? (groups.length - 1).toDouble() : 0.0;

    // Construction des spots pour chaque série.
    final usdcSpots = <FlSpot>[];
    final xdaiSpots = <FlSpot>[];
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final convertedUsdc = currencyUtils.convert(group.usdc);
      final convertedXdai = currencyUtils.convert(group.xdai);
      usdcSpots.add(FlSpot(i.toDouble(), convertedUsdc));
      // On additionne les montants convertis pour décaler la courbe xDai.
      xdaiSpots.add(FlSpot(i.toDouble(), convertedUsdc + convertedXdai));
    }

    double calculatedMaxY = 0;
    for (final group in groups) {
      final convertedUsdc = currencyUtils.convert(group.usdc);
      final convertedXdai = currencyUtils.convert(group.xdai);
      final stackedValue = convertedUsdc + convertedXdai;
      calculatedMaxY =
          stackedValue > calculatedMaxY ? stackedValue : calculatedMaxY;
    }
    final maxY = calculatedMaxY > 0 ? calculatedMaxY * 1.1 : 10.0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true, 
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.15),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < 0 || index >= groups.length)
                                return const SizedBox();
                              final groupDate = groups[index].groupDate;
                              String label;
                              if (selectedPeriod == S.of(context).day) {
                                label = DateFormat('dd/MM').format(groupDate);
                              } else if (selectedPeriod == S.of(context).week) {
                                label =
                                    'S${CustomDateUtils.weekNumber(groupDate).toString().padLeft(2, '0')}';
                              } else if (selectedPeriod == S.of(context).month) {
                                label = DateFormat('MM/yy').format(groupDate);
                              } else if (selectedPeriod == S.of(context).year) {
                                label = DateFormat('yyyy').format(groupDate);
                              } else {
                                label = DateFormat('dd/MM').format(groupDate);
                              }
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10 + appState.getTextSizeOffset(),
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              final formattedValue = currencyUtils.formatCompactCurrency(
                                value,
                                currencyUtils.currencySymbol,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
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
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: minX,
                      maxX: maxX,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: usdcSpots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFFFF9500), // Orange iOS
                              );
                            },
                            checkToShowDot: (spot, barData) {
                              // Afficher les points aux extrémités et quelques points intermédiaires
                              return spot.x == 0 || 
                                     spot.x == barData.spots.length - 1 || 
                                     spot.x % (barData.spots.length > 8 ? 4 : 2) == 0;
                            },
                          ),
                          barWidth: 2.5,
                          color: const Color(0xFFFF9500), // Orange iOS
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF9500).withOpacity(0.3),
                                const Color(0xFFFF9500).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: xdaiSpots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFFFF3B30), // Rouge iOS
                              );
                            },
                            checkToShowDot: (spot, barData) {
                              // Afficher les points aux extrémités et quelques points intermédiaires
                              return spot.x == 0 || 
                                     spot.x == barData.spots.length - 1 || 
                                     spot.x % (barData.spots.length > 8 ? 4 : 2) == 0;
                            },
                          ),
                          barWidth: 2.5,
                          color: const Color(0xFFFF3B30), // Rouge iOS
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF3B30).withOpacity(0.3),
                                const Color(0xFFFF3B30).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            if (touchedSpots.isEmpty) return [];
                            
                            final int index = touchedSpots.first.spotIndex;
                            if (index < 0 || index >= groups.length) return [];
                            
                            final group = groups[index];
                            String periodLabel;
                            if (selectedPeriod == S.of(context).day) {
                              periodLabel = DateFormat('dd/MM/yyyy').format(group.groupDate);
                            } else if (selectedPeriod == S.of(context).week) {
                              periodLabel =
                                  'S${CustomDateUtils.weekNumber(group.groupDate).toString().padLeft(2, '0')}';
                            } else if (selectedPeriod == S.of(context).month) {
                              periodLabel = DateFormat('MM/yyyy').format(group.groupDate);
                            } else if (selectedPeriod == S.of(context).year) {
                              periodLabel = DateFormat('yyyy').format(group.groupDate);
                            } else {
                              periodLabel = DateFormat('dd/MM/yyyy').format(group.groupDate);
                            }
                            
                            final tooltipText = "$periodLabel\n"
                                "USDC: ${currencyUtils.formatCompactCurrency(currencyUtils.convert(group.usdc), currencyUtils.currencySymbol)}\n"
                                "xDai: ${currencyUtils.formatCompactCurrency(currencyUtils.convert(group.xdai), currencyUtils.currencySymbol)}";
                                
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                tooltipText,
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12 + appState.getTextSizeOffset(),
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
                  ),
                ),
                const SizedBox(height: 10),
                // Légende
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('USDC', const Color(0xFFFF9500)),
                    const SizedBox(width: 24),
                    _buildLegendItem('xDai', const Color(0xFFFF3B30)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget de légende pour chaque série de données.
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Regroupe les enregistrements d'emprunt (USDC et xDai) par période.
  List<_BorrowGroup> _groupBorrows(BuildContext context) {
    Map<DateTime, _BorrowGroup> groups = {};

    void addRecord(BalanceRecord record, String tokenKey) {
      final DateTime groupDate = _truncateDate(record.timestamp, context);
      if (!groups.containsKey(groupDate)) {
        groups[groupDate] =
            _BorrowGroup(groupDate: groupDate, usdc: 0, xdai: 0);
      }
      final currentGroup = groups[groupDate]!;
      if (tokenKey == 'usdc') {
        groups[groupDate] = _BorrowGroup(
          groupDate: groupDate,
          usdc: currentGroup.usdc + record.balance,
          xdai: currentGroup.xdai,
        );
      } else if (tokenKey == 'xdai') {
        groups[groupDate] = _BorrowGroup(
          groupDate: groupDate,
          usdc: currentGroup.usdc,
          xdai: currentGroup.xdai + record.balance,
        );
      }
    }

    if (allHistories['usdcBorrow'] != null) {
      for (var record in allHistories['usdcBorrow']!) {
        addRecord(record, 'usdc');
      }
    }
    if (allHistories['xdaiBorrow'] != null) {
      for (var record in allHistories['xdaiBorrow']!) {
        addRecord(record, 'xdai');
      }
    }

    List<_BorrowGroup> groupList = groups.values.toList();
    groupList.sort((a, b) => a.groupDate.compareTo(b.groupDate));
    return groupList;
  }

  /// Tronque une date selon la période sélectionnée.
  DateTime _truncateDate(DateTime date, BuildContext context) {
    if (selectedPeriod == S.of(context).day) {
      return DateTime(date.year, date.month, date.day);
    } else if (selectedPeriod == S.of(context).week) {
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    } else if (selectedPeriod == S.of(context).month) {
      return DateTime(date.year, date.month);
    } else if (selectedPeriod == S.of(context).year) {
      return DateTime(date.year);
    } else {
      return DateTime(date.year, date.month, date.day);
    }
  }
}
