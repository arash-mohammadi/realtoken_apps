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

  const RentsCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    return UIUtils.buildCard(
      S.of(context).rents,
      Icons.attach_money,
      Row(
        children: [
          UIUtils.buildValueBeforeText(context, '${dataManager.netGlobalApy.toStringAsFixed(2)}%' as String?, S.of(context).annualYield, dataManager.isLoadingMain),
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
          dataManager.isLoadingMain,
          context,
        ),
        const SizedBox(height: 10),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.dailyRent), dataManager.currencySymbol, showAmounts),
          S.of(context).daily,
          dataManager.isLoadingMain,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.weeklyRent), dataManager.currencySymbol, showAmounts),
          S.of(context).weekly,
          dataManager.isLoadingMain,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(
            dataManager.convert(dataManager.monthlyRent),
            dataManager.currencySymbol,
            showAmounts,
          ),
          S.of(context).monthly,
          dataManager.isLoadingMain,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.yearlyRent), dataManager.currencySymbol, showAmounts),
          S.of(context).annually,
          dataManager.isLoadingMain,
          context,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      rightWidget: _buildMiniGraphForRendement(_getLast12WeeksRent(dataManager), context, dataManager),
    );
  }

  Widget _buildMiniGraphForRendement(List<Map<String, dynamic>> data, BuildContext context, DataManager dataManager) {
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
            minY: data.map((e) => e['amount']).reduce((a, b) => a < b ? a : b),
            maxY: data.map((e) => e['amount']).reduce((a, b) => a > b ? a : b),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (index) {
                  double roundedValue = double.parse(dataManager.convert(data[index]['amount']).toStringAsFixed(2));
                  return FlSpot(index.toDouble(), roundedValue);
                }),
                isCurved: true,
                barWidth: 2,
                color: Theme.of(context).primaryColor,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 2,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.4),
                      Theme.of(context).primaryColor.withOpacity(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            // Ajout de LineTouchData pour le tooltip avec la semaine
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final index = touchedSpot.x.toInt();
                    final weekLabel = data[index]['week'];
                    final amount = touchedSpot.y.toStringAsFixed(2);

                    return LineTooltipItem(
                      '$weekLabel\n$amount ${dataManager.currencySymbol}',
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

  List<Map<String, dynamic>> _getLast12WeeksRent(DataManager dataManager) {
    final currentDate = DateTime.now();
    final rentData = dataManager.rentData;

    DateTime currentMonday = currentDate.subtract(Duration(days: currentDate.weekday - 1));

    Map<String, double> weeklyRent = {};

    for (var rentEntry in rentData) {
      DateTime date = DateTime.parse(rentEntry['date']);

      DateTime mondayOfWeek = date.subtract(Duration(days: date.weekday - 1));

      String weekKey = DateFormat('yyyy-MM-dd').format(mondayOfWeek);

      if (mondayOfWeek.isBefore(currentMonday)) {
        weeklyRent[weekKey] = (weeklyRent[weekKey] ?? 0) + rentEntry['rent'];
      }
    }

    List<Map<String, dynamic>> last12WeeksData = List.generate(12, (index) {
      DateTime pastMonday = currentMonday.subtract(Duration(days: (index + 1) * 7));
      String weekLabel = DateFormat('dd MMM yyyy').format(pastMonday);

      return {'week': weekLabel, 'amount': weeklyRent[DateFormat('yyyy-MM-dd').format(pastMonday)] ?? 0};
    }).reversed.toList();

    return last12WeeksData;
  }
}
