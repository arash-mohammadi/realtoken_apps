// deposit_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart'; // Pour CustomDateUtils

/// Classe privée représentant un groupe de dépôts agrégé selon la période.
class _DepositGroup {
  final DateTime groupDate;
  final double usdc;
  final double xdai;
  _DepositGroup({
    required this.groupDate,
    required this.usdc,
    required this.xdai,
  });
}

class DepositChart extends StatelessWidget {
  final Map<String, List<BalanceRecord>> allHistories;
  final String selectedPeriod;

  const DepositChart({
    required this.allHistories,
    required this.selectedPeriod,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Regroupement des données de dépôts par période.
    final groups = _groupDeposits(context);
    final minX = 0.0;
    final maxX = groups.isNotEmpty ? (groups.length - 1).toDouble() : 0.0;

    // Construction des spots pour chaque série en appliquant la conversion
    // et en empilant la courbe xDai sur la courbe USDC.
    final usdcSpots = <FlSpot>[];
    final xdaiSpots = <FlSpot>[];
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final convertedUsdc = currencyUtils.convert(group.usdc);
      final convertedXdai = currencyUtils.convert(group.xdai);
      usdcSpots.add(FlSpot(i.toDouble(), convertedUsdc));
      // La courbe xDai démarre à partir de la courbe USDC.
      xdaiSpots.add(FlSpot(i.toDouble(), convertedUsdc + convertedXdai));
    }

    // Calcul de la valeur maximale pour l'axe vertical (avec une marge de 20%).
    double calculatedMaxY = 0;
    for (final group in groups) {
      final convertedUsdc = currencyUtils.convert(group.usdc);
      final convertedXdai = currencyUtils.convert(group.xdai);
      final stackedValue = convertedUsdc + convertedXdai;
      calculatedMaxY = stackedValue > calculatedMaxY ? stackedValue : calculatedMaxY;
    }
    final maxY = calculatedMaxY > 0 ? calculatedMaxY * 1.1 : 10.0;

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
                  appState.showAmounts,
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
            color: Colors.blue,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.blue.withOpacity(0),
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
            color: Colors.green,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.2),
                  Colors.green.withOpacity(0),
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

  /// Regroupe les enregistrements de dépôts (USDC et xDai) par période.
  List<_DepositGroup> _groupDeposits(BuildContext context) {
    Map<DateTime, _DepositGroup> groups = {};

    void addRecord(BalanceRecord record, String tokenKey) {
      final DateTime groupDate = _truncateDate(record.timestamp, context);
      if (!groups.containsKey(groupDate)) {
        groups[groupDate] = _DepositGroup(groupDate: groupDate, usdc: 0, xdai: 0);
      }
      final currentGroup = groups[groupDate]!;
      if (tokenKey == 'usdc') {
        groups[groupDate] = _DepositGroup(
          groupDate: groupDate,
          usdc: currentGroup.usdc + record.balance,
          xdai: currentGroup.xdai,
        );
      } else if (tokenKey == 'xdai') {
        groups[groupDate] = _DepositGroup(
          groupDate: groupDate,
          usdc: currentGroup.usdc,
          xdai: currentGroup.xdai + record.balance,
        );
      }
    }

    if (allHistories['usdcDeposit'] != null) {
      for (var record in allHistories['usdcDeposit']!) {
        addRecord(record, 'usdc');
      }
    }
    if (allHistories['xdaiDeposit'] != null) {
      for (var record in allHistories['xdaiDeposit']!) {
        addRecord(record, 'xdai');
      }
    }

    List<_DepositGroup> groupList = groups.values.toList();
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
