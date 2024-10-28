import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:realtokens_apps/generated/l10n.dart';

void showOtherDetailsModal(BuildContext context, dataManager, List<Map<String, dynamic>> othersDetails, String key) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permet de contrôler la taille de la modale
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.8, // Définit la hauteur de la modale à 70% de l'écran
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                S.of(context).othersTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildOtherDetailsDonutData(othersDetails, key),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Ajout de la légende en dessous du donut
              _buildLegendForModal(othersDetails, key),
            ],
          ),
        ),
      );
    },
  );
}

List<PieChartSectionData> _buildOtherDetailsDonutData(List<Map<String, dynamic>> othersDetails, String key) {
  final List<Color> sectionColors = Colors.primaries; // Utilisez une palette de couleurs
  final Set<String> uniqueEntries = {};
  
  return othersDetails.asMap().entries.map((entry) {
    final int index = entry.key;
    final String entryName = entry.value[key] ?? 'Unknown';

    if (uniqueEntries.add(entryName)) {
      final double percentage = (entry.value['count'] / othersDetails.fold<double>(0.0, (sum, e) => sum + e['count'])) * 100;

      return PieChartSectionData(
        value: entry.value['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: sectionColors[index % sectionColors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return null;
    }
  }).where((section) => section != null).toList().cast<PieChartSectionData>();
}

Widget _buildLegendForModal(List<Map<String, dynamic>> othersDetails, String key) {
  final List<Color> sectionColors = Colors.primaries;
  final Set<String> uniqueEntries = {};

  return Wrap(
    spacing: 8.0,
    runSpacing: 4.0,
    children: othersDetails.asMap().entries.map((entry) {
      final int index = entry.key;
      final String name = entry.value[key] ?? 'Unknown';

      if (uniqueEntries.add(name)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: sectionColors[index % sectionColors.length],
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      } else {
        return Container();
      }
    }).toList(),
  );
}
