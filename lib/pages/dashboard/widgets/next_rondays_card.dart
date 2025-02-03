import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';

class NextRondaysCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const NextRondaysCard(
      {super.key, required this.showAmounts, required this.isLoading});

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
    );
    
    }

  Widget _buildCumulativeRentList(BuildContext context, dataManager) {
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
  children: futureRentEvolution.map<Widget>((entry) {  // <Widget> ici est important
        DateTime rentStartDate = entry['rentStartDate'];

        // Vérifier si la date est déjà dans le Set
        if (displayedDates.contains(rentStartDate)) {
          return SizedBox.shrink(); // Ne rien afficher si la date est déjà affichée
        } else {
          // Ajouter la date au Set
          displayedDates.add(rentStartDate);

          // Vérifier si la date est "3000-01-01" et afficher 'date non connu'
          String displayDate = rentStartDate == DateTime(3000, 1, 1) ? 'Date non communiquée' : DateFormat('yyyy-MM-dd').format(rentStartDate);

          // Afficher la date et le loyer cumulé
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(
              '$displayDate: ${CurrencyUtils.getFormattedAmount(dataManager.convert(entry['cumulativeRent']), dataManager.currencySymbol, showAmounts)}',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          );
        }
  }).toList().cast<Widget>(),  // <== Ajoutez .cast<Widget>() ici
    );
  }}
