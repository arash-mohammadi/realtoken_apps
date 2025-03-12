import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/pages/Statistics/wallet/charts/rent_graph.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:share_plus/share_plus.dart';

class DashboardRentsDetailsPage extends StatefulWidget {
  const DashboardRentsDetailsPage({super.key});

  @override
  _DashboardRentsDetailsPageState createState() =>
      _DashboardRentsDetailsPageState();
}

class _DashboardRentsDetailsPageState extends State<DashboardRentsDetailsPage> {
  bool _isGraphVisible = true;

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rents Details'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/excel.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              // Assurez-vous d'avoir bien les méthodes _generateCSV et _getFormattedToday
              if (dataManager.rentData.isNotEmpty) {
                final csvData =
                    _generateCSV(dataManager.rentData, currencyUtils);
                final fileName = 'rents_${_getFormattedToday()}.csv';
                final directory = await getTemporaryDirectory();
                final filePath = '${directory.path}/$fileName';
                final file = File(filePath);
                await file.writeAsString(csvData);
                await Share.shareXFiles(
                  [XFile(filePath)],
                  sharePositionOrigin: Rect.fromCenter(
                    center: MediaQuery.of(context).size.center(Offset.zero),
                    width: 100,
                    height: 100,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Aucune donnée de loyer à partager.')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: dataManager.rentData.isEmpty
            ? Center(
                child: Text(
                  'No rent data available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification) {
                    setState(() {
                      _isGraphVisible = scrollNotification.metrics.pixels < 50;
                    });
                  }
                  return true;
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Graphique rétractable
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isGraphVisible ? 380 : 0,
                      child: _isGraphVisible
                          ? RentGraph(
                              groupedData: _groupByMonth(dataManager.rentData),
                              dataManager: dataManager,
                              showCumulativeRent: false,
                              selectedPeriod: S.of(context).month,
                              onPeriodChanged: (period) {},
                              onCumulativeRentChanged: (value) {},
                            )
                          : null,
                    ),

                    const SizedBox(height: 5),

                    // TITRE FIXE
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            'Montant',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // LISTE SCROLLABLE
                    Expanded(
                      child: ListView.builder(
                        itemCount: dataManager.rentData.length,
                        shrinkWrap:
                            true, // Supprime la nécessité d'un ScrollView externe
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Permet de scroller normalement
                        itemBuilder: (context, index) {
                          final rentEntry = dataManager.rentData[index];
                          final rentDate =
                              CustomDateUtils.formatDate(rentEntry['date']);
                          final rentAmount = currencyUtils.formatCurrency(
                            currencyUtils.convert(rentEntry['rent']),
                            currencyUtils.currencySymbol,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rentDate,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  rentAmount,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Formate la date du jour pour le nom du fichier (ex: 20250222)
  String _getFormattedToday() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(now);
  }

// Génère une chaîne CSV à partir des données de loyer
  String _generateCSV(List<dynamic> rentData, CurrencyProvider currencyUtils) {
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Date,Montant');
    for (var rentEntry in rentData) {
      final String rentDate = CustomDateUtils.formatDate(rentEntry['date']);
      final String rentAmount = currencyUtils.formatCurrency(
        currencyUtils.convert(rentEntry['rent']),
        currencyUtils.currencySymbol,
      );
      csvBuffer.writeln('$rentDate,$rentAmount');
    }
    return csvBuffer.toString();
  }

  List<Map<String, dynamic>> _groupByMonth(List<dynamic> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String monthKey = DateFormat('yyyy/MM').format(date);
      groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
    }
    List<Map<String, dynamic>> list = groupedData.entries
        .map((e) => {'date': e.key, 'rent': e.value})
        .toList();
    list.sort((a, b) => DateFormat('yyyy/MM')
        .parse(a['date'])
        .compareTo(DateFormat('yyyy/MM').parse(b['date'])));
    return list;
  }
}
