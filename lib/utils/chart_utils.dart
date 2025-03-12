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
    return Row(
      children: [
        buildPeriodButton(
          context: context,
          period: S.of(context).day,
          isSelected: selectedPeriod == S.of(context).day,
          isFirst: true,
          onTap: () => onPeriodChanged(S.of(context).day),
        ),
        buildPeriodButton(
          context: context,
          period: S.of(context).week,
          isSelected: selectedPeriod == S.of(context).week,
          onTap: () => onPeriodChanged(S.of(context).week),
        ),
        buildPeriodButton(
          context: context,
          period: S.of(context).month,
          isSelected: selectedPeriod == S.of(context).month,
          onTap: () => onPeriodChanged(S.of(context).month),
        ),
        buildPeriodButton(
          context: context,
          period: S.of(context).year,
          isSelected: selectedPeriod == S.of(context).year,
          isLast: true,
          onTap: () => onPeriodChanged(S.of(context).year),
        ),
      ],
    );
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
}
