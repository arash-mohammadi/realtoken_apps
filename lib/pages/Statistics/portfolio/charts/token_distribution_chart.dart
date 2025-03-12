import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/parameters.dart';

class TokenDistributionCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionCard({super.key, required this.dataManager});

  @override
  _TokenDistributionCardState createState() => _TokenDistributionCardState();
}

class _TokenDistributionCardState extends State<TokenDistributionCard> {
  int? _selectedIndexToken;
  final ValueNotifier<int?> _selectedIndexNotifierToken =
      ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistribution,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierToken,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartData(
                              widget.dataManager, selectedIndex),
                          centerSpaceRadius: 70,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                PieTouchResponse? response) {
                              if (response != null &&
                                  response.touchedSection != null) {
                                final touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierToken.value =
                                    touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifierToken.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterTextToken(widget.dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegend(widget.dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(
      DataManager dataManager, int? selectedIndex) {
    final appState = Provider.of<AppState>(context);

    // Trier les données par 'count' dans l'ordre décroissant
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    return sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final double percentage = (data['count'] /
              dataManager.propertyData
                  .fold(0.0, (double sum, item) => sum + item['count'])) *
          100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Obtenir la couleur de base et créer des nuances
      final Color baseColor = _getPropertyColor(data['propertyType']);
      final Color lighterColor = UIUtils.shadeColor(baseColor, 1); // plus clair
      final Color darkerColor =
          UIUtils.shadeColor(baseColor, 0.7); // plus foncé

      return PieChartSectionData(
        value: data['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withOpacity(opacity),
        radius: isSelected ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: isSelected
              ? 14 + appState.getTextSizeOffset()
              : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildCenterTextToken(DataManager dataManager, int? selectedIndex) {
    // Somme des valeurs de 'count'
    final totalCount = dataManager.propertyData.fold(0.0, (double sum, item) {
      final count = item['count'] ?? 0.0; // Utiliser 0.0 si 'count' est null
      return sum + (count is String ? double.tryParse(count) ?? 0.0 : count);
    });

    if (selectedIndex == null) {
      // Afficher la valeur totale si aucun segment n'est sélectionné
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'total',
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            totalCount.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // Afficher les détails du segment sélectionné
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    final selectedData = sortedData[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Parameters.getPropertyTypeName(selectedData['propertyType'], context),
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          selectedData['count'].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    // Trier les données par 'count' dans l'ordre décroissant
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedData.map((data) {
        final index = sortedData.indexOf(data);
        final color = _getPropertyColor(data['propertyType']);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  Parameters.getPropertyTypeName(data['propertyType'], context),
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getPropertyColor(int propertyType) {
    switch (propertyType) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.yellow;
      case 7:
        return Colors.teal;
      case 8:
        return Colors.brown;
      case 9:
        return Colors.pink;
      case 10:
        return Colors.cyan;
      case 11:
        return Colors.lime;
      case 12:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
