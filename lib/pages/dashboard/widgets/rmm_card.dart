import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/pages/dashboard/detailsPages/rmm_details_page.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';

class RmmCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const RmmCard({Key? key, required this.showAmounts, required this.isLoading})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context);

    // Récupérer la liste des wallets depuis perWalletBalances
    final List<Map<String, dynamic>> walletDetails =
        dataManager.perWalletBalances;
// Sélection du wallet ayant le HF le plus bas, basé sur walletRmmValue
    Map<String, dynamic>? walletWithLowestHF;
    double lowestHF = double.infinity;

    for (var wallet in walletDetails) {
      final String address = wallet['address'] ?? '';
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      final double totalBorrow = usdcBorrow + xdaiBorrow;

      // Utilise la même valeur RMM que dans l'autre page
      final double walletRmmValue =
          dataManager.perWalletRmmValues[address] ?? 0;

      // Calcul du Health Factor basé sur walletRmmValue
      final double hf = totalBorrow > 0
          ? (walletRmmValue * 0.7) / totalBorrow
          : double.infinity;

      if (hf < lowestHF) {
        lowestHF = hf;
        walletWithLowestHF = wallet;
      }
    }

// Récupération des valeurs finales du wallet sélectionné
    final String selectedAddress = walletWithLowestHF?['address'] ?? '';
    final double usdcDeposit =
        walletWithLowestHF?['usdcDeposit'] as double? ?? 0;
    final double xdaiDeposit =
        walletWithLowestHF?['xdaiDeposit'] as double? ?? 0;
    final double usdcBorrow = walletWithLowestHF?['usdcBorrow'] as double? ?? 0;
    final double xdaiBorrow = walletWithLowestHF?['xdaiBorrow'] as double? ?? 0;
    final double walletDeposit = usdcDeposit + xdaiDeposit;
    final double walletBorrow = usdcBorrow + xdaiBorrow;

// Récupération correcte du walletRmmValue
    final double walletRmmValue =
        dataManager.perWalletRmmValues[selectedAddress] ?? 0;

// Calcul final du Health Factor et du LTV
    double healthFactor = walletBorrow > 0
        ? (walletRmmValue * 0.7) / walletBorrow
        : double.infinity;
    double currentLTV =
        walletRmmValue > 0 ? (walletBorrow / walletRmmValue * 100) : 0;

// Gestion des cas particuliers pour l'affichage
    if (healthFactor.isInfinite || healthFactor.isNaN || walletBorrow == 0) {
      healthFactor = 10.0; // Valeur par défaut pour un HF sûr
    }

    currentLTV = currentLTV.clamp(0.0, 100.0);

    return UIUtils.buildCard(
      S.of(context).rmm,
      Icons.currency_exchange,
      UIUtils.buildValueBeforeText(
        context,
        healthFactor >= 10 ? '∞' : healthFactor.toStringAsFixed(1),
        'Health factor',
        isLoading,
      ),
      [
        UIUtils.buildValueBeforeText(
          context,
          currentLTV.toStringAsFixed(1),
          'Current LTV',
          isLoading,
        ),
        const SizedBox(height: 10),
        Text(
          '${S.of(context).timeBeforeLiquidation}: ${_calculateTimeBeforeLiquidationFormatted(
            walletDeposit,
            usdcBorrow,
            xdaiBorrow,
            dataManager.usdcDepositApy,
          )}',
          style: TextStyle(
            fontSize: 13 + appState.getTextSizeOffset(),
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(xdaiDeposit),
              currencyUtils.currencySymbol, showAmounts),
          'Xdai ${S.of(context).depositBalance}',
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(usdcDeposit),
              currencyUtils.currencySymbol, showAmounts),
          'USDC ${S.of(context).depositBalance}',
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(usdcBorrow),
              currencyUtils.currencySymbol, showAmounts),
          'USDC ${S.of(context).borrowBalance}',
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(xdaiBorrow),
              currencyUtils.currencySymbol, showAmounts),
          'Xdai ${S.of(context).borrowBalance}',
          isLoading,
          context,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      // À droite, on affiche la jauge et la flèche de navigation
      rightWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              double factor = healthFactor;
              factor = factor.isNaN || factor < 0 ? 0 : factor.clamp(0.0, 10.0);
              return _buildVerticalGauges(
                  factor, walletRmmValue, walletBorrow, context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalGauges(double factor, double walletDeposit,
      double walletBorrow, BuildContext context) {
    double progressHF = (factor / 10).clamp(0.0, 1.0);
    double progressLTV = walletDeposit > 0
        ? ((walletBorrow / walletDeposit * 100).clamp(0.0, 100.0)) / 100
        : 0;

    Color progressHFColor = Color.lerp(Colors.red, Colors.green, progressHF)!;
    Color progressLTVColor =
        Color.lerp(Colors.green.shade300, Colors.red, progressLTV)!;

    return SizedBox(
      width: 90,
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Jauge Health Factor (HF)
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'HF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 20,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: progressHF * 100,
                    decoration: BoxDecoration(
                      color: progressHFColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                (progressHF * 10).toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          // Jauge LTV
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'LTV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 20,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: progressLTV * 100,
                    decoration: BoxDecoration(
                      color: progressLTVColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${(progressLTV * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTimeBeforeLiquidationFormatted(
      double walletDeposit, double usdcBorrow, double xdaiBorrow, double apy) {
    final double totalBorrow = usdcBorrow + xdaiBorrow;
    if (totalBorrow == 0 || apy == 0) {
      return '∞';
    }
    final double liquidationThreshold = walletDeposit * 0.7;
    if (liquidationThreshold <= totalBorrow) {
      return 'Liquidation imminente';
    }
    final double dailyRate = apy / 365 / 100;
    final double timeInDays =
        (liquidationThreshold - totalBorrow) / (totalBorrow * dailyRate);
    if (timeInDays > 100 * 30) {
      final double years = timeInDays / 365;
      return '${years.toStringAsFixed(1)} ans';
    } else if (timeInDays > 100) {
      final double months = timeInDays / 30;
      return '${months.toStringAsFixed(1)} mois';
    } else {
      return '${timeInDays.toStringAsFixed(1)} jours';
    }
  }
}
