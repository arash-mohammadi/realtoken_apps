import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:realtokens/modals/modal_others_pie.dart'; // Assurez-vous que ce fichier existe

class TokenDistributionByRegionCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByRegionCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByRegionCardState createState() => _TokenDistributionByRegionCardState();
}

class _TokenDistributionByRegionCardState extends State<TokenDistributionByRegionCard> {
  int? _selectedIndexRegion;
  final ValueNotifier<int?> _selectedIndexNotifierRegion = ValueNotifier<int?>(null);
  List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

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
              S.of(context).tokenDistributionByRegion,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierRegion,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByRegion(widget.dataManager, othersDetails, selectedIndex),
                          centerSpaceRadius: 70,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierRegion.value = touchedIndex >= 0 ? touchedIndex : null;

                                if (event is FlTapUpEvent) {
                                  final section = response.touchedSection!.touchedSection;
                                  if (section!.title.contains(S.of(context).others)) {
                                    showOtherDetailsModal(context, widget.dataManager, othersDetails, 'region');
                                  }
                                }
                              } else {
                                _selectedIndexNotifierRegion.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterTextByRegion(widget.dataManager, selectedIndex, othersDetails),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByRegion(widget.dataManager, othersDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails, int? selectedIndex) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String regionCode = parts.length >= 3 ? parts[2].trim().substring(0, 2) : S.of(context).unknown;

      String regionName = Parameters.usStateAbbreviations[regionCode] ?? regionCode;
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = regionCount.values.fold(0, (sum, value) => sum + value);

    // Trier les régions par 'count' croissant
    final sortedRegions = regionCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    othersDetails.clear();
    int othersValue = 0;

    for (var entry in sortedRegions) {
      final region = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(sortedRegions.indexOf(entry));

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final bool isSelected = selectedIndex == sortedRegions.indexOf(entry);
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: baseColor.withOpacity(opacity),
          radius: isSelected ? 50 : 40,
          titleStyle: TextStyle(
            fontSize: isSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
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
        title: '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
        color: Colors.grey.withOpacity(selectedIndex != null && selectedIndex == sections.length ? 1.0 : 0.5),
        radius: selectedIndex != null && selectedIndex == sections.length ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: selectedIndex != null && selectedIndex == sections.length ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  Widget _buildCenterTextByRegion(DataManager dataManager, int? selectedIndex, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String regionCode = parts.length >= 3 ? parts[2].trim().substring(0, 2) : S.of(context).unknown;

      String regionName = Parameters.usStateAbbreviations[regionCode] ?? regionCode;
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = regionCount.values.fold(0, (sum, value) => sum + value);

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
    final sortedRegions = regionCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (selectedIndex < sortedRegions.length) {
      final selectedRegion = sortedRegions[selectedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedRegion.key,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            selectedRegion.value.toString(),
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
            othersDetails.fold<int>(0, (sum, item) => sum + (item['count'] as int)).toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLegendByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String regionCode = token['regionCode'] ?? 'Unknown Region';
      String regionName = Parameters.usStateAbbreviations[regionCode] ?? regionCode;
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Trier les régions par 'count' croissant
    final sortedRegions = regionCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> legendItems = [];
    int othersValue = 0;

    for (var entry in sortedRegions) {
      final region = entry.key;
      final value = entry.value;
      final double percentage = (value / regionCount.values.fold(0, (sum, v) => sum + v)) * 100;
      final color = generateColor(sortedRegions.indexOf(entry));

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
      } else {
        // Ajouter un élément de légende pour cette région
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
                region,
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

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.start,
          children: legendItems,
        ),
      ),
    );
  }

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
}
