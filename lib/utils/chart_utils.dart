import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/date_utils.dart';

class ChartUtils {
  static Widget buildPeriodSelector(
    BuildContext context, {
    required String selectedPeriod,
    required Function(String) onPeriodChanged,
  }) {
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black12
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton(S.of(context).day, context, selectedPeriod, onPeriodChanged),
            _buildPeriodButton(S.of(context).week, context, selectedPeriod, onPeriodChanged),
            _buildPeriodButton(S.of(context).month, context, selectedPeriod, onPeriodChanged),
            _buildPeriodButton(S.of(context).year, context, selectedPeriod, onPeriodChanged),
          ],
        ),
      ),
    );
  }

  static Widget _buildPeriodButton(
    String period, 
    BuildContext context, 
    String selectedPeriod, 
    Function(String) onPeriodChanged
  ) {
    final isSelected = selectedPeriod == period;
    final appState = Provider.of<AppState>(context);
    
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12 + appState.getTextSizeOffset(),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  static List<FlSpot> buildHistoryChartData<T>(
      BuildContext context,
      List<T> history,
      String selectedPeriod,
      double Function(T) getValue,
      DateTime Function(T) getTimestamp) {
    Map<String, List<double>> groupedData = {};

    for (var record in history) {
      DateTime date = getTimestamp(record);
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

      groupedData.putIfAbsent(periodKey, () => []).add(getValue(record));
    }

    List<FlSpot> spots = [];
    List<String> sortedKeys = groupedData.keys.toList()..sort();

    for (int i = 0; i < sortedKeys.length; i++) {
      String periodKey = sortedKeys[i];
      List<double> values = groupedData[periodKey]!;
      double averageValue = values.reduce((a, b) => a + b) / values.length;
      spots.add(FlSpot(i.toDouble(), averageValue));
    }

    return spots;
  }

  static Widget buildPeriodButton({
    required BuildContext context,
    required String period,
    required bool isSelected,
    bool isFirst = false,
    bool isLast = false,
    required Function() onTap,
  }) {
    final appState = Provider.of<AppState>(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          child: Text(
            period,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
