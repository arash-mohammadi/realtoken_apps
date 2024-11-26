import 'package:flutter/services.dart';
import 'package:realtokens_apps/pages/Statistics/Modal_others_pie.dart';
import 'package:realtokens_apps/utils/parameters.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'package:realtokens_apps/api/data_manager.dart';
import 'package:realtokens_apps/generated/l10n.dart'; // Import pour les traductions
import 'package:realtokens_apps/app_state.dart'; // Import AppState
import 'package:logger/logger.dart';

class PortfolioStats extends StatefulWidget {
  const PortfolioStats({super.key});

  @override
  _PortfolioStats createState() => _PortfolioStats();
}

class _PortfolioStats extends State<PortfolioStats> {
  static final logger = Logger(); // Initialiser une instance de logger

  late String _selectedPeriod;
  late String _selectedFilter; // Ajoutez une variable pour le filtre

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Region'; // Valeur par défaut

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);
        logger.i("Fetching rent data and property data...");
        Utils.loadData(context);
        dataManager.fetchPropertyData();
      } catch (e, stacktrace) {
        logger.i("Error during initState: $e");
        logger.i("Stacktrace: $stacktrace");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedPeriod = S.of(context).month; // Initialisation avec la traduction après que le contexte est disponible.
  }

  List<Map<String, dynamic>> _groupRentDataByPeriod(DataManager dataManager) {
    if (_selectedPeriod == S.of(context).week) {
      return _groupByWeek(dataManager.rentData);
    } else if (_selectedPeriod == S.of(context).month) {
      return _groupByMonth(dataManager.rentData);
    } else {
      return _groupByYear(dataManager.rentData);
    }
  }

  List<Map<String, dynamic>> _groupByWeek(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};

    for (var entry in data) {
      if (entry.containsKey('date') && entry.containsKey('rent')) {
        try {
          DateTime date = DateTime.parse(entry['date']);
          String weekKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}"; // Semaine formatée avec deux chiffres
          groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
        } catch (e) {
          // En cas d'erreur de parsing de date ou autre, vous pouvez ignorer cette entrée ou la traiter différemment
          logger.w("Erreur lors de la conversion de la date : ${entry['date']}");
        }
      }
    }

    // Conversion de groupedData en une liste de maps
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByMonth(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String monthKey = DateFormat('yy-MM').format(date);
      groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  List<Map<String, dynamic>> _groupByYear(List<Map<String, dynamic>> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String yearKey = date.year.toString();
      groupedData[yearKey] = (groupedData[yearKey] ?? 0) + entry['rent'];
    }
    return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Try to access DataManager from the provider
    DataManager? dataManager;
    try {
      dataManager = Provider.of<DataManager>(context);
    } catch (e, stacktrace) {
      logger.i("Error accessing DataManager: $e");
      logger.i("Stacktrace: $stacktrace");
      return Center(child: Text("Error loading data"));
    }

    // If dataManager is still null, return an error message
    if (dataManager == null) {
      return Center(child: Text("DataManager is unavailable"));
    }

    // Retrieve app state and grouped data
    List<Map<String, dynamic>> groupedData = _groupRentDataByPeriod(dataManager);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;
    final double fixedCardHeight = 380; // Hauteur fixe pour toutes les cartes

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 80.0, left: 8.0, right: 8.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 2 : 1,
                mainAxisSpacing: 8.0, // Espacement vertical entre les cartes
                crossAxisSpacing: 8.0, // Espacement horizontal entre les cartes
                mainAxisExtent: fixedCardHeight, // Hauteur fixe pour chaque carte
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  // Return widgets based on index
                  switch (index) {
                    case 0:
                      return _buildRentDistributionCard(dataManager!);
                    case 1:
                      return _buildTokenDistributionCard(dataManager!);
                    case 2:
                      return _buildTokenDistributionByCountryCard(dataManager!);
                    case 3:
                      return _buildTokenDistributionByRegionCard(dataManager!);
                    case 4:
                      return _buildTokenDistributionByCityCard(dataManager!);
                    default:
                      return Container();
                  }
                },
                childCount: 5, // Total number of chart widgets
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentDistributionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).rentDistribution,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: [
                    DropdownMenuItem(value: 'Country', child: Text(S.of(context).country)),
                    DropdownMenuItem(value: 'Region', child: Text(S.of(context).region)),
                    DropdownMenuItem(value: 'City', child: Text(S.of(context).city)),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Graphique
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildRentDonutChartData(dataManager),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Légende avec Flexible
            Flexible(
              child: SingleChildScrollView(
                child: _buildRentLegend(dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentLegend(DataManager dataManager) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final appState = Provider.of<AppState>(context);

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: groupedData.entries.map((entry) {
        final index = groupedData.keys.toList().indexOf(entry.key);
        final color = generateColor(index);

        // Convertir les abréviations d'état en noms complets si possible
        String displayKey = Parameters.usStateAbbreviations[entry.key] ?? entry.key;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200), // Largeur maximale pour éviter les débordements
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$displayKey: ${Utils.formatCurrency(dataManager.convert(entry.value), dataManager.currencySymbol)}',
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildRentDonutChartData(DataManager dataManager) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);

    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);

    return groupedData.entries.map((entry) {
      final percentage = (entry.value / totalRent) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: generateColor(groupedData.keys.toList().indexOf(entry.key)),
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + Provider.of<AppState>(context).getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Map<String, double> _groupRentDataBySelectedFilter(DataManager dataManager) {
    Map<String, double> groupedData = {};

    for (var token in dataManager.portfolio) {
      String key;
      switch (_selectedFilter) {
        case 'Country':
          key = token['country'] ?? 'Unknown Country';
          break;
        case 'Region':
          key = token['regionCode'] ?? 'Unknown Region';
          break;
        case 'City':
          key = token['city'] ?? 'Unknown City';
          break;
        default:
          key = 'Unknown';
      }

      // Additionner les revenus locatifs (monthlyIncome)
      groupedData[key] = (groupedData[key] ?? 0) + (token['monthlyIncome'] ?? 0.0);
    }

    return groupedData;
  }

  Widget _buildTokenDistributionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistribution,
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildDonutChartData(dataManager),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegend(dataManager),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByCountryCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistributionByCountry,
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildDonutChartDataByCountry(dataManager),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegendByCountry(dataManager),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByRegionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistributionByRegion,
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildDonutChartDataByRegion(dataManager, othersDetails),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                        final section = pieTouchResponse.touchedSection!.touchedSection;

                        if (event is FlTapUpEvent) {
                          // Gérer uniquement les événements de tap final
                          if (section!.title.contains(S.of(context).others)) {
                            showOtherDetailsModal(context, dataManager, othersDetails, 'region'); // Passer les détails de "Autres"
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegendByRegion(dataManager, othersDetails),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDistributionByCityCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistributionByCity,
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildDonutChartDataByCity(dataManager, othersDetails),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                        final section = pieTouchResponse.touchedSection!.touchedSection;

                        if (event is FlTapUpEvent) {
                          // Gérer uniquement les événements de tap final
                          if (section!.title.contains(S.of(context).others)) {
                            showOtherDetailsModal(context, dataManager, othersDetails, 'city'); // Passer les détails de "Autres"
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegendByCity(dataManager, othersDetails),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return dataManager.propertyData.map((data) {
      final double percentage = (data['count'] / dataManager.propertyData.fold(0.0, (double sum, item) => sum + item['count'])) * 100;

      // Obtenir la couleur de base et créer des nuances
      final Color baseColor = _getPropertyColor(data['propertyType']);
      final Color lighterColor = Utils.shadeColor(baseColor, 1); // plus clair
      final Color darkerColor = Utils.shadeColor(baseColor, 0.7); // plus foncé

      return PieChartSectionData(
        value: data['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        // Supposons que le champ 'gradient' soit pris en charge
        gradient: LinearGradient(
          colors: [lighterColor, darkerColor], // Appliquer le dégradé avec les deux nuances
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        radius: 50,
        titleStyle: TextStyle(fontSize: 10 + appState.getTextSizeOffset(), color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Widget _buildLegend(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Flexible(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: dataManager.propertyData.map((data) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: _getPropertyColor(data['propertyType']),
                ),
                const SizedBox(width: 4),
                Text(
                  Parameters.getPropertyTypeName(data['propertyType'], context),
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegendByCountry(DataManager dataManager) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    // Compter les occurrences par pays
    for (var token in dataManager.portfolio) {
      String country = token['country'] ?? 'Unknown Country';
      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    // Utiliser le même tri que pour le graphique
    final sortedCountries = countryCount.keys.toList()..sort();

    return Flexible(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sortedCountries.map((country) {
            final int index = sortedCountries.indexOf(country);
            final color = generateColor(index);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '$country: ${countryCount[country]}',
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
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

    // Liste triée pour un index cohérent entre les légendes et le graphique
    final sortedRegions = regionCount.keys.toList()..sort();

    List<Widget> legendItems = [];
    int othersValue = 0;

    for (var region in sortedRegions) {
      final value = regionCount[region]!;
      final double percentage = (value / regionCount.values.fold(0, (sum, v) => sum + v)) * 100;
      final color = generateColor(sortedRegions.indexOf(region));

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
      } else {
        // Ajouter un élément de légende pour cette région
        legendItems.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$region: $value',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
          ],
        ));
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
            '${S.of(context).others}: $othersValue',
            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
          ),
        ],
      ));
    }

    return Flexible(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: legendItems,
        ),
      ),
    );
  }

  Widget _buildLegendByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String fullName = token['fullName'];
      List<String> parts = fullName.split(',');
      String city = parts.length >= 2 ? parts[1].trim() : 'Unknown City';

      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par ordre alphabétique pour un index constant
    final sortedCities = cityCount.keys.toList()..sort();

    List<Widget> legendItems = [];
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var city in sortedCities) {
      final value = cityCount[city]!;
      final double percentage = (value / totalCount) * 100;
      final color = generateColor(sortedCities.indexOf(city)); // Appliquer la couleur générée

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add({'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        // Ajouter un élément de légende pour cette ville
        legendItems.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$city: $value',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
          ],
        ));
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
            '${S.of(context).others}: $othersValue',
            style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
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

  List<PieChartSectionData> _buildDonutChartDataByCountry(DataManager dataManager) {
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
    return sortedCountries.map((country) {
      final int value = countryCount[country]!;
      final double percentage = (value / countryCount.values.reduce((a, b) => a + b)) * 100;

      // Utiliser `generateColor` avec l'index dans `sortedCountries`
      final int index = sortedCountries.indexOf(country);
      final Color baseColor = generateColor(index);

      // Créer des nuances pour le gradient
      final Color lighterColor = Utils.shadeColor(baseColor, 1);
      final Color darkerColor = Utils.shadeColor(baseColor, 0.7);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 1 ? '' : '${percentage.toStringAsFixed(1)}%',
        gradient: LinearGradient(
          colors: [lighterColor, darkerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        radius: 50,
        titleStyle: TextStyle(fontSize: 10 + appState.getTextSizeOffset(), color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildDonutChartDataByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
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
    final sortedRegions = regionCount.keys.toList()..sort();

    List<PieChartSectionData> sections = [];
    othersDetails.clear();
    int othersValue = 0;

    for (var region in sortedRegions) {
      final value = regionCount[region]!;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(sortedRegions.indexOf(region));

      // Créer des nuances pour le gradient
      final Color lighterColor = Utils.shadeColor(baseColor, 1);
      final Color darkerColor = Utils.shadeColor(baseColor, 0.7);

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          gradient: LinearGradient(
            colors: [lighterColor, darkerColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 10 + appState.getTextSizeOffset(),
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
        color: Colors.grey,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  List<PieChartSectionData> _buildDonutChartDataByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par ordre alphabétique pour un index constant
    final sortedCities = cityCount.keys.toList()..sort();

    List<PieChartSectionData> sections = [];
    othersDetails.clear(); // Clear previous details of "Autres"
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var city in sortedCities) {
      final value = cityCount[city]!;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(sortedCities.indexOf(city)); // Appliquer la couleur générée

      // Créer des nuances pour le gradient
      final Color lighterColor = Utils.shadeColor(baseColor, 1);
      final Color darkerColor = Utils.shadeColor(baseColor, 0.7);

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          gradient: LinearGradient(
            colors: [lighterColor, darkerColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 10 + appState.getTextSizeOffset(),
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
        color: Colors.grey,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360; // Alterne entre plusieurs intervalles de teinte
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7); // Variation de la saturation
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9); // Variation de la luminosité
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
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
