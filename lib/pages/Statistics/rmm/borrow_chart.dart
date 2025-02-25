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
    Key? key,
  }) : super(key: key);

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
      usdcSpots.add(FlSpot(i.toDouble(), groups[i].usdc));
      xdaiSpots.add(FlSpot(i.toDouble(), groups[i].xdai));
    }

    // Calcul de la valeur maximale pour l'axe vertical (avec une marge de 20%).
    double calculatedMaxY = 0;
    for (final group in groups) {
      calculatedMaxY = group.usdc > calculatedMaxY ? group.usdc : calculatedMaxY;
      calculatedMaxY = group.xdai > calculatedMaxY ? group.xdai : calculatedMaxY;
    }
    final maxY = calculatedMaxY > 0 ? calculatedMaxY * 1.2 : 10.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= groups.length) return const SizedBox();
                final groupDate = groups[index].groupDate;
                String label;
                if (selectedPeriod == S.of(context).day) {
                  label = DateFormat('dd/MM').format(groupDate);
                } else if (selectedPeriod == S.of(context).week) {
                  label = 'W${CustomDateUtils.weekNumber(groupDate).toString().padLeft(2, '0')}';
                } else if (selectedPeriod == S.of(context).month) {
                  label = DateFormat('MM/yyyy').format(groupDate);
                } else if (selectedPeriod == S.of(context).year) {
                  label = DateFormat('yyyy').format(groupDate);
                } else {
                  label = DateFormat('dd/MM').format(groupDate);
                }
                return Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                final formattedValue = currencyUtils.getFormattedAmount(
                  value,
                  currencyUtils.currencySymbol,
                  appState.showAmounts, // Applique le masquage des montants
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
            isCurved: false,
            dotData: FlDotData(show: false),
            barWidth: 2,
            color: Colors.orange,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.2),
                  Colors.orange.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: xdaiSpots,
            isCurved: false,
            dotData: FlDotData(show: false),
            barWidth: 2,
            color: Colors.red,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.2),
                  Colors.red.withOpacity(0),
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
                periodLabel = 'W${CustomDateUtils.weekNumber(group.groupDate).toString().padLeft(2, '0')}';
              } else if (selectedPeriod == S.of(context).month) {
                periodLabel = DateFormat('MM/yyyy').format(group.groupDate);
              } else if (selectedPeriod == S.of(context).year) {
                periodLabel = DateFormat('yyyy').format(group.groupDate);
              } else {
                periodLabel = DateFormat('dd/MM/yyyy').format(group.groupDate);
              }
              final tooltipText = "$periodLabel\n"
                  "USDC: ${currencyUtils.getFormattedAmount(currencyUtils.convert(group.usdc), currencyUtils.currencySymbol, appState.showAmounts)}\n"
                  "xDai: ${currencyUtils.getFormattedAmount(currencyUtils.convert(group.xdai), currencyUtils.currencySymbol, appState.showAmounts)}";
// Retourne le tooltip complet uniquement pour le premier touched spot, sinon un tooltip vide.
              return touchedSpots.map((spot) {
                if (identical(spot, touchedSpots.first)) {
                  return LineTooltipItem(
                    tooltipText,
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10 + appState.getTextSizeOffset(),
                    ),
                  );
                } else {
                  return LineTooltipItem('', const TextStyle(fontSize: 0));
                }
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  /// Regroupe les enregistrements d'emprunt (USDC et xDai) par période.
  List<_BorrowGroup> _groupBorrows(BuildContext context) {
    Map<DateTime, _BorrowGroup> groups = {};

    void addRecord(BalanceRecord record, String tokenKey) {
      final DateTime groupDate = _truncateDate(record.timestamp, context);
      if (!groups.containsKey(groupDate)) {
        groups[groupDate] = _BorrowGroup(groupDate: groupDate, usdc: 0, xdai: 0);
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
