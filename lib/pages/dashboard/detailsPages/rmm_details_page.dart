import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/text_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'dart:ui';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Détails RMM',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: walletsWithUsage.isEmpty && walletsNoUsage.isEmpty
          ? Center(
              child: Text(
                'Aucune donnée disponible',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: index < walletsWithUsage.length
                            ? _WalletDetailCard(wallet: walletsWithUsage[index], currencyUtils: currencyUtils)
                            : _NoUsageWalletsCard(noUsageWallets: walletsNoUsage),
                      ),
                      childCount: walletsWithUsage.length + (walletsNoUsage.isNotEmpty ? 1 : 0),
                    ),
                  ),
                ),
                // Espace en bas pour éviter que le dernier élément ne soit caché par la barre de navigation
                const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
              ],
            ),
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

    // Couleurs pour les health factors
    final Color hfColor = walletHF < 1.5 
      ? Colors.red 
      : walletHF < 3 
          ? Colors.orange 
          : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      TextUtils.truncateWallet(address),
                      style: TextStyle(
                        fontSize: 15 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hfColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        walletHF < 1.5 
                          ? Icons.warning_amber_rounded 
                          : Icons.check_circle_outline,
                        color: hfColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "HF: ${walletHF.toStringAsFixed(1)}",
                        style: TextStyle(
                          fontSize: 14 + appState.getTextSizeOffset(),
                          fontWeight: FontWeight.w600,
                          color: hfColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne de gauche avec les informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        "Dépôts",
                        [
                          _buildInfoItem(
                            "XDAI",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(xdaiDeposit),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.green.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            "USDC",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(usdcDeposit),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.green.shade700,
                          ),
                        ],
                        context,
                        appState,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        "Emprunts",
                        [
                          _buildInfoItem(
                            "USDC",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(usdcBorrow),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.red.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            "XDAI",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(xdaiBorrow),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.red.shade700,
                          ),
                        ],
                        context,
                        appState,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        "Valeur RMM",
                        currencyUtils.getFormattedAmount(
                          currencyUtils.convert(walletRmmValue),
                          currencyUtils.currencySymbol,
                          true,
                        ),
                        context,
                        appState,
                        isBold: true,
                        textSize: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Colonne de droite avec les jauges
                _buildVerticalGauges(walletHF, walletLTV, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, BuildContext context, 
      AppState appState, {bool isBold = false, Color? valueColor, double textSize = 14}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: textSize + appState.getTextSizeOffset(),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: (textSize - 2) + appState.getTextSizeOffset(),
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalGauges(double hf, double ltv, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Limiter les valeurs pour l'affichage
    double progressHF = (hf.clamp(0, 10) / 10).clamp(0.0, 1.0);
    double progressLTV = (ltv / 100).clamp(0.0, 1.0);

    // Déterminer les couleurs basées sur les valeurs
    Color progressHFColor = Color.lerp(Colors.red, Colors.green, progressHF)!;
    Color progressLTVColor = Color.lerp(Colors.green.shade300, Colors.red, progressLTV)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Jauge Health Factor (HF)
          _buildGauge(
            "HF",
            hf.toStringAsFixed(1),
            progressHF,
            progressHFColor,
            context,
            appState,
          ),
          const SizedBox(width: 20),
          // Jauge LTV
          _buildGauge(
            "LTV",
            "${(progressLTV * 100).toStringAsFixed(1)}%",
            progressLTV,
            progressLTVColor,
            context,
            appState,
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(String title, String value, double progress, Color color, BuildContext context, AppState appState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).secondaryHeaderColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Fond de jauge
              Container(
                width: 30,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              // Remplissage de la jauge avec animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuad,
                width: 30,
                height: progress * 120,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
              ),
              // Marqueurs de niveau (lignes horizontales)
              ...List.generate(5, (index) {
                final position = index * 0.25;
                return Positioned(
                  bottom: position * 120,
                  child: Container(
                    height: 1,
                    width: 30,
                    color: Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoUsageWalletsCard extends StatelessWidget {
  final List<Map<String, dynamic>> noUsageWallets;
  const _NoUsageWalletsCard({Key? key, required this.noUsageWallets})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Récupérer les adresses complètes sans tronquage, chaque adresse sur une nouvelle ligne
    final List<String> addresses = noUsageWallets
        .map((wallet) => wallet['address'] as String? ?? 'Inconnu')
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Wallets sans utilisation RMM',
                  style: TextStyle(
                    fontSize: 16 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).secondaryHeaderColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: addresses.map((address) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appState.showAmounts ? address : TextUtils.truncateWallet(address),
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
