import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';

class RentsCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const RentsCard(
      {super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    return UIUtils.buildCard(
                      S.of(context).rents,
                      Icons.attach_money,
                      Row(
                        children: [
                          UIUtils.buildValueBeforeText(context, '${dataManager.netGlobalApy.toStringAsFixed(2)}%' as String?, S.of(context).annualYield, dataManager.isLoading),
                          SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(S.of(context).apy), // Titre de la popup
                                    content: Text(
                                      S.of(context).netApyHelp, // Contenu de la popup
                                      style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Fermer la popup
                                        },
                                        child: Text(S.of(context).close), // Bouton de fermeture
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Icon(Icons.info_outline, size: 15), // Icône sans padding implicite
                          ),
                          
                        ],
                      ),
                      [
                        UIUtils.buildTextWithShimmer(
                          '${dataManager.averageAnnualYield.toStringAsFixed(2)}%',
                          'APY brut: ',
                          dataManager.isLoading,
                          context,
                        ),
                        const SizedBox(height: 10),
                        UIUtils.buildTextWithShimmer(
                          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.dailyRent), dataManager.currencySymbol, showAmounts),
                          S.of(context).daily,
                          dataManager.isLoading,
                          context,
                        ),
                        UIUtils.buildTextWithShimmer(
                          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.weeklyRent), dataManager.currencySymbol, showAmounts),
                          S.of(context).weekly,
                          dataManager.isLoading,
                          context,
                        ),
                        UIUtils.buildTextWithShimmer(
                          CurrencyUtils.getFormattedAmount(
                            dataManager.convert(dataManager.monthlyRent),
                            dataManager.currencySymbol,
                            showAmounts,
                          ),
                          S.of(context).monthly,
                          dataManager.isLoading,
                          context,
                        ),
                        UIUtils.buildTextWithShimmer(
                          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.yearlyRent), dataManager.currencySymbol, showAmounts),
                          S.of(context).annually,
                          dataManager.isLoading,
                          context,
                        ),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: _buildMiniGraphForRendement(_getLast12MonthsRent(dataManager), context, dataManager),
                    
    );
    
    }

  Widget _buildMiniGraphForRendement(List<double> data, BuildContext context, DataManager dataManager) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 70,
        width: 120,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: data.length.toDouble() - 1,
            minY: data.reduce((a, b) => a < b ? a : b),
            maxY: data.reduce((a, b) => a > b ? a : b),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (index) {
                  double roundedValue = double.parse(dataManager.convert(data[index]).toStringAsFixed(2));
                  return FlSpot(index.toDouble(), roundedValue);
                }),
                isCurved: true,
                barWidth: 2,
                color: Colors.blue,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 2,
                    color: Colors.blue,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.4), // Couleur plus opaque en haut
                      Colors.blue.withOpacity(0), // Couleur plus transparente en bas
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            // Ajout de LineTouchData pour le tooltip
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final flSpot = touchedSpot;
                    return LineTooltipItem(
                      '${flSpot.y.toStringAsFixed(2)} ${dataManager.currencySymbol}', // Utiliser currencySymbol de dataManager
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }


List<double> _getLast12MonthsRent(DataManager dataManager) {
  final currentDate = DateTime.now();
  final rentData = dataManager.rentData;

  Map<String, double> monthlyRent = {};

  for (var rentEntry in rentData) {
    DateTime date = DateTime.parse(rentEntry['date']);
    // Exclure le mois en cours et ne garder que les données des 12 mois précédents
    if (date.isBefore(DateTime(currentDate.year, currentDate.month)) &&
        date.isAfter(DateTime(currentDate.year, currentDate.month - 12, 1))) {
      String monthKey = DateFormat('yyyy-MM').format(date);
      monthlyRent[monthKey] = (monthlyRent[monthKey] ?? 0) + rentEntry['rent'];
    }
  }

  // Convert the map values to a List<double> and return
  return monthlyRent.values.toList();
}


  }
