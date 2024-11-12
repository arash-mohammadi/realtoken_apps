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

  @override
  void initState() {
    super.initState();
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
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0, right: 16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 2 : 1,
               
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
                      return _buildTokenDistributionCard(dataManager!);
                    case 3:
                      return _buildTokenDistributionByCountryCard(dataManager!);
                    case 4:
                      return _buildTokenDistributionByRegionCard(dataManager!);
                    case 5:
                      return _buildTokenDistributionByCityCard(dataManager!);
                    default:
                      return Container();
                  }
                },
                childCount: 6, // Total number of chart widgets
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
            _buildPeriodSelector(),
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
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                labels[value.toInt()],
                                style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                              ),
                            );
                          } else {
                            return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
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
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final value = touchedSpot.y;
                          return LineTooltipItem(
                            '${Utils.formatCurrency(dataManager.convert(value), dataManager.currencySymbol)} ', // Formater avec 2 chiffres après la virgule
                            const TextStyle(color: Colors.white),
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

    // Récupérer les données de l'historique des balances du wallet
    List<FlSpot> walletBalanceData = _buildWalletBalanceChartData(dataManager);

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
                  S.of(context).walletBalanceHistory, // Clé de traduction pour "Historique du Wallet"
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit),
                  iconSize: 16.0, // Réduisez la taille ici
                  onPressed: () => _showEditModal(context, dataManager),
                  tooltip: S.of(context).edit, // Clé de traduction pour "Éditer"
                ),
              ],
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
                          // Remplacez `highestValue` par la valeur maximale que vous souhaitez ignorer
                          final highestValue = walletBalanceData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

                          // Vérifier si la valeur est la plus haute pour l'ignorer
                          if (value == highestValue) {
                            return const SizedBox.shrink();
                          }

                          // Vérifier si la valeur dépasse 1000 et formater en "1k$" si nécessaire
                          final displayValue = value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}' // Formater en "1.0k"
                              : Utils.formatCurrency(value, dataManager.currencySymbol);

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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateBottomInterval(walletBalanceData.cast<Map<String, dynamic>>()),
                        getTitlesWidget: (value, meta) {
                          List<String> labels = _buildDateLabelsForWallet(dataManager);
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                labels[value.toInt()],
                                style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                              ),
                            );
                          } else {
                            return const Text('');
                          }
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (walletBalanceData.length - 1).toDouble(),
                  minY: 0, // Définit la valeur minimale de l'axe de gauche à 0
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
                          final value = touchedSpot.y;
                          return LineTooltipItem(
                            Utils.formatCurrency(dataManager.convert(value), dataManager.currencySymbol),
                            const TextStyle(color: Colors.white),
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

  List<FlSpot> _buildWalletBalanceChartData(DataManager dataManager) {
    List<FlSpot> spots = [];
    List<BalanceRecord> walletHistory = dataManager.walletBalanceHistory;

    for (var i = 0; i < walletHistory.length; i++) {
      double balanceValue = walletHistory[i].balance;
      spots.add(FlSpot(i.toDouble(), balanceValue));
    }
    return spots;
  }

  List<String> _buildDateLabelsForWallet(DataManager dataManager) {
    return dataManager.walletBalanceHistory.map((record) => DateFormat('yy-MM-dd').format(record.timestamp)).toList();
  }

// Méthode pour calculer un intervalle optimisé pour l'axe des dates
  double _calculateBottomInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;

    double interval = (data.length / 6).roundToDouble(); // Calculer l'intervalle

    // S'assurer que l'intervalle est au moins 1
    return interval > 0 ? interval : 1;
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

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton(S.of(context).week, isFirst: true),
        _buildPeriodButton(S.of(context).month),
        _buildPeriodButton(S.of(context).year, isLast: true),
      ],
    );
  }

  Widget _buildPeriodButton(String period, {bool isFirst = false, bool isLast = false}) {
    bool isSelected = _selectedPeriod == period;
    final appState = Provider.of<AppState>(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          child: Text(
            period,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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

    return Wrap(
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
    );
  }

  Widget _buildLegendByCountry(DataManager dataManager) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    // Compter les occurrences par pays
    for (var token in dataManager.portfolio) {
      String country = token['country'];
      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    // Utiliser le même tri que pour le graphique
    final sortedCountries = countryCount.keys.toList()..sort();

    return Wrap(
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
    );
  }

  Widget _buildLegendByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String regionCode = token['regionCode'];
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

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: legendItems,
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

  List<FlSpot> _buildCumulativeChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> spots = [];
    double cumulativeRent = 0.0;

    for (var i = 0; i < data.length; i++) {
      cumulativeRent += data[i]['rent']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), cumulativeRent));
    }
    return spots;
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
      final color = generateColor(sortedRegions.indexOf(region));

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
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
      final color = generateColor(sortedCities.indexOf(city)); // Appliquer la couleur générée

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
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
