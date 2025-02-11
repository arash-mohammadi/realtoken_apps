import 'package:flutter/services.dart';
import 'package:realtokens/pages/Statistics/portfolio/Modal_others_pie.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart'; // Import pour les traductions
import 'package:realtokens/app_state.dart'; // Import AppState
import 'package:realtokens/utils/ui_utils.dart';

class PortfolioStats extends StatefulWidget {
  const PortfolioStats({super.key});

  @override
  _PortfolioStats createState() => _PortfolioStats();
}

class _PortfolioStats extends State<PortfolioStats> {

  late String _selectedPeriod;
  late String _selectedFilter; // Ajoutez une variable pour le filtre

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Region'; // Valeur par défaut

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        debugPrint("Fetching rent data and property data...");
        DataFetchUtils.loadData(context);
      } catch (e, stacktrace) {
        debugPrint("Error during initState: $e");
        debugPrint("Stacktrace: $stacktrace");
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
          String weekKey = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}"; // Semaine formatée avec deux chiffres
          groupedData[weekKey] = (groupedData[weekKey] ?? 0) + entry['rent'];
        } catch (e) {
          // En cas d'erreur de parsing de date ou autre, vous pouvez ignorer cette entrée ou la traiter différemment
          debugPrint("❌ Erreur lors de la conversion de la date : ${entry['date']}");
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
      debugPrint("Error accessing DataManager: $e");
      debugPrint("Stacktrace: $stacktrace");
      return Center(child: Text("Error loading data"));
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

  //---------------------------------------------------------------------------------------
  // ------------------------------------ Graphique des loyers ----------------------------
  // --------------------------------------------------------------------------------------

  int? _selectedIndex;
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null); // Pour suivre l'index sélectionné

  Widget _buildRentDistributionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0.5,
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
                      _selectedIndexNotifier.value = null; // Réinitialiser la sélection lors du changement de filtre
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Graphique
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildRentDonutChartData(dataManager, selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                // Mettre à jour le ValueNotifier
                                _selectedIndexNotifier.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                // Si l'utilisateur clique en dehors du graphique, désélectionner tout
                                _selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      // Texte affiché au centre
                      _buildCenterText(dataManager, selectedIndex),
                    ],
                  );
                },
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

  List<PieChartSectionData> _buildRentDonutChartData(DataManager dataManager, int? selectedIndex) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);

    // Trier les données en ordre décroissant par valeur
    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value / totalRent) * 100;

      final bool isSelected = selectedIndex == index;

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      return PieChartSectionData(
        value: data.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: generateColor(index).withOpacity(opacity), // Opacité conditionnelle
        radius: isSelected ? 50 : 40, // Augmenter légèrement la taille de la section sélectionnée
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + Provider.of<AppState>(context).getTextSizeOffset() : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildCenterText(DataManager dataManager, int? selectedIndex) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);

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
            CurrencyUtils.getFormattedAmount(dataManager.convert(totalRent), dataManager.currencySymbol, true),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // Afficher les détails du segment sélectionné
    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final selectedEntry = sortedEntries[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Parameters.usStateAbbreviations[selectedEntry.key] ?? selectedEntry.key,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          CurrencyUtils.getFormattedAmount(dataManager.convert(selectedEntry.value), dataManager.currencySymbol, true),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey,
          ),
        ),
      ],
    );
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

  Widget _buildRentLegend(DataManager dataManager) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final appState = Provider.of<AppState>(context);

    // Trier les données en ordre décroissant par valeur
    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.map((entry) {
        final index = sortedEntries.indexOf(entry); // Index basé sur l'ordre trié
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
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4), // Bordures arrondies
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
                  displayKey,
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  //----------------------------------------------------------------------------------------
  // --------------------------------- Graphique par Type de propriété ---------------------
  // ---------------------------------------------------------------------------------------

  int? _selectedIndexToken;

  final ValueNotifier<int?> _selectedIndexNotifierToken = ValueNotifier<int?>(null); // Pour suivre l'index sélectionné

  Widget _buildTokenDistributionCard(DataManager dataManager) {
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
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Graphique
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
                          sections: _buildDonutChartData(dataManager, selectedIndex),
                          centerSpaceRadius: 70,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                // Mettre à jour le ValueNotifier
                                _selectedIndexNotifierToken.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                // Si l'utilisateur clique en dehors du graphique, désélectionner tout
                                _selectedIndexNotifierToken.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      // Texte affiché au centre
                      _buildCenterTextToken(dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Légende avec Flexible
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegend(dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(DataManager dataManager, int? selectedIndex) {
    final appState = Provider.of<AppState>(context);

    // Trier les données par 'count' dans l'ordre décroissant
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)..sort((a, b) => b['count'].compareTo(a['count']));

    return sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final double percentage = (data['count'] / dataManager.propertyData.fold(0.0, (double sum, item) => sum + item['count'])) * 100;

      final bool isSelected = selectedIndex == index;

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Obtenir la couleur de base et créer des nuances
      final Color baseColor = _getPropertyColor(data['propertyType']);
      final Color lighterColor = UIUtils.shadeColor(baseColor, 1); // plus clair
      final Color darkerColor = UIUtils.shadeColor(baseColor, 0.7); // plus foncé

      return PieChartSectionData(
        value: data['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withOpacity(opacity), // Opacité conditionnelle
        radius: isSelected ? 50 : 40, // Augmenter légèrement la taille de la section sélectionnée
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
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

    print('propertyData: ${dataManager.propertyData}');

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
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)..sort((a, b) => b['count'].compareTo(a['count']));

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
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)..sort((a, b) => b['count'].compareTo(a['count']));

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedData.map((data) {
        final index = sortedData.indexOf(data);
        final color = _getPropertyColor(data['propertyType']);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200), // Largeur maximale pour éviter les débordements
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4), // Bordures arrondies
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

  //----------------------------------------------------------------------------------------
  // --------------------------------- Graphique par Type de pays --------------------------
  // ---------------------------------------------------------------------------------------

  int? _selectedIndexCountry;
  final ValueNotifier<int?> _selectedIndexNotifierCountry = ValueNotifier<int?>(null); // Pour suivre l'index sélectionné

  Widget _buildTokenDistributionByCountryCard(DataManager dataManager) {
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
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Graphique
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
                          sections: _buildDonutChartDataByCountry(dataManager, selectedIndex),
                          centerSpaceRadius: 70, // Augmenter l'espace central
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                // Mettre à jour le ValueNotifier
                                _selectedIndexNotifierCountry.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                // Si l'utilisateur clique en dehors du graphique, désélectionner tout
                                _selectedIndexNotifierCountry.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      // Texte affiché au centre
                      _buildCenterTextByCountry(dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Légende avec Flexible
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByCountry(dataManager),
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

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Utiliser `generateColor` avec l'index dans `sortedCountries`
      final Color baseColor = generateColor(index);

      // Créer des nuances pour le gradient
      final Color lighterColor = UIUtils.shadeColor(baseColor, 1);
      final Color darkerColor = UIUtils.shadeColor(baseColor, 0.7);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 1 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withOpacity(opacity), // Opacité conditionnelle
        radius: isSelected ? 50 : 40, // Réduire légèrement le rayon des sections
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
          constraints: BoxConstraints(maxWidth: 200), // Largeur maximale pour éviter les débordements
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4), // Bordures arrondies
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

  //----------------------------------------------------------------------------------------
  // --------------------------------- Graphique par Region --------------------------------
  // ---------------------------------------------------------------------------------------

  int? _selectedIndexRegion;
  final ValueNotifier<int?> _selectedIndexNotifierRegion = ValueNotifier<int?>(null); // Pour suivre l'index sélectionné

  Widget _buildTokenDistributionByRegionCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

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
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Graphique
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
                          sections: _buildDonutChartDataByRegion(dataManager, othersDetails, selectedIndex),
                          centerSpaceRadius: 70, // Augmenter l'espace central
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                // Mettre à jour le ValueNotifier
                                _selectedIndexNotifierRegion.value = touchedIndex >= 0 ? touchedIndex : null;

                                if (event is FlTapUpEvent) {
                                  final section = response.touchedSection!.touchedSection;
                                  if (section!.title.contains(S.of(context).others)) {
                                    showOtherDetailsModal(context, dataManager, othersDetails, 'region'); // Passer les détails de "Autres"
                                  }
                                }
                              } else {
                                // Si l'utilisateur clique en dehors du graphique, désélectionner tout
                                _selectedIndexNotifierRegion.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      // Texte affiché au centre
                      _buildCenterTextByRegion(dataManager, selectedIndex, othersDetails),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Légende avec Flexible
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByRegion(dataManager, othersDetails),
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
          color: baseColor.withOpacity(opacity), // Opacité conditionnelle
          radius: isSelected ? 50 : 40, // Réduire légèrement le rayon des sections
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
        color: Colors.grey.withOpacity(selectedIndex != null && selectedIndex == sections.length ? 1.0 : 0.5), // Opacité conditionnelle
        radius: selectedIndex != null && selectedIndex == sections.length ? 50 : 40, // Réduire légèrement le rayon des sections
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
        legendItems.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4), // Bordures arrondies
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
            Text(
              region,
              style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
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
            S.of(context).others,
            style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
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

  //----------------------------------------------------------------------------------------
  // --------------------------------- Graphique par Ville --------------------------------
  // ---------------------------------------------------------------------------------------

  int? _selectedIndexCity;
  final ValueNotifier<int?> _selectedIndexNotifierCity = ValueNotifier<int?>(null); // Pour suivre l'index sélectionné

  Widget _buildTokenDistributionByCityCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

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
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Graphique
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
                          sections: _buildDonutChartDataByCity(dataManager, othersDetails, selectedIndex),
                          centerSpaceRadius: 70, // Augmenter l'espace central
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                // Mettre à jour le ValueNotifier
                                _selectedIndexNotifierCity.value = touchedIndex >= 0 ? touchedIndex : null;

                                if (event is FlTapUpEvent) {
                                  final section = response.touchedSection!.touchedSection;
                                  if (section!.title.contains(S.of(context).others)) {
                                    showOtherDetailsModal(context, dataManager, othersDetails, 'city'); // Passer les détails de "Autres"
                                  }
                                }
                              } else {
                                // Si l'utilisateur clique en dehors du graphique, désélectionner tout
                                _selectedIndexNotifierCity.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      // Texte affiché au centre
                      _buildCenterTextByCity(dataManager, selectedIndex, othersDetails),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Légende avec Flexible
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByCity(dataManager, othersDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails, int? selectedIndex) {
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
    final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    othersDetails.clear(); // Clear previous details of "Autres"
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedCities) {
      final city = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(sortedCities.indexOf(entry)); // Appliquer la couleur générée

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final bool isSelected = selectedIndex == sortedCities.indexOf(entry);
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: baseColor.withOpacity(opacity), // Opacité conditionnelle
          radius: isSelected ? 50 : 40, // Réduire légèrement le rayon des sections
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
        color: Colors.grey.withOpacity(selectedIndex != null && selectedIndex == sections.length ? 1.0 : 0.5), // Opacité conditionnelle
        radius: selectedIndex != null && selectedIndex == sections.length ? 50 : 40, // Réduire légèrement le rayon des sections
        titleStyle: TextStyle(
          fontSize: selectedIndex != null && selectedIndex == sections.length ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return sections;
  }

  Widget _buildCenterTextByCity(DataManager dataManager, int? selectedIndex, List<Map<String, dynamic>> othersDetails) {
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
    final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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

  Widget _buildLegendByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
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
    final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> legendItems = [];
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedCities) {
      final city = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final color = generateColor(sortedCities.indexOf(entry)); // Appliquer la couleur générée

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
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4), // Bordures arrondies
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
            Text(
              city,
              style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
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
  //----------------------------------------------------------------------------------------
  // --------------------------------- Autres fonctions -----------------------------------
  // ---------------------------------------------------------------------------------------

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
