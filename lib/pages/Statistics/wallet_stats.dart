  import 'package:flutter/services.dart';
  import 'package:realtokens/utils/utils.dart';
  import 'package:flutter/material.dart';
  import 'package:fl_chart/fl_chart.dart';
  import 'package:provider/provider.dart';
  import 'package:intl/intl.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:realtokens/api/data_manager.dart';
  import 'package:realtokens/generated/l10n.dart'; // Import pour les traductions
  import 'package:realtokens/app_state.dart'; // Import AppState
  import 'package:logger/logger.dart';
  import 'dart:math';

  import 'package:shared_preferences/shared_preferences.dart'; // Import the math library

  class WalletStats extends StatefulWidget {
    const WalletStats({super.key});

    @override
    _WalletStats createState() => _WalletStats();
  }

  class _WalletStats extends State<WalletStats> {
    static final logger = Logger(); // Initialiser une instance de logger

// Variables pour stocker la période sélectionnée pour chaque graphique
  late String _selectedRentPeriod; // Pour le graphique des loyers
  late String _selectedWalletPeriod; // Pour le graphique du solde du portefeuille
  late String _selectedRoiPeriod; // Pour le graphique du ROI
  late String _selectedApyPeriod; // Pour le graphique de l'APY
  
  bool apyIsBarChart = true; // Basculer entre BarChart et LineChart
    bool roiIsBarChart = false; // Basculer entre BarChart et LineChart
    bool walletIsBarChart = false; // Basculer entre BarChart et LineChart
    late SharedPreferences prefs;

    @override
    void initState() {
      super.initState();
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        prefs = await SharedPreferences.getInstance();

        setState(() {
          // Charger les préférences sauvegardées ou utiliser des valeurs par défaut
          apyIsBarChart = prefs.getBool('apyIsBarChart') ?? true;
          roiIsBarChart = prefs.getBool('roiIsBarChart') ?? false;
          walletIsBarChart = prefs.getBool('walletIsBarChart') ?? false;
        });

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
_selectedRentPeriod = S.of(context).month;
    _selectedWalletPeriod = S.of(context).month;
    _selectedRoiPeriod = S.of(context).month;
    _selectedApyPeriod = S.of(context).month;    }


List<BarChartGroupData> _buildRoiHistoryBarChartData(DataManager dataManager, String selectedPeriod) {
  // Récupérer les données de ROI groupées par période
  List<FlSpot> roiHistoryData = _buildRoiHistoryChartData(dataManager, selectedPeriod);

  // Convertir les FlSpot en BarChartGroupData
  return roiHistoryData
      .asMap()
      .entries
      .map(
        (entry) => BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.y,
              color: Colors.cyan, // Couleur des barres
              width: 8, // Largeur des barres
            ),
          ],
        ),
      )
      .toList();
}

    List<Map<String, dynamic>> _groupRentDataByPeriod(DataManager dataManager) {
  if (_selectedRentPeriod == S.of(context).day) {
    return _groupByDay(dataManager.rentData); // Ajouter une méthode _groupByDay
  } else if (_selectedRentPeriod == S.of(context).week) {
    return _groupByWeek(dataManager.rentData);
  } else if (_selectedRentPeriod == S.of(context).month) {
    return _groupByMonth(dataManager.rentData);
  } else {
    return _groupByYear(dataManager.rentData);
  }
}

List<Map<String, dynamic>> _groupByDay(List<Map<String, dynamic>> data) {
  Map<String, double> groupedData = {};
  for (var entry in data) {
    DateTime date = DateTime.parse(entry['date']);
    String dayKey = DateFormat('yyyy/MM/dd').format(date); // Format jour
    groupedData[dayKey] = (groupedData[dayKey] ?? 0) + entry['rent'];
  }
  return groupedData.entries.map((entry) => {'date': entry.key, 'rent': entry.value}).toList();
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
        String monthKey = DateFormat('yyyy/MM').format(date);
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

    List<FlSpot> _buildChartData(List<Map<String, dynamic>> data) {
      List<FlSpot> spots = [];
      for (var i = 0; i < data.length; i++) {
        double rentValue = data[i]['rent']?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), rentValue));
      }
      return spots;
    }

    List<String> _buildDateLabels(List<Map<String, dynamic>> data) {
      return data.map((entry) => entry['date'].toString()).toList();
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
                        return _buildRentGraphCard(groupedData, dataManager!);
                      case 1:
                        return _buildWalletBalanceCard(dataManager!);
                      case 2:
                        return _buildRoiHistoryCard(dataManager!);
                      case 3:
                        return _buildApyHistoryCard(dataManager!);
                      default:
                        return Container();
                    }
                  },
                  childCount: 4, // Total number of chart widgets
                ),
              ),
            ),
          ],
        ),
      );
    }

    bool _showCumulativeRent = false;

    Widget _buildRentGraphCard(List<Map<String, dynamic>> groupedData, DataManager dataManager) {
      const int maxPoints = 1000;
      final appState = Provider.of<AppState>(context);

      List<Map<String, dynamic>> limitedData = groupedData.length > maxPoints ? groupedData.sublist(0, maxPoints) : groupedData;

      List<Map<String, dynamic>> convertedData = limitedData.map((entry) {
        double convertedRent = dataManager.convert(entry['rent'] ?? 0.0);
        return {
          'date': entry['date'],
          'rent': convertedRent,
          'cumulativeRent': entry['cumulativeRent'] ?? 0.0,
        };
      }).toList();

      // Trier les données par date croissante
      convertedData.sort((a, b) => a['date'].compareTo(b['date']));

      return Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _showCumulativeRent ? S.of(context).cumulativeRentGraph : S.of(context).groupedRentGraph,
                    style: TextStyle(
                      fontSize: 20 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Transform.scale(
                    scale: 0.8, // Réduit la taille à 80% de la taille originale
                    child: Switch(
                      value: _showCumulativeRent,
                      onChanged: (value) {
                        setState(() {
                          _showCumulativeRent = value;
                        });
                      },
                      activeColor: Colors.blue, // Couleur d'accentuation en mode activé
                      inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                    ),
                  )
                ],
              ),
                _buildPeriodSelector(
            selectedPeriod: _selectedRentPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedRentPeriod = period;
              });
            },
          ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            // Calcul de la valeur la plus élevée dans les données
                            final highestValue = convertedData.map((entry) => entry['rent']).reduce((a, b) => a > b ? a : b);

                            // Si la valeur est la plus haute, on ne l'affiche pas
                            if (value == highestValue) {
                              return const SizedBox.shrink();
                            }

                            // Vérifier si la valeur dépasse 1000 et formater en "1.0k" si nécessaire
                            final displayValue = value >= 1000
                                ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}' // Formater en "1.0k"
                                : '${value.toStringAsFixed(0)}${dataManager.currencySymbol}'; // Limiter à 1 chiffre après la virgule

                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                displayValue,
                                style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calculateBottomInterval(convertedData),
                          getTitlesWidget: (value, meta) {
                            List<String> labels = _buildDateLabels(convertedData);
                            if (value.toInt() >= 0 && value.toInt() < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0), // Décalage vers le bas
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                  ),
                                ),
                              );
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true, // Affiche les bordures
                      border: Border(
                        left: BorderSide(color: Colors.transparent), // Axe gauche
                        bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5), // Axe bas
                        right: BorderSide(color: Colors.transparent), // Masque l'axe droit
                        top: BorderSide(color: Colors.transparent), // Masque l'axe supérieur
                      ),
                    ),
                    minX: 0,
                    maxX: (convertedData.length - 1).toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _showCumulativeRent ? _buildCumulativeChartData(convertedData) : _buildChartData(convertedData),
                        isCurved: false,
                        barWidth: 2,
                        color: _showCumulativeRent ? Colors.green : Colors.blue,
                        dotData: FlDotData(show: false), // Cache les points par défaut
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0.4),
                              (_showCumulativeRent ? Colors.green : Colors.blue).withOpacity(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipMargin: 8,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          if (touchedSpots.isEmpty) {
                            return [];
                          }
                          return touchedSpots.map((touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            final rent = convertedData[index]['rent'];
                            final date = convertedData[index]['date']; // Utiliser directement la date

                            // Combine la date et la valeur dans le tooltip
                            return LineTooltipItem(
                              '$date\n${Utils.formatCurrency(rent, dataManager.currencySymbol)}', // Date + Valeur
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildWalletBalanceCard(DataManager dataManager) {
  final appState = Provider.of<AppState>(context);

  // Récupérer les données pour les graphiques
  List<FlSpot> walletBalanceData = _buildWalletBalanceChartData(dataManager, _selectedWalletPeriod);
  List<BarChartGroupData> barChartData = _buildWalletBalanceBarChartData(dataManager, _selectedWalletPeriod);

  return Card(
    elevation: 0,
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.of(context).walletBalanceHistory, // Titre principal
                style: TextStyle(
                  fontSize: 20 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  size: 20.0,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.bar_chart, color: Colors.blue),
                              title: Text(S.of(context).barChart),
                              onTap: () {
                                setState(() {
                                  walletIsBarChart = true;
                                  _saveChartPreference('walletIsBarChart', walletIsBarChart);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.show_chart, color: Colors.green),
                              title: Text(S.of(context).lineChart),
                              onTap: () {
                                setState(() {
                                  walletIsBarChart = false;
                                  _saveChartPreference('walletIsBarChart', walletIsBarChart);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.edit, color: Colors.orange),
                              title: Text(S.of(context).edit),
                              onTap: () {
                                Navigator.of(context).pop();
                                _showEditModal(context, dataManager);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
  _buildPeriodSelector(
            selectedPeriod: _selectedWalletPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedWalletPeriod = period;
              });
            },
          ),          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: StatefulBuilder(
              builder: (context, setState) {
                return walletIsBarChart
                    ? BarChart(
                        BarChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  final displayValue = value >= 1000
                                      ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}'
                                      : Utils.formatCurrency(value, dataManager.currencySymbol);
                                  return Text(
                                    displayValue,
                                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  List<String> labels = _buildDateLabelsForWallet(dataManager, _selectedWalletPeriod);
                                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.transparent),
                              bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                              right: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          barGroups: barChartData,
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  final displayValue = value >= 1000
                                      ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}'
                                      : Utils.formatCurrency(value, dataManager.currencySymbol);
                                  return Text(
                                    displayValue,
                                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  List<String> labels = _buildDateLabelsForWallet(dataManager, _selectedWalletPeriod);
                                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.transparent),
                              bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                              right: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: walletBalanceData,
                              isCurved: false,
                              barWidth: 2,
                              color: Colors.purple,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.4),
                                    Colors.purple.withOpacity(0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipItems: (List<LineBarSpot> touchedSpots) {
      return touchedSpots.map((touchedSpot) {
        final index = touchedSpot.x.toInt();
        final averageBalance = touchedSpot.y;
        final periodLabel = _buildDateLabelsForWallet(dataManager, _selectedWalletPeriod)[index];

        return LineTooltipItem(
          '$periodLabel\n${Utils.formatCurrency(averageBalance, dataManager.currencySymbol)}',
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      }).toList();
    },
  ),
),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

List<BarChartGroupData> _buildWalletBalanceBarChartData(DataManager dataManager, String selectedPeriod) {
  List<FlSpot> walletBalanceData = _buildWalletBalanceChartData(dataManager, selectedPeriod);
  return walletBalanceData
      .asMap()
      .entries
      .map(
        (entry) => BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.y,
              color: Colors.purple,
              width: 8,
            ),
          ],
        ),
      )
      .toList();
}
    
   Widget _buildRoiHistoryCard(DataManager dataManager) {
  final appState = Provider.of<AppState>(context);

  // Récupérer les données pour les graphiques
  List<FlSpot> roiHistoryData = _buildRoiHistoryChartData(dataManager, _selectedRoiPeriod);
  List<BarChartGroupData> barChartData = _buildRoiHistoryBarChartData(dataManager, _selectedRoiPeriod);

  return Card(
    elevation: 0,
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.of(context).roiHistory, // Titre principal
                style: TextStyle(
                  fontSize: 20 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, size: 20.0),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.bar_chart, color: Colors.blue),
                              title: Text(S.of(context).barChart),
                              onTap: () {
                                setState(() {
                                  roiIsBarChart = true;
                                  _saveChartPreference('roiIsBarChart', roiIsBarChart);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.show_chart, color: Colors.green),
                              title: Text(S.of(context).lineChart),
                              onTap: () {
                                setState(() {
                                  roiIsBarChart = false;
                                  _saveChartPreference('roiIsBarChart', roiIsBarChart);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          _buildPeriodSelector(
            selectedPeriod: _selectedRoiPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedRoiPeriod = period;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: StatefulBuilder(
              builder: (context, setState) {
                return roiIsBarChart
                    ? BarChart(
                        BarChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  List<String> labels = _buildDateLabelsForRoi(dataManager, _selectedRoiPeriod);
                                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.transparent),
                              bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                              right: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          barGroups: barChartData,
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  final highestValue = roiHistoryData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

                                  if (value == highestValue) {
                                    return const SizedBox.shrink();
                                  }

                                  return Transform.rotate(
                                    angle: -0.5,
                                    child: Text(
                                      '${value.toStringAsFixed(0)}%',
                                      style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  List<String> labels = _buildDateLabelsForRoi(dataManager, _selectedRoiPeriod);

                                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                                reservedSize: 30,
                                interval: 1,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.transparent),
                              bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                              right: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          minX: 0,
                          maxX: (roiHistoryData.length - 1).toDouble(),
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: roiHistoryData,
                              isCurved: false,
                              barWidth: 2,
                              color: Colors.cyan,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyan.withOpacity(0.4),
                                    Colors.cyan.withOpacity(0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 8,
                              tooltipMargin: 8,
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((touchedSpot) {
                                  final index = touchedSpot.x.toInt();
                                  final value = touchedSpot.y;
                                  final date = _buildDateLabelsForRoi(dataManager, _selectedRoiPeriod)[index];

                                  final formattedValue = '${value.toStringAsFixed(2)}%';

                                  return LineTooltipItem(
                                    '$date\n$formattedValue',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                }).toList();
                              },
                            ),
                            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                              if (touchResponse != null && touchResponse.lineBarSpots != null) {
                                debugPrint('Point touché : ${touchResponse.lineBarSpots?.first.x}');
                              }
                            },
                            handleBuiltInTouches: true,
                          ),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

    List<FlSpot> _buildRoiHistoryChartData(DataManager dataManager, String selectedPeriod) {
  List<RoiRecord> roiHistory = dataManager.roiHistory;

  // Grouper les données en fonction de la période sélectionnée
  Map<String, List<double>> groupedData = {};
  for (var record in roiHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }

    groupedData.putIfAbsent(periodKey, () => []).add(record.roi);
  }

  // Calculer la moyenne pour chaque période
  List<FlSpot> spots = [];
  List<String> sortedKeys = groupedData.keys.toList()..sort();

  for (int i = 0; i < sortedKeys.length; i++) {
    String periodKey = sortedKeys[i];
    List<double> rois = groupedData[periodKey]!;
    double averageRoi = rois.reduce((a, b) => a + b) / rois.length; // Calcul de la moyenne
    spots.add(FlSpot(i.toDouble(), averageRoi));
  }

  return spots;
}

    Widget _buildApyHistoryCard(DataManager dataManager) {
  final appState = Provider.of<AppState>(context);

  List<BarChartGroupData> apyHistoryData = _buildApyHistoryBarChartData(dataManager, _selectedApyPeriod);
  List<LineChartBarData> lineChartData = _buildApyHistoryLineChartData(dataManager, _selectedApyPeriod);

  int? selectedIndex; // Variable pour stocker l'index sélectionné

  return Card(
    elevation: 0,
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.of(context).apyHistory,
                style: TextStyle(
                  fontSize: 20 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, size: 20.0),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.bar_chart, color: Colors.blue),
                              title: Text(S.of(context).barChart),
                              onTap: () {
                                setState(() {
                                  apyIsBarChart = true;
                                  _saveChartPreference('apyIsBarChart', apyIsBarChart);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.show_chart, color: Colors.green),
                              title: Text(S.of(context).lineChart),
                              onTap: () {
                                setState(() {
                                  apyIsBarChart = false;
                                  _saveChartPreference('apyIsBarChart', apyIsBarChart);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          _buildPeriodSelector(
            selectedPeriod: _selectedApyPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedApyPeriod = period;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: StatefulBuilder(
              builder: (context, setState) {
                return apyIsBarChart
                    ? BarChart(
                        BarChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  List<String> labels = _buildDateLabelsForApy(dataManager, _selectedApyPeriod);
                                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Text('');
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.transparent),
                              bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                              right: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          alignment: BarChartAlignment.center,
                          barGroups: apyHistoryData,
                          maxY: 20,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                // Affiche uniquement le tooltip si l'index est sélectionné
                                if (selectedIndex == groupIndex) {
                                  String tooltip = '${S.of(context).brute}: ${group.barRods[0].rodStackItems[0].toY.toStringAsFixed(2)}%\n'
                                      '${S.of(context).net}: ${group.barRods[0].rodStackItems[1].toY.toStringAsFixed(2)}%';
                                  return BarTooltipItem(
                                    tooltip,
                                    const TextStyle(color: Colors.white),
                                  );
                                }
                                return null; // Aucun tooltip
                              },
                            ),
                            touchCallback: (FlTouchEvent event, barTouchResponse) {
                              // Met à jour l'index sélectionné en cas de clic
                              if (event is FlTapUpEvent && barTouchResponse != null) {
                                setState(() {
                                  selectedIndex = barTouchResponse.spot?.touchedBarGroupIndex;
                                });
                              } else if (event is FlLongPressEnd || event is FlPanEndEvent) {
                                // Désélectionne si l'utilisateur annule l'interaction
                                setState(() {
                                  selectedIndex = null;
                                });
                              }
                            },
                            handleBuiltInTouches: true,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  List<String> labels = _buildDateLabelsForApy(dataManager, _selectedApyPeriod);
                                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Text('');
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.transparent),
                              bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                              right: BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          lineBarsData: lineChartData,
                          minY: 0,
                          maxY: 20,
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

    List<LineChartBarData> _buildApyHistoryLineChartData(DataManager dataManager, String selectedPeriod) {
  final groupedData = _groupApyByDate(dataManager, selectedPeriod);

  final grossSpots = <FlSpot>[];
  final netSpots = <FlSpot>[];

  int index = 0;
  groupedData.forEach((date, values) {
    grossSpots.add(FlSpot(index.toDouble(), values['gross']!));
    netSpots.add(FlSpot(index.toDouble(), values['net']!));
    index++;
  });

  return [
    LineChartBarData(
      spots: grossSpots,
      isCurved: true,
      color: Colors.blue,
      barWidth: 2,
      belowBarData: BarAreaData(
        show: true,
        color: Colors.blue.withOpacity(0.1),
      ),
      dotData: FlDotData(show: false),
    ),
    LineChartBarData(
      spots: netSpots,
      isCurved: true,
      color: Colors.green,
      barWidth: 2,
      belowBarData: BarAreaData(
        show: true,
        color: Colors.green.withOpacity(0.1),
      ),
      dotData: FlDotData(show: false),
    ),
  ];
}

    List<BarChartGroupData> _buildApyHistoryBarChartData(DataManager dataManager, String selectedPeriod) {
  final groupedData = _groupApyByDate(dataManager, selectedPeriod);
  final barGroups = <BarChartGroupData>[];

  int index = 0;
  groupedData.forEach((date, values) {
    barGroups.add(
      BarChartGroupData(
        x: index,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: values['gross']!,
            width: 16,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
              bottomLeft: Radius.zero,
              bottomRight: Radius.zero,
            ),
            rodStackItems: [
              BarChartRodStackItem(0, values['gross']!, Colors.blue.withOpacity(0.8)),
              BarChartRodStackItem(0, values['net']!, Colors.green.withOpacity(0.8)),
            ],
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    );
    index++;
  });

  return barGroups;
}

    void _showEditModal(BuildContext context, DataManager dataManager) {
      final appState = Provider.of<AppState>(context, listen: false);
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (BuildContext context) {
          final screenHeight = MediaQuery.of(context).size.height;
          return Container(
            height: screenHeight * 0.7,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).editWalletBalance,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: dataManager.walletBalanceHistory.length,
                    itemBuilder: (context, index) {
                      BalanceRecord record = dataManager.walletBalanceHistory[index];
                      TextEditingController valueController = TextEditingController(text: record.balance.toString());
                      TextEditingController dateController = TextEditingController(
                        text: DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp),
                      );

                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Editable date field
                            Expanded(
                              child: TextField(
                                controller: dateController,
                                keyboardType: TextInputType.datetime,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(fontSize: 12 + appState.getTextSizeOffset()),
                                decoration: InputDecoration(
                                  labelText: S.of(context).date,
                                  labelStyle: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
                                ),
                                onSubmitted: (value) {
                                  try {
                                    DateTime newDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
                                    record.timestamp = newDate;
                                    dataManager.saveWalletBalanceHistory();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('invalidDateFormat')),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: valueController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                style: TextStyle(fontSize: 12 + appState.getTextSizeOffset()),
                                decoration: InputDecoration(
                                  labelText: S.of(context).balance,
                                  labelStyle: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
                                ),
                                onSubmitted: (value) {
                                  double? newValue = double.tryParse(value);
                                  if (newValue != null) {
                                    record.balance = newValue;
                                    dataManager.saveWalletBalanceHistory();
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 20,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  iconSize: 18 + appState.getTextSizeOffset(),
                                  onPressed: () {
                                    _deleteBalanceRecord(dataManager, index);
                                    Navigator.pop(context);
                                    _showEditModal(context, dataManager);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    dataManager.saveWalletBalanceHistory();
                    Navigator.pop(context);
                  },
                  child: Text(S.of(context).save),
                ),
              ],
            ),
          );
        },
      );
    }

    void _deleteBalanceRecord(DataManager dataManager, int index) {
      dataManager.walletBalanceHistory.removeAt(index);
      dataManager.saveWalletBalanceHistory(); // Sauvegarder la mise à jour dans Hive
      dataManager.notifyListeners();
    }

    List<FlSpot> _buildWalletBalanceChartData(DataManager dataManager, String selectedPeriod) {
  List<BalanceRecord> walletHistory = dataManager.walletBalanceHistory;

  // Grouper les données en fonction de la période sélectionnée
  Map<String, List<double>> groupedData = {};
  for (var record in walletHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }
    groupedData.putIfAbsent(periodKey, () => []).add(record.balance);
  }

  // Calculer la moyenne pour chaque période
  List<FlSpot> spots = [];
  List<String> sortedKeys = groupedData.keys.toList()..sort();

  for (int i = 0; i < sortedKeys.length; i++) {
    String periodKey = sortedKeys[i];
    List<double> balances = groupedData[periodKey]!;
    double averageBalance = balances.reduce((a, b) => a + b) / balances.length; // Calcul de la moyenne
    spots.add(FlSpot(i.toDouble(), averageBalance));
  }

  return spots;
}

  Map<String, Map<String, double>> _groupApyByDate(DataManager dataManager, String selectedPeriod) {
  Map<String, Map<String, double>> groupedData = {};

  for (var record in dataManager.apyHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }

    if (!groupedData.containsKey(periodKey)) {
      groupedData[periodKey] = {'gross': 0, 'net': 0};
    }

    groupedData[periodKey]!['gross'] = record.grossApy;
    groupedData[periodKey]!['net'] = record.netApy;
  }

  return groupedData;
}

   List<String> _buildDateLabelsForWallet(DataManager dataManager, String selectedPeriod) {
  List<BalanceRecord> walletHistory = dataManager.walletBalanceHistory;

  // Grouper les données en fonction de la période sélectionnée
  Map<String, List<double>> groupedData = {};
  for (var record in walletHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }

    groupedData.putIfAbsent(periodKey, () => []).add(record.balance);
  }

  // Trier les clés et les retourner
  List<String> sortedKeys = groupedData.keys.toList()..sort();
  return sortedKeys;
}

    List<String> _buildDateLabelsForRoi(DataManager dataManager, String selectedPeriod) {
  List<RoiRecord> roiHistory = dataManager.roiHistory;

  // Grouper les données en fonction de la période sélectionnée
  Map<String, List<double>> groupedData = {};
  for (var record in roiHistory) {
    DateTime date = record.timestamp;
    String periodKey;

    if (selectedPeriod == S.of(context).day) {
      periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
    } else if (selectedPeriod == S.of(context).week) {
      periodKey = "${date.year}-S${Utils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      periodKey = DateFormat('yyyy/MM').format(date);
    } else {
      periodKey = date.year.toString();
    }

    groupedData.putIfAbsent(periodKey, () => []).add(record.roi);
  }

  // Trier les clés et les retourner
  List<String> sortedKeys = groupedData.keys.toList()..sort();
  return sortedKeys;
}

    List<String> _buildDateLabelsForApy(DataManager dataManager, String selectedPeriod) {
  final groupedData = _groupApyByDate(dataManager, selectedPeriod);
  return groupedData.keys.toList();
}

  // Méthode pour calculer un intervalle optimisé pour l'axe des dates
    double _calculateBottomInterval(List<Map<String, dynamic>> data) {
      if (data.isEmpty) return 1;

      double interval = (data.length / 6).roundToDouble(); // Calculer l'intervalle

      // S'assurer que l'intervalle est au moins 1
      return interval > 0 ? interval : 1;
    }

Widget _buildPeriodSelector({
  required String selectedPeriod,
  required Function(String) onPeriodChanged,
}) {
  return Row(
    children: [
      _buildPeriodButton(
        period: S.of(context).day, // Ajouter le paramètre 'period'
        isSelected: selectedPeriod == S.of(context).day,
        isFirst: true,
        onTap: () => onPeriodChanged(S.of(context).day),
      ),
      _buildPeriodButton(
        period: S.of(context).week, // Ajouter le paramètre 'period'
        isSelected: selectedPeriod == S.of(context).week,
        onTap: () => onPeriodChanged(S.of(context).week),
      ),
      _buildPeriodButton(
        period: S.of(context).month, // Ajouter le paramètre 'period'
        isSelected: selectedPeriod == S.of(context).month,
        onTap: () => onPeriodChanged(S.of(context).month),
      ),
      _buildPeriodButton(
        period: S.of(context).year, // Ajouter le paramètre 'period'
        isSelected: selectedPeriod == S.of(context).year,
        isLast: true,
        onTap: () => onPeriodChanged(S.of(context).year),
      ),
    ],
  );
}

Widget _buildPeriodButton({
  required String period, // Paramètre nommé 'period'
  required bool isSelected,
  bool isFirst = false,
  bool isLast = false,
  required Function() onTap,
}) {
  final appState = Provider.of<AppState>(context);

  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Theme.of(context).secondaryHeaderColor,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(8) : Radius.zero,
            right: isLast ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 3),
        alignment: Alignment.center,
        child: Text(
          period, // Utilisation du paramètre 'period'
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}
    List<FlSpot> _buildCumulativeChartData(List<Map<String, dynamic>> data) {
      List<FlSpot> spots = [];
      double cumulativeRent = 0.0;

      for (var i = 0; i < data.length; i++) {
        cumulativeRent += data[i]['rent']?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), cumulativeRent));
      }
      return spots;
    }

    void _saveChartPreference(String key, bool value) {
      prefs.setBool(key, value);
    }
  }