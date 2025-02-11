import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:shimmer/shimmer.dart';

class PortfolioCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;
  final BuildContext context; // Ajoutez le contexte ici

  const PortfolioCard({
    super.key,
    required this.showAmounts,
    required this.isLoading,
    required this.context, // Passez le contexte via le constructeur
  });

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return UIUtils.buildCard(
      S.of(context).portfolio,
      Icons.dashboard,
      UIUtils.buildValueBeforeText(
        context,
        CurrencyUtils.getFormattedAmount(
            dataManager.convert(dataManager.yamTotalValue +
                dataManager.rwaHoldingsValue +
                dataManager.totalUsdcDepositBalance +
                dataManager.totalXdaiDepositBalance -
                dataManager.totalUsdcBorrowBalance -
                dataManager.totalXdaiBorrowBalance),
            dataManager.currencySymbol,
            showAmounts),
        'projection YAM (${(((dataManager.yamTotalValue + dataManager.rwaHoldingsValue + dataManager.totalUsdcDepositBalance + dataManager.totalXdaiDepositBalance - dataManager.totalUsdcBorrowBalance - dataManager.totalXdaiBorrowBalance) / dataManager.totalWalletValue - 1) * 100).toStringAsFixed(0)}%)',
        isLoading,
        highlightPercentage: true,
      ),
      [
        UIUtils.buildValueBeforeText(context, CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.totalWalletValue), dataManager.currencySymbol, showAmounts),
            S.of(context).totalPortfolio, isLoading),
        _buildIndentedBalance(S.of(context).wallet, dataManager.convert(dataManager.walletValue), dataManager.currencySymbol, true, context, isLoading),
        _buildIndentedBalance(S.of(context).rmm, dataManager.convert(dataManager.rmmValue), dataManager.currencySymbol, true, context, isLoading),
        _buildIndentedBalance(S.of(context).rwaHoldings, dataManager.convert(dataManager.rwaHoldingsValue), dataManager.currencySymbol, true, context, isLoading),
        const SizedBox(height: 10),
        _buildIndentedBalance(S.of(context).depositBalance, dataManager.convert(dataManager.totalUsdcDepositBalance + dataManager.totalXdaiDepositBalance),
            dataManager.currencySymbol, true, context, isLoading),
        _buildIndentedBalance(S.of(context).borrowBalance, dataManager.convert(dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance), dataManager.currencySymbol,
            false, context, isLoading),
      ],
      dataManager,
      context,
      hasGraph: true,
      rightWidget: _buildVerticalGauge(_getPortfolioBarGraphData(dataManager), context),
    );
  }

  Widget _buildIndentedBalance(String label, double value, String symbol, bool isPositive, BuildContext context, bool isLoading) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    String formattedAmount = showAmounts
        ? (isPositive ? "+ ${CurrencyUtils.formatCurrency(value, symbol)}" : "- ${CurrencyUtils.formatCurrency(value, symbol)}")
        : (isPositive ? "+ " : "- ") + ('*' * 10);

    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                  highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!,
                  child: Container(
                    width: 60,
                    height: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                  ),
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11 + appState.getTextSizeOffset(),
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalGauge(double value, BuildContext context) {
    // Utiliser une valeur par défaut si 'value' est NaN ou négatif
    double displayValue = value.isNaN || value < 0 ? 0 : value;

    return Padding(
      padding: const EdgeInsets.only(right: 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ajuster la taille de la colonne au contenu
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ROI", // Titre de la jauge
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(width: 8), // Espacement entre le texte et l'icône
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(S.of(context).roiPerProperties), // Titre du popup
                        content: Text(S.of(context).roiAlertInfo), // Texte du popup
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Fermer le popup
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline, // Icône à afficher
                  size: 15, // Taille de l'icône
                  color: Colors.grey, // Couleur de l'icône
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Espacement entre le titre et la jauge
          SizedBox(
            height: 100, // Hauteur totale de la jauge
            width: 90, // Largeur de la jauge
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: 100, // Échelle sur 100%
                barTouchData: BarTouchData(
                  enabled: true, // Activer l'interaction pour l'animation au toucher
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 25 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: Colors.black54), // Définir la taille et couleur du texte
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false), // Désactiver la grille
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: displayValue, // Utiliser la valeur corrigée
                        width: 20, // Largeur de la barre
                        borderRadius: BorderRadius.circular(10), // Bordures arrondies
                        color: Colors.transparent, // Couleur transparente pour appliquer le dégradé
                        gradient: LinearGradient(
                          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100, // Fond de la jauge
                          color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3), // Couleur du fond grisé
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(0, displayValue, Colors.blueAccent.withOpacity(0.6)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8), // Espacement entre le titre et la jauge
          Text(
            "${displayValue.toStringAsFixed(1)}%", // Valeur de la barre affichée en dessous
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color, // Même couleur que la barre
            ),
          ),
        ],
      ),
    );
  }

  double _getPortfolioBarGraphData(DataManager dataManager) {
    return (dataManager.roiGlobalValue);
  }
}
