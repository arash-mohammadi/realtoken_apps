import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/components/charts/generic_chart_widget.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/models/apy_record.dart';

class ApyHistoryGraph extends StatelessWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final bool apyIsBarChart;
  final Function(String) onPeriodChanged;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;

  const ApyHistoryGraph({
    super.key,
    required this.dataManager,
    required this.selectedPeriod,
    required this.apyIsBarChart,
    required this.onPeriodChanged,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Définir les couleurs pour les séries empilées
    final Color netColor = const Color(0xFF5AC8FA); // Bleu pour net
    final Color grossColor = const Color(0xFFFF9500); // Orange pour brut
    
    return GenericChartWidget<APYRecord>(
      title: S.of(context).apyHistory,
      chartColor: netColor, // Utiliser la couleur de la série principale
      stackColors: [netColor, grossColor], // Couleurs pour l'empilement
      dataList: dataManager.apyHistory,
      selectedPeriod: selectedPeriod,
      onPeriodChanged: onPeriodChanged,
      isBarChart: apyIsBarChart,
      onChartTypeChanged: onChartTypeChanged,
      selectedTimeRange: selectedTimeRange,
      onTimeRangeChanged: onTimeRangeChanged,
      timeOffset: timeOffset,
      onTimeOffsetChanged: onTimeOffsetChanged,
      getYValue: (record) => record?.apy ?? 0.0,
      // Fournir les valeurs pour l'empilement
      getStackValues: (record) {
        final netValue = record?.netApy ?? record?.apy ?? 0.0;
        final grossValue = record?.grossApy ?? record?.apy ?? 0.0;
        
        // Si gross est inférieur à net (rare), on affiche juste la valeur nette
        final grossDiff = grossValue > netValue ? grossValue - netValue : 0.0;
        
        return [netValue, grossDiff];
      },
      getTimestamp: (record) => record?.timestamp ?? DateTime.now(),
      valuePrefix: '',
      valueSuffix: '%',
      maxY: 20, // Limiter la hauteur à 20%
      isStacked: true, // Activer l'affichage empilé pour APY
      stackLabels: [S.of(context).net, S.of(context).brute], // Ajouter les étiquettes pour la légende
    );
  }
}
