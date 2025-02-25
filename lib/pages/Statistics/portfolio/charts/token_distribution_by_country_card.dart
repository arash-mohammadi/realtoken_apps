import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/parameters.dart';

class TokenDistributionByCountryCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByCountryCard({required this.dataManager});

  @override
  _TokenDistributionByCountryCardState createState() => _TokenDistributionByCountryCardState();
}

class _TokenDistributionByCountryCardState extends State<TokenDistributionByCountryCard> {
  int? _selectedIndexCountry;
  final ValueNotifier<int?> _selectedIndexNotifierCountry = ValueNotifier<int?>(null);

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
              S.of(context).tokenDistributionByCountry,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierCountry,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByCountry(widget.dataManager, selectedIndex),
                          centerSpaceRadius: 70,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierCountry.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifierCountry.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterTextByCountry(widget.dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByCountry(widget.dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByCountry(DataManager dataManager, int? selectedIndex) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par pays
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String country = parts.length == 4 ? parts[3].trim() : 'United States';

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    // Trier les pays par ordre alphabétique pour garantir un ordre constant
    final sortedCountries = countryCount.keys.toList()..sort();

    // Créer les sections du graphique à secteurs avec des gradients
    return sortedCountries.asMap().entries.map((entry) {
      final index = entry.key;
      final country = entry.value;
      final int value = countryCount[country]!;
      final double percentage = (value / countryCount.values.reduce((a, b) => a + b)) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Utiliser `generateColor` avec l'index dans `sortedCountries`
      final Color baseColor = generateColor(index);

      // Créer des nuances pour le gradient
      final Color lighterColor = UIUtils.shadeColor(baseColor, 1);
      final Color darkerColor = UIUtils.shadeColor(baseColor, 0.7);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 1 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withOpacity(opacity),
        radius: isSelected ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildCenterTextByCountry(DataManager dataManager, int? selectedIndex) {
    Map<String, int> countryCount = {};

    // Remplir le dictionnaire avec les counts par pays
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String country = parts.length == 4 ? parts[3].trim() : 'United States';

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    final totalCount = countryCount.values.reduce((a, b) => a + b);

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
            totalCount.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // Afficher les détails du segment sélectionné
    final sortedCountries = countryCount.keys.toList()..sort();
    final selectedCountry = sortedCountries[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedCountry,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          countryCount[selectedCountry].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendByCountry(DataManager dataManager) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    // Compter les occurrences par pays
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String country = parts.length == 4 ? parts[3].trim() : 'United States';

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    // Utiliser le même tri que pour le graphique
    final sortedCountries = countryCount.keys.toList()..sort();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedCountries.map((country) {
        final int index = sortedCountries.indexOf(country);
        final color = generateColor(index);

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
                  country,
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
}
