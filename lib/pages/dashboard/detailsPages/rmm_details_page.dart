import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/text_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';

class RmmWalletDetailsPage extends StatelessWidget {
  const RmmWalletDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final List<Map<String, dynamic>> walletDetails =
        dataManager.perWalletBalances;

    // Séparer les wallets avec utilisation de ceux sans utilisation
    final List<Map<String, dynamic>> walletsWithUsage =
        walletDetails.where((wallet) {
      final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
      final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      return !(usdcDeposit == 0 &&
          xdaiDeposit == 0 &&
          usdcBorrow == 0 &&
          xdaiBorrow == 0);
    }).toList();

    final List<Map<String, dynamic>> walletsNoUsage =
        walletDetails.where((wallet) {
      final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
      final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      return (usdcDeposit == 0 &&
          xdaiDeposit == 0 &&
          usdcBorrow == 0 &&
          xdaiBorrow == 0);
    }).toList();

    // Trier les wallets avec utilisation par HealthFactor croissant
    walletsWithUsage.sort((a, b) {
      final double aUsdcBorrow = a['usdcBorrow'] as double? ?? 0;
      final double aXdaiBorrow = a['xdaiBorrow'] as double? ?? 0;
      final double bUsdcBorrow = b['usdcBorrow'] as double? ?? 0;
      final double bXdaiBorrow = b['xdaiBorrow'] as double? ?? 0;
      final double aBorrowSum = aUsdcBorrow + aXdaiBorrow;
      final double bBorrowSum = bUsdcBorrow + bXdaiBorrow;

      final double aRmm = dataManager.perWalletRmmValues[a['address']] ?? 0;
      final double bRmm = dataManager.perWalletRmmValues[b['address']] ?? 0;

      // Calcul du HealthFactor (HF)
      final double aHF = aBorrowSum > 0 ? (aRmm * 0.7 / aBorrowSum) : 10;
      final double bHF = bBorrowSum > 0 ? (bRmm * 0.7 / bBorrowSum) : 10;

      return aHF.compareTo(bHF);
    });

    // Création de la liste des widgets à afficher
    List<Widget> cards = [];
    cards.addAll(walletsWithUsage
        .map((wallet) =>
            _WalletDetailCard(wallet: wallet, currencyUtils: currencyUtils))
        .toList());
    if (walletsNoUsage.isNotEmpty) {
      cards.add(_NoUsageWalletsCard(noUsageWallets: walletsNoUsage));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails RMM'),
      ),
      body: cards.isNotEmpty
          ? ListView(
              children: cards,
            )
          : Center(child: Text('Aucune donnée disponible')),
    );
  }
}

class _WalletDetailCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  final CurrencyProvider currencyUtils;

  const _WalletDetailCard(
      {Key? key, required this.wallet, required this.currencyUtils})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
      final appState = Provider.of<AppState>(context, listen: false);

    // Récupération des informations du wallet
    final String address =  wallet['address'];
    final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
    final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
    final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
    final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;

    // Récupération de la valeur RMM propre à ce wallet
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final double walletRmmValue = dataManager.perWalletRmmValues[address] ?? 0;

    // Calcul du Health Factor (HF) et du LTV
    final double walletBorrowSum = usdcBorrow + xdaiBorrow;
    final double walletHF =
        walletBorrowSum > 0 ? (walletRmmValue * 0.7 / walletBorrowSum) : 10;
    final double walletLTV =
        walletRmmValue > 0 ? (walletBorrowSum / walletRmmValue * 100) : 0;

    // Affichage de la carte complète avec les détails
    return UIUtils.buildCard(
      'Wallet: ${TextUtils.truncateWallet(address)}', // Titre avec adresse tronquée
      Icons.account_balance_wallet, // Icône
      UIUtils.buildValueBeforeText(
        context,
        walletHF.toStringAsFixed(1),
        'Health Factor',
        false,
      ),
      [
        UIUtils.buildValueBeforeText(
          context,
          walletLTV.toStringAsFixed(1),
          'LTV',
          false,
        ),
        const SizedBox(height: 10),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(
            currencyUtils.convert(xdaiDeposit),
            currencyUtils.currencySymbol,
            true,
          ),
          'Xdai Deposit',
          false,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(
            currencyUtils.convert(usdcDeposit),
            currencyUtils.currencySymbol,
            true,
          ),
          'USDC Deposit',
          false,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(
            currencyUtils.convert(usdcBorrow),
            currencyUtils.currencySymbol,
            true,
          ),
          'USDC Borrow',
          false,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(
            currencyUtils.convert(xdaiBorrow),
            currencyUtils.currencySymbol,
            true,
          ),
          'Xdai Borrow',
          false,
          context,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      // Affichage des jauges pour HF et LTV à droite
      rightWidget: _buildVerticalGauges(walletHF, walletLTV, context),
    );
  }

  Widget _buildVerticalGauges(double hf, double ltv, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    double progressHF = (hf.clamp(0, 10) / 10).clamp(0.0, 1.0);
    double progressLTV = (ltv / 100).clamp(0.0, 1.0);

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
                  fontSize: 14 + appState.getTextSizeOffset(),
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
                hf.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12 + appState.getTextSizeOffset(),
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
                  fontSize: 14 + appState.getTextSizeOffset(),
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
                  fontSize: 12 + appState.getTextSizeOffset(),
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

  
}

class _NoUsageWalletsCard extends StatelessWidget {
  final List<Map<String, dynamic>> noUsageWallets;
  const _NoUsageWalletsCard({Key? key, required this.noUsageWallets})
      : super(key: key);



  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final appState = Provider.of<AppState>(context);

    // Récupérer les adresses complètes sans tronquage, chaque adresse sur une nouvelle ligne
    final List<String> addresses = noUsageWallets
        .map((wallet) => wallet['address'] as String? ?? 'Inconnu')
        .toList();
    final String addressesStr = addresses.join('\n');

    return UIUtils.buildCard(
      'Wallets sans utilisation RMM',
      Icons.account_balance_wallet_outlined,
      Container(),
      [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            appState.showAmounts ? addressesStr : TextUtils.truncateWallet(addressesStr),
            style: TextStyle(fontSize: 12 + appState.getTextSizeOffset(), fontStyle: FontStyle.italic),
          ),
        )
      ],
      dataManager,
      context,
      hasGraph: false,
    );
  }
}
