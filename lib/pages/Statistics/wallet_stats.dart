import 'package:flutter/services.dart';
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

class WalletStats extends StatefulWidget {
  const WalletStats({super.key});

  @override
  _WalletStats createState() => _WalletStats();
}

class _WalletStats extends State<WalletStats> {
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

 Widget _buildRoiHistoryCard(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    // Récupérer les données de l'historique des balances du wallet
    List<FlSpot> roiHistoryData = _buildRoiHistoryChartData(dataManager);

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
                          final highestValue = roiHistoryData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

                          // Vérifier si la valeur est la plus haute pour l'ignorer
                          if (value == highestValue) {
                            return const SizedBox.shrink();
                          }

                         
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              value as String,
                              style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateBottomInterval(roiHistoryData.cast<Map<String, dynamic>>()),
                        getTitlesWidget: (value, meta) {
                          List<String> labels = _buildDateLabelsForRoi(dataManager);
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
                  maxX: (roiHistoryData.length - 1).toDouble(),
                  minY: 0, // Définit la valeur minimale de l'axe de gauche à 0
                  lineBarsData: [
                    LineChartBarData(
                      spots: roiHistoryData,
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

  List<FlSpot> _buildRoiHistoryChartData(DataManager dataManager) {
    List<FlSpot> spots = [];
    List<RoiRecord> roiHistory = dataManager.roiHistory;

    for (var i = 0; i <roiHistory.length; i++) {
      double roiValue = roiHistory[i].roi;
      spots.add(FlSpot(i.toDouble(), roiValue));
    }
    return spots;
  }

  List<String> _buildDateLabelsForWallet(DataManager dataManager) {
    return dataManager.walletBalanceHistory.map((record) => DateFormat('yy-MM-dd').format(record.timestamp)).toList();
  }

  List<String> _buildDateLabelsForRoi(DataManager dataManager) {
    return dataManager.roiHistory.map((record) => DateFormat('yy-MM-dd').format(record.timestamp)).toList();
  }

// Méthode pour calculer un intervalle optimisé pour l'axe des dates
  double _calculateBottomInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;

    double interval = (data.length / 6).roundToDouble(); // Calculer l'intervalle

    // S'assurer que l'intervalle est au moins 1
    return interval > 0 ? interval : 1;
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

  List<FlSpot> _buildCumulativeChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> spots = [];
    double cumulativeRent = 0.0;

    for (var i = 0; i < data.length; i++) {
      cumulativeRent += data[i]['rent']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), cumulativeRent));
    }
    return spots;
  }



}
