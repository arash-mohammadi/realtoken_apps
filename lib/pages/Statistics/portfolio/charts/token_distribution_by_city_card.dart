import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/modals/modal_others_pie.dart'; // Assurez-vous que ce fichier existe

class TokenDistributionByCityCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByCityCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByCityCardState createState() =>
      _TokenDistributionByCityCardState();
}

class _TokenDistributionByCityCardState
    extends State<TokenDistributionByCityCard> {
  int? _selectedIndexCity;
  final ValueNotifier<int?> _selectedIndexNotifierCity =
      ValueNotifier<int?>(null);
  List<Map<String, dynamic>> othersDetails =
      []; // Pour stocker les détails de la section "Autres"

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
              S.of(context).tokenDistributionByCity,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierCity,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByCity(
                              widget.dataManager, othersDetails, selectedIndex),
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
                                _selectedIndexNotifierCity.value =
                                    touchedIndex >= 0 ? touchedIndex : null;

                                if (event is FlTapUpEvent) {
                                  final section =
                                      response.touchedSection!.touchedSection;
                                  if (section!.title
                                      .contains(S.of(context).others)) {
                                    showOtherDetailsModal(
                                        context,
                                        widget.dataManager,
                                        othersDetails,
                                        'city');
                                  }
                                }
                              } else {
                                _selectedIndexNotifierCity.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterTextByCity(
                          widget.dataManager, selectedIndex, othersDetails),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByCity(widget.dataManager, othersDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByCity(DataManager dataManager,
      List<Map<String, dynamic>> othersDetails, int? selectedIndex) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par 'count' croissant
    final sortedCities = cityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    othersDetails.clear(); // Clear previous details of "Autres"
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedCities) {
      final city = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(
          sortedCities.indexOf(entry)); // Appliquer la couleur générée

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final bool isSelected = selectedIndex == sortedCities.indexOf(entry);
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add(
            {'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
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
        ));
      }
    }

    // Ajouter la section "Autres" si nécessaire
    if (othersValue > 0) {
      final double othersPercentage = (othersValue / totalCount) * 100;
      sections.add(PieChartSectionData(
        value: othersValue.toDouble(),
        title:
            '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
        color: Colors.grey.withOpacity(
            selectedIndex != null && selectedIndex == sections.length
                ? 1.0
                : 0.5),
        radius:
            selectedIndex != null && selectedIndex == sections.length ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: selectedIndex != null && selectedIndex == sections.length
              ? 14 + appState.getTextSizeOffset()
              : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  Widget _buildCenterTextByCity(DataManager dataManager, int? selectedIndex,
      List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

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
    final sortedCities = cityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (selectedIndex < sortedCities.length) {
      final selectedCity = sortedCities[selectedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCity.key,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            selectedCity.value.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    } else {
      // Afficher les détails de la section "Autres"
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).others,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            othersDetails
                .fold<int>(0, (sum, item) => sum + (item['count'] as int))
                .toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLegendByCity(
      DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par 'count' croissant
    final sortedCities = cityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> legendItems = [];
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedCities) {
      final city = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final color = generateColor(
          sortedCities.indexOf(entry)); // Appliquer la couleur générée

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add(
            {'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        // Ajouter un élément de légende pour cette ville
        legendItems.add(
          Row(
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
                    )
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                city,
                style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
              ),
            ],
          ),
        );
      }
    }

    // Ajouter une légende pour "Autres" si nécessaire
    if (othersValue > 0) {
      legendItems.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            S.of(context).others,
            style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
          ),
        ],
      ));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: legendItems,
    );
  }

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness)
        .toColor();
  }
}
