import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class NextRondaysCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const NextRondaysCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return UIUtils.buildCard(
      S.of(context).nextRondays,
      Icons.trending_up,
      _buildCumulativeRentList(context, dataManager),
      [], // Pas d'autres enfants pour cette carte
      dataManager,
      context,
      hasGraph: true,
      rightWidget: _buildMiniGraphForNextRondays(dataManager, context),
    );
  }

  Widget _buildMiniGraphForNextRondays(DataManager dataManager, BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final cumulativeRentEvolution = dataManager.getCumulativeRentEvolution();
    DateTime today = DateTime.now();

    // Filtrer pour n'afficher que les dates futures
    final futureRentEvolution = cumulativeRentEvolution.where((entry) {
      DateTime rentStartDate = entry['rentStartDate'];
      return rentStartDate.isAfter(today);
    }).toList();

    // Utiliser un Set pour ne garder que des dates uniques
    Set<DateTime> displayedDates = <DateTime>{};
    List<Map<String, dynamic>> graphData = [];

    for (var entry in futureRentEvolution) {
      DateTime rentStartDate = entry['rentStartDate'];
      if (!displayedDates.contains(rentStartDate)) {
        displayedDates.add(rentStartDate);
        graphData.add({
          'date': DateFormat('dd MMM yyyy').format(rentStartDate),
          'amount': entry['cumulativeRent'],
        });
      }
    }

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 70,
        width: 120,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceBetween,
            maxY: graphData.map((e) => e['amount']).reduce((a, b) => a > b ? a : b),
            minY: graphData.map((e) => e['amount']).reduce((a, b) => a < b ? a : b) * 0.95,
            barGroups: List.generate(graphData.length, (index) {
              double roundedValue = double.parse(currencyUtils.convert(graphData[index]['amount']).toStringAsFixed(2));
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: roundedValue,
                    color: Theme.of(context).primaryColor,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dateLabel = graphData[groupIndex]['date'];
                  final amount = rod.toY.toStringAsFixed(2);
                  return BarTooltipItem(
                    '$dateLabel\n$amount ${currencyUtils.currencySymbol}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              handleBuiltInTouches: true,
              touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                if (response?.spot != null) {
                  // Le tooltip s'affichera uniquement sur la barre touchée
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCumulativeRentList(BuildContext context, dataManager) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final cumulativeRentEvolution = dataManager.getCumulativeRentEvolution();
    DateTime today = DateTime.now();
    final appState = Provider.of<AppState>(context);

    // Filtrer pour n'afficher que les dates futures
    final futureRentEvolution = cumulativeRentEvolution.where((entry) {
      DateTime rentStartDate = entry['rentStartDate'];
      return rentStartDate.isAfter(today);
    }).toList();

    // Utiliser un Set pour ne garder que des dates uniques
    Set<DateTime> displayedDates = <DateTime>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: futureRentEvolution
          .map<Widget>((entry) {
            DateTime rentStartDate = entry['rentStartDate'];

            if (displayedDates.contains(rentStartDate)) {
              return SizedBox.shrink();
            } else {
              displayedDates.add(rentStartDate);

              String displayDate = rentStartDate == DateTime(3000, 1, 1) ? 'Date non communiquée' : DateFormat('yyyy-MM-dd').format(rentStartDate);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Text(
                  '$displayDate: ${currencyUtils.getFormattedAmount(currencyUtils.convert(entry['cumulativeRent']), currencyUtils.currencySymbol, showAmounts)}',
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              );
            }
          })
          .toList()
          .cast<Widget>(),
    );
  }
}
