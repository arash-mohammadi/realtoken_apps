import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/models/roi_record.dart';
import 'package:realtokens/components/charts/generic_chart_widget.dart';

class RoiHistoryGraph extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool roiIsBarChart;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;

  const RoiHistoryGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.roiIsBarChart,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return GenericChartWidget<ROIRecord>(
      title: S.of(context).roiHistory,
      chartColor: const Color(0xFF34C759), // Vert iOS
      dataList: dataManager.roiHistory,
      selectedPeriod: selectedPeriod,
      onPeriodChanged: onPeriodChanged,
      isBarChart: roiIsBarChart,
      onChartTypeChanged: onChartTypeChanged,
      selectedTimeRange: selectedTimeRange,
      onTimeRangeChanged: onTimeRangeChanged,
      timeOffset: timeOffset,
      onTimeOffsetChanged: onTimeOffsetChanged,
      getYValue: (record) => record.roi < 1 ? 1 : record.roi,
      getTimestamp: (record) => record.timestamp,
      valuePrefix: '',
      valueSuffix: '%',
      maxY: 20, // Limiter la hauteur à 20%
    );
  }
}
