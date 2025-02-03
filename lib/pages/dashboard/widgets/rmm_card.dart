import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/ui_utils.dart';

class RmmCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const RmmCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    return UIUtils.buildCard(
      S.of(context).rmm,
      Icons.currency_exchange,
      UIUtils.buildValueBeforeText(
        context,
          ((dataManager.rmmValue * 0.7) / (dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance)).toStringAsFixed(1),
          'Health factor',
          isLoading),
      [
        UIUtils.buildValueBeforeText(
          context,
            ((dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance) / dataManager.rmmValue * 100).toStringAsFixed(1),
            'Current LTV',
            isLoading),
        const SizedBox(height: 10),
        Text(
          '${S.of(context).timeBeforeLiquidation}: ${_calculateTimeBeforeLiquidationFormatted(
            dataManager.rmmValue,
            dataManager.totalUsdcBorrowBalance,
            dataManager.totalXdaiBorrowBalance,
            dataManager.usdcDepositApy,
          )}',
          style: TextStyle(
            fontSize: 13 + appState.getTextSizeOffset(),
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.totalXdaiDepositBalance), dataManager.currencySymbol, showAmounts),
          'Xdai ${S.of(context).depositBalance}',
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.totalUsdcDepositBalance), dataManager.currencySymbol, showAmounts),
          'USDC ${S.of(context).depositBalance}',
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.totalUsdcBorrowBalance), dataManager.currencySymbol, showAmounts),
          'USDC ${S.of(context).borrowBalance}',
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          CurrencyUtils.getFormattedAmount(dataManager.convert(dataManager.totalXdaiBorrowBalance), dataManager.currencySymbol, showAmounts),
          'Xdai ${S.of(context).borrowBalance}',
          isLoading,
          context,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      rightWidget: Builder(
        builder: (context) {
          double factor = (dataManager.rmmValue * 0.7) / (dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance);
          factor = factor.isNaN || factor < 0 ? 0 : factor.clamp(0.0, 10.0);

          return _buildVerticalGauges(factor, context, dataManager);
        },
      ),
    );
  }

  Widget _buildVerticalGauges(double factor, BuildContext context, DataManager dataManager) {
    double progress1 = (factor / 10).clamp(0.0, 1.0); // Jauge 1
    double progress2 =
        ((dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance) / dataManager.rmmValue * 100).clamp(0.0, 100.0) / 100; // Jauge 2 (en %)

    // Couleur dynamique pour la première jauge
    Color progress1Color = Color.lerp(Colors.red, Colors.green, progress1)!;

    // Couleur dynamique pour la deuxième jauge (0% = vert, 100% = rouge)
    Color progress2Color = Color.lerp(Colors.green.shade300, Colors.red, progress2)!;

    return SizedBox(
      width: 100, // Largeur totale pour la disposition
      height: 180, // Hauteur totale
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Jauge 1 (HF)
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Titre de la jauge
              Text(
                'HF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8), // Espacement entre le titre et la jauge
              Stack(
                alignment: Alignment.bottomCenter, // Alignement pour jauge verticale
                children: [
                  // Fond de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: 100, // Hauteur totale de la jauge
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Progression de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: progress1 * 100, // Hauteur dynamique
                    decoration: BoxDecoration(
                      color: progress1Color, // Couleur dynamique
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5), // Espacement entre la jauge et le texte
              Text(
                '${(progress1 * 10).toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Jauge 2 (LTV)
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Titre de la jauge
              Text(
                'LTV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8), // Espacement entre le titre et la jauge
              Stack(
                alignment: Alignment.bottomCenter, // Alignement pour jauge verticale
                children: [
                  // Fond de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: 100, // Hauteur totale de la jauge
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Progression de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: progress2 * 100, // Hauteur dynamique
                    decoration: BoxDecoration(
                      color: progress2Color, // Couleur dynamique
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5), // Espacement entre la jauge et le texte
              Text(
                '${(progress2 * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
String _calculateTimeBeforeLiquidationFormatted(double rmmValue, double usdcBorrow, double xdaiBorrow, double apy) {
    double totalBorrow = usdcBorrow + xdaiBorrow;

    if (totalBorrow == 0 || apy == 0) {
      return '∞'; // Pas de liquidation possible
    }

    double liquidationThreshold = rmmValue * 0.7;

    if (liquidationThreshold <= totalBorrow) {
      return 'Liquidation imminente'; // Déjà liquidé
    }

    // APY en taux journalier
    double dailyRate = apy / 365 / 100;

    // Temps avant liquidation en jours
    double timeInDays = (liquidationThreshold - totalBorrow) / (totalBorrow * dailyRate);

    // Conversion en mois ou années si nécessaire
    if (timeInDays > 100 * 30) {
      // Plus de 100 mois
      double years = timeInDays / 365;
      return '${years.toStringAsFixed(1)} ans';
    } else if (timeInDays > 100) {
      // Plus de 100 jours
      double months = timeInDays / 30;
      return '${months.toStringAsFixed(1)} mois';
    } else {
      return '${timeInDays.toStringAsFixed(1)} jours';
    }
  }
}