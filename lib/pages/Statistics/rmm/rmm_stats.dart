import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/archive_manager.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/pages/Statistics/rmm/borrow_chart.dart';
import 'package:realtokens/pages/Statistics/rmm/deposit_chart.dart';
import 'package:realtokens/pages/Statistics/rmm/healthFactorLtv_graph.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RmmStats extends StatefulWidget {
  const RmmStats({super.key});

  @override
  RmmStatsState createState() => RmmStatsState();
}

class RmmStatsState extends State<RmmStats> {
  String selectedDepositPeriod = '';
  String selectedBorrowPeriod = '';
  String selectedHealthAndLtvPeriod = '';
  late String _selectedHealthAndLtvPeriod;
  final ArchiveManager _archiveManager = ArchiveManager();
  final DataManager _dataManager = DataManager();

  late SharedPreferences prefs;

  bool healthAndLtvIsBarChart = true;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      // Charger la préférence stockée, si elle existe, sinon utiliser true par défaut
      healthAndLtvIsBarChart = prefs.getBool('healthAndLtvIsBarChart') ?? true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedDepositPeriod.isEmpty) {
      selectedDepositPeriod = S.of(context).week;
    }
    if (selectedBorrowPeriod.isEmpty) {
      selectedBorrowPeriod = S.of(context).week;
    }
    if (selectedHealthAndLtvPeriod.isEmpty) {
      selectedHealthAndLtvPeriod = S.of(context).week;
    }

    _selectedHealthAndLtvPeriod = S.of(context).week;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const double fixedCardHeight = 380;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildApyCard(dataManager, 380),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 80),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 700 ? 2 : 1,
                mainAxisExtent: fixedCardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  switch (index) {
                    case 0:
                      return _buildDepositBalanceCard(dataManager, 380);
                    case 1:
                      return _buildBorrowBalanceCard(dataManager, 380);
                    case 2:
                      return _buildHealthAndLtvHistoryCard(dataManager);

                    default:
                      return Container();
                  }
                },
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAndLtvHistoryCard(DataManager dataManager) {
    return SizedBox(
      height: 380,
      child: HealthAndLtvHistoryGraph(
        dataManager: dataManager,
        selectedPeriod: selectedHealthAndLtvPeriod,
        healthAndLtvIsBarChart: healthAndLtvIsBarChart,
        onPeriodChanged: (newPeriod) {
          setState(() {
            selectedHealthAndLtvPeriod = newPeriod;
          });
        },
        onChartTypeChanged: (isBarChart) {
          setState(() {
            healthAndLtvIsBarChart = isBarChart;
            prefs.setBool('healthAndLtvIsBarChart', isBarChart);
          });
        },
      ),
    );
  }

  Widget _buildApyCard(DataManager dataManager, double screenWidth) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Card(
        elevation: 0.5,
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
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Explication APY Moyen'),
                            content: const Text(
                              'L\'APY moyen est calculé en moyenne sur les variations de balance entre plusieurs paires de données. '
                              'Les valeurs avec des variations anormales (dépôts ou retraits) sont écartées.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
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
                          '${S.of(context).averageApy} ${dataManager.apyAverage.isNaN ? "0.00" : dataManager.apyAverage.toStringAsFixed(2)}%',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.info_outline,
                            size: 20, color: Colors.blue),
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

  Widget _buildApyTable(DataManager dataManager) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.black.withOpacity(0.3),
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
                child:
                    Image.asset('assets/icons/usdc.png', width: 22, height: 22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child:
                    Image.asset('assets/icons/xdai.png', width: 22, height: 22),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Deposit',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.usdcDepositApy.toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.blue)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.xdaiDepositApy.toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.green)),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Borrow', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.usdcBorrowApy.toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.orange)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${dataManager.xdaiBorrowApy.toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepositBalanceCard(DataManager dataManager, double cardHeight) {
    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 0.5,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).depositBalance,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ChartUtils.buildPeriodSelector(
                context,
                selectedPeriod: selectedDepositPeriod,
                onPeriodChanged: (newPeriod) {
                  setState(() {
                    selectedDepositPeriod = newPeriod;
                  });
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                  future: _fetchAndAggregateBalanceHistories(
                      dataManager, selectedDepositPeriod),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Pas de données disponibles.');
                    } else {
                      final allHistories = snapshot.data!;
                      return DepositChart(
                        allHistories: allHistories,
                        selectedPeriod: selectedDepositPeriod,
                      );
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

  Future<Map<String, List<BalanceRecord>>> _fetchAndAggregateBalanceHistories(
      DataManager dataManager, String selectedPeriod) async {
    Map<String, List<BalanceRecord>> allHistories = {};

    allHistories['usdcDeposit'] =
        await _archiveManager.getBalanceHistory('usdcDeposit');
    allHistories['usdcBorrow'] =
        await _archiveManager.getBalanceHistory('usdcBorrow');
    allHistories['xdaiDeposit'] =
        await _archiveManager.getBalanceHistory('xdaiDeposit');
    allHistories['xdaiBorrow'] =
        await _archiveManager.getBalanceHistory('xdaiBorrow');

    for (String tokenType in allHistories.keys) {
      allHistories[tokenType] =
          await _aggregateByPeriod(allHistories[tokenType]!, selectedPeriod);
    }

    return allHistories;
  }

  Future<List<BalanceRecord>> _aggregateByPeriod(
      List<BalanceRecord> records, String period) async {
    Map<DateTime, List<double>> groupedByPeriod = {};

    for (var record in records) {
      DateTime truncatedToPeriod;

      if (period == S.of(context).day) {
        truncatedToPeriod = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
      } else if (period == S.of(context).week) {
        final date = record.timestamp;
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        truncatedToPeriod = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
      } else if (period == S.of(context).month) {
        truncatedToPeriod = DateTime(
          record.timestamp.year,
          record.timestamp.month,
        );
      } else if (period == S.of(context).year) {
        truncatedToPeriod = DateTime(
          record.timestamp.year,
        );
      } else {
        // Valeur par défaut (ici on considère le jour)
        truncatedToPeriod = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
      }

      groupedByPeriod
          .putIfAbsent(truncatedToPeriod, () => [])
          .add(record.balance);
    }

    List<BalanceRecord> averagedRecords = [];
    groupedByPeriod.forEach((timestamp, balances) {
      double averageBalance =
          balances.reduce((a, b) => a + b) / balances.length;
      averagedRecords.add(BalanceRecord(
        tokenType: records.first.tokenType,
        balance: averageBalance,
        timestamp: timestamp,
      ));
    });

    return averagedRecords;
  }

  Widget _buildBorrowBalanceCard(DataManager dataManager, double cardHeight) {
    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 0.5,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).borrowBalance,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ChartUtils.buildPeriodSelector(
                context,
                selectedPeriod: selectedBorrowPeriod,
                onPeriodChanged: (newPeriod) {
                  setState(() {
                    selectedBorrowPeriod = newPeriod;
                  });
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                  future: _fetchAndAggregateBalanceHistories(
                      dataManager, selectedBorrowPeriod),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Pas de données disponibles.');
                    } else {
                      final allHistories = snapshot.data!;
                      return BorrowChart(
                        allHistories: allHistories,
                        selectedPeriod: selectedBorrowPeriod,
                      );
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

  void _saveChartPreference(String key, bool value) {
    prefs.setBool(key, value);
  }
}
