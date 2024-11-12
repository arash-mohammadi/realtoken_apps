import 'package:realtokens_apps/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realtokens_apps/api/data_manager.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:realtokens_apps/app_state.dart'; // Import AppState

class RmmStats extends StatefulWidget {
  const RmmStats({super.key});

  @override
  RmmStatsState createState() => RmmStatsState();
}

class RmmStatsState extends State<RmmStats> {
  String selectedPeriod = 'hour'; // Par défaut, afficher par heure

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double fixedCardHeight = 380; // Hauteur fixe pour toutes les cartes

    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Carte APY en pleine largeur en haut
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildApyCard(dataManager, screenWidth),
            ),
          ),

          // Grille des autres cartes
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 80),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 700 ? 2 : 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: fixedCardHeight, // Hauteur fixe pour chaque carte
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  switch (index) {
                    case 0:
                      return _buildDepositBalanceCard(dataManager, 380);
                    case 1:
                      return _buildBorrowBalanceCard(dataManager, 380);
                    default:
                      return Container();
                  }
                },
                childCount: 2, // Nombre total de cartes dans la grille
              ),
            ),
          ),
        ],
      ),
    );
  }

// Fonction pour créer la carte APY en pleine largeur
  Widget _buildApyCard(DataManager dataManager, double screenWidth) {
    final double cardHeight = screenWidth > 700 ? 200 : 200;

    return SizedBox(
      height: cardHeight,
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Explication APY Moyen'),
                            content: const Text(
                              'L’APY moyen est calculé en moyenne sur les variations de balance entre plusieurs paires de données. '
                              'Les valeurs avec des variations anormales (dépôts ou retraits) sont écartées.',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          '${S.of(context).averageApy} ${dataManager.apyAverage.toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildApyTable(dataManager),
            ],
          ),
        ),
      ),
    );
  }

// Fonction pour créer la carte de dépôt (Deposit Balance Card)
  Widget _buildDepositBalanceCard(DataManager dataManager, double screenHeight) {
    return SizedBox(
      height: screenHeight,
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).depositBalance,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                  future: _fetchAndAggregateBalanceHistories(dataManager),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Pas de données disponibles.');
                    } else {
                      final allHistories = snapshot.data!;
                      return LineChart(_buildDepositChart(allHistories));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Fonction pour créer la carte d'emprunt (Borrow Balance Card)
  Widget _buildBorrowBalanceCard(DataManager dataManager, double screenHeight) {
    return SizedBox(
      height: screenHeight,
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).borrowBalance,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                  future: _fetchAndAggregateBalanceHistories(dataManager),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Pas de données disponibles.');
                    } else {
                      final allHistories = snapshot.data!;
                      return LineChart(_buildBorrowChart(allHistories));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Fonction pour créer le tableau APY (peut être personnalisée selon les données à afficher)
  Widget _buildApyTable(DataManager dataManager) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(
                  color: Colors.black.withOpacity(0.3), // Couleur du fond grisé
          width: 1,
        ),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(''),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Image.asset('assets/icons/usdc.png', width: 24, height: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Image.asset('assets/icons/xdai.png', width: 24, height: 24),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.usdcDepositApy.toStringAsFixed(2)}%'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.xdaiDepositApy.toStringAsFixed(2)}%'),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Borrow', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.usdcBorrowApy.toStringAsFixed(2)}%'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.xdaiBorrowApy.toStringAsFixed(2)}%'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Fonction pour créer le graphique des dépôts (Deposits)
  LineChartData _buildDepositChart(Map<String, List<BalanceRecord>> allHistories) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    final maxY = _getMaxY(allHistories, ['usdcDeposit', 'xdaiDeposit']);
    final maxX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a > b ? a : b);
    final minX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a < b ? a : b);

    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Transform.rotate(
                angle: -0.5,
                child: Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              // Déterminer la valeur la plus élevée dans les données de l'axe Y
              if (value == maxY) {
                return const SizedBox.shrink(); // Ne pas afficher la valeur la plus élevée
              }

              // Formater la valeur en "k" si elle est supérieure ou égale à 1000
              final displayValue = value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}'
                  : '${value.toStringAsFixed(2)}${dataManager.currencySymbol}';

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
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: minX,
      maxX: maxX,
      minY: 0, // Laisser un peu d'espace en bas
      maxY: maxY, // Ajouter une marge en haut
      lineBarsData: [
        _buildLineBarData(allHistories['usdcDeposit']!, Colors.blue, "USDC Deposit"),
        _buildLineBarData(allHistories['xdaiDeposit']!, Colors.green, "xDai Deposit"),
      ],
    );
  }

  // Fonction pour créer le graphique des emprunts (Borrows)
  LineChartData _buildBorrowChart(Map<String, List<BalanceRecord>> allHistories) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    final maxY = _getMaxY(allHistories, ['usdcBorrow', 'xdaiBorrow']);
    final maxX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a > b ? a : b);
    final minX = allHistories.values.expand((e) => e).map((e) => e.timestamp.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a < b ? a : b);

    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Transform.rotate(
                angle: -0.5,
                child: Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              // Déterminer la valeur la plus élevée dans les données de l'axe Y
              if (value == maxY) {
                return const SizedBox.shrink(); // Ne pas afficher la valeur la plus élevée
              }

              // Formater la valeur en "k" si elle est supérieure ou égale à 1000
              final displayValue = value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}'
                  : '${value.toStringAsFixed(2)}${dataManager.currencySymbol}';

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
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: minX,
      maxX: maxX,
      minY: 0, // Laisser un peu d'espace en bas
      maxY: maxY, // Ajouter une marge en haut
      lineBarsData: [
        _buildLineBarData(allHistories['usdcBorrow']!, Colors.orange, "USDC Borrow"),
        _buildLineBarData(allHistories['xdaiBorrow']!, Colors.red, "xDai Borrow"),
      ],
    );
  }

  // Fonction pour calculer un intervalle adapté à l'axe vertical gauche
  double _getMaxY(Map<String, List<BalanceRecord>> allHistories, List<String> types) {
    double maxY = types.expand((type) => allHistories[type] ?? []).map((record) => record.balance).reduce((a, b) => a > b ? a : b);
    return maxY > 0 ? maxY * 1.2 : 10; // Ajouter 20% de marge ou fixer une valeur par défaut si tout est à 0
  }

  // Fonction pour créer une ligne pour un type de token spécifique
  LineChartBarData _buildLineBarData(List<BalanceRecord> history, Color color, String label) {
    return LineChartBarData(
      spots: history
          .map((record) => FlSpot(
                record.timestamp.millisecondsSinceEpoch.toDouble(),
                double.parse(record.balance.toStringAsFixed(2)), // Limiter à 2 décimales
              ))
          .toList(),
      isCurved: true,
      dotData: FlDotData(show: false), // Afficher les points sur chaque valeur
      barWidth: 2,
      isStrokeCapRound: true,
      color: color,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // Fonction pour récupérer et agréger les historiques des balances pour tous les types de tokens
  Future<Map<String, List<BalanceRecord>>> _fetchAndAggregateBalanceHistories(DataManager dataManager) async {
    Map<String, List<BalanceRecord>> allHistories = {};

    allHistories['usdcDeposit'] = await dataManager.getBalanceHistory('usdcDeposit');
    allHistories['usdcBorrow'] = await dataManager.getBalanceHistory('usdcBorrow');
    allHistories['xdaiDeposit'] = await dataManager.getBalanceHistory('xdaiDeposit');
    allHistories['xdaiBorrow'] = await dataManager.getBalanceHistory('xdaiBorrow');

    for (String tokenType in allHistories.keys) {
      allHistories[tokenType] = await _aggregateByPeriod(allHistories[tokenType]!, selectedPeriod);
    }

    return allHistories;
  }

  // Fonction pour regrouper les données par période (heure, jour, semaine) et calculer la moyenne
  Future<List<BalanceRecord>> _aggregateByPeriod(List<BalanceRecord> records, String period) async {
    Map<DateTime, List<double>> groupedByPeriod = {};

    for (var record in records) {
      DateTime truncatedToPeriod;

      switch (period) {
        case 'hour':
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
            record.timestamp.hour,
          );
          break;
        case 'day':
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
          );
          break;
        case 'week':
          final date = record.timestamp;
          final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
          truncatedToPeriod = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          break;
        default:
          truncatedToPeriod = DateTime(
            record.timestamp.year,
            record.timestamp.month,
            record.timestamp.day,
            record.timestamp.hour,
          );
      }

      if (!groupedByPeriod.containsKey(truncatedToPeriod)) {
        groupedByPeriod[truncatedToPeriod] = [];
      }
      groupedByPeriod[truncatedToPeriod]!.add(record.balance);
    }

    List<BalanceRecord> averagedRecords = [];
    groupedByPeriod.forEach((timestamp, balances) {
      double averageBalance = balances.reduce((a, b) => a + b) / balances.length;
      averagedRecords.add(BalanceRecord(
        tokenType: records.first.tokenType,
        balance: averageBalance,
        timestamp: timestamp,
      ));
    });

    return averagedRecords;
  }
}
