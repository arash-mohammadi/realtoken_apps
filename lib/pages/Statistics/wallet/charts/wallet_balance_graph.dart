import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/components/charts/generic_chart_widget.dart';

class WalletBalanceGraph extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool balanceIsBarChart;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;

  const WalletBalanceGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.balanceIsBarChart,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return GenericChartWidget<BalanceRecord>(
      title: S.of(context).walletBalanceHistory,
      chartColor: const Color(0xFF007AFF), // Bleu iOS
      dataList: dataManager.walletBalanceHistory,
      selectedPeriod: selectedPeriod,
      onPeriodChanged: onPeriodChanged,
      isBarChart: balanceIsBarChart,
      onChartTypeChanged: onChartTypeChanged,
      selectedTimeRange: selectedTimeRange,
      onTimeRangeChanged: onTimeRangeChanged,
      timeOffset: timeOffset,
      onTimeOffsetChanged: onTimeOffsetChanged,
      getYValue: (record) => record.balance,
      getTimestamp: (record) => record.timestamp,
      valuePrefix: '',
      valueSuffix: ' €',
    );
  }
}
