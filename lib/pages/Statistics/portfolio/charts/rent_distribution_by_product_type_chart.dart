import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/components/section_card_widget.dart';
import 'package:realtoken_asset_tracker/utils/style_constants.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class RentDistributionByProductTypeChart extends StatefulWidget {
  final DataManager dataManager;

  const RentDistributionByProductTypeChart({
    super.key,
    required this.dataManager,
  });

  @override
  State<RentDistributionByProductTypeChart> createState() => _RentDistributionByProductTypeChartState();
}

class _RentDistributionByProductTypeChartState extends State<RentDistributionByProductTypeChart> {

  Map<String, double> _calculateRentByProductType() {
    Map<String, double> rentByProductType = {};
    
    for (var token in widget.dataManager.portfolio) {
      final String productType = token['productType'] ?? 'other';
      final double totalRentReceived = (token['totalRentReceived'] ?? 0.0).toDouble();
      
      if (totalRentReceived > 0) {
        rentByProductType[productType] = (rentByProductType[productType] ?? 0.0) + totalRentReceived;
      }
    }
    
    return rentByProductType;
  }

  String _getLocalizedProductTypeName(BuildContext context, String productType) {
    switch (productType.toLowerCase()) {
      case 'real_estate_rental':
        return S.of(context).productTypeRealEstateRental;
      case 'factoring_profitshare':
        return S.of(context).productTypeFactoringProfitshare;
      case 'loan_income':
        return S.of(context).productTypeLoanIncome;
      default:
        return S.of(context).productTypeOther;
    }
  }

  List<Color> _getColors() {
    return [
      const Color(0xFF4285F4), // Bleu
      const Color(0xFF34A853), // Vert
      const Color(0xFFEA4335), // Rouge
      const Color(0xFFFBBC04), // Jaune
      const Color(0xFF9C27B0), // Violet
      const Color(0xFFFF9800), // Orange
      const Color(0xFF607D8B), // Bleu-gris
      const Color(0xFF795548), // Marron
      const Color(0xFFE91E63), // Rose
      const Color(0xFF00BCD4), // Cyan
    ];
  }

  List<PieChartSectionData> _createSections(Map<String, double> data) {
    final List<Color> colors = _getColors();
    final double total = data.values.fold(0.0, (sum, value) => sum + value);
    
    if (total == 0) return [];
    
    List<MapEntry<String, double>> sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedData.asMap().entries.map((entry) {
      final int index = entry.key;
      final String productType = entry.value.key;
      final double value = entry.value.value;
      final double percentage = (value / total) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context, Map<String, double> data) {
    final List<Color> colors = _getColors();
    final double total = data.values.fold(0.0, (sum, value) => sum + value);
    
    if (total == 0) {
      return Center(
        child: Text(
          S.of(context).noDataAvailable,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }
    
    List<MapEntry<String, double>> sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedData.asMap().entries.map((entry) {
        final int index = entry.key;
        final String productType = entry.value.key;
        final double value = entry.value.value;
        final double percentage = (value / total) * 100;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getLocalizedProductTypeName(context, productType),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Vérification de sécurité pour éviter les erreurs de renderObject
    if (!mounted) {
      return Container();
    }

    try {
      final rentByProductType = _calculateRentByProductType();

      return SectionCardWidget(
        title: S.of(context).rentDistributionByProductType,
        contentPadding: const EdgeInsets.all(12.0),
        children: [
          if (rentByProductType.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  S.of(context).noDataAvailable,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  // Graphique en donut
                  Expanded(
                    flex: 3,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          sections: _createSections(rentByProductType),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Légende
                  Expanded(
                    flex: 2,
                    child: _buildLegend(context, rentByProductType),
                  ),
                ],
              ),
            ),
        ],
      );
    } catch (e) {
      debugPrint("Error building RentDistributionByProductTypeChart: $e");
      return SectionCardWidget(
        title: "Répartition des loyers par type",
        contentPadding: const EdgeInsets.all(12.0),
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Erreur de chargement du graphique",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }
  }
} 