import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/text_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/managers/apy_manager.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart'; // Pour Clipboard

class PortfolioDetailsPage extends StatelessWidget {
  const PortfolioDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    
    // Récupérer les données par wallet depuis la nouvelle structure
    final List<Map<String, dynamic>> walletDetails = 
        dataManager.walletStats;
    final List<Map<String, dynamic>> perWalletBalances =
        dataManager.perWalletBalances;

    // Associer les informations d'emprunt et de dépôt à chaque wallet
    for (var wallet in walletDetails) {
      final String address = wallet['address'] as String;
      final matchingBalance = perWalletBalances.firstWhere(
        (balance) => balance['address'] == address,
        orElse: () => <String, dynamic>{},
      );

      wallet['usdcDeposit'] = matchingBalance['usdcDeposit'] ?? 0.0;
      wallet['xdaiDeposit'] = matchingBalance['xdaiDeposit'] ?? 0.0;
      wallet['usdcBorrow'] = matchingBalance['usdcBorrow'] ?? 0.0;
      wallet['xdaiBorrow'] = matchingBalance['xdaiBorrow'] ?? 0.0;
    }

    // Trier par valeur totale
    walletDetails.sort((a, b) {
      final double aWalletValue = a['walletValueSum'] as double? ?? 0;
      final double aRmmValue = a['rmmValue'] as double? ?? 0;
      final double aTotalValue = aWalletValue + aRmmValue;
      
      final double bWalletValue = b['walletValueSum'] as double? ?? 0;
      final double bRmmValue = b['rmmValue'] as double? ?? 0;
      final double bTotalValue = bWalletValue + bRmmValue;
      
      return bTotalValue.compareTo(aTotalValue); // Tri décroissant
    });

    // Afficher les données pour debugger
    for (var wallet in walletDetails) {
      print("Portfolio details - Wallet: ${wallet['address']} - Values: $wallet");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).portfolio),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: walletDetails.isEmpty
            ? Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlobalInfo(context, dataManager, appState, currencyUtils),
                  const SizedBox(height: 20),
                  ...walletDetails.map((wallet) => 
                    _buildWalletCard(context, wallet, dataManager, appState, currencyUtils)
                  ).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildGlobalInfo(BuildContext context, DataManager dataManager, 
      AppState appState, CurrencyProvider currencyUtils) {
    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portefeuille Global',
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildRoiGauge(dataManager.roiGlobalValue, context, appState),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      S.of(context).totalPortfolio,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(dataManager.totalWalletValue),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      S.of(context).wallet,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(dataManager.walletValue),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      S.of(context).rmm,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(dataManager.rmmValue),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      S.of(context).depositBalance,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(dataManager.totalUsdcDepositBalance + 
                          dataManager.totalXdaiDepositBalance),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      S.of(context).borrowBalance,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(dataManager.totalUsdcBorrowBalance + 
                          dataManager.totalXdaiBorrowBalance),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'APY Net',
                      "${dataManager.netGlobalApy.toStringAsFixed(2)}%",
                      context,
                      appState,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoRow(
                  'Tokens',
                  dataManager.totalRealtTokens.toStringAsFixed(2),
                  context,
                  appState,
                ),
                _buildInfoRow(
                  'Properties',
                  dataManager.totalTokenCount.toString(),
                  context,
                  appState,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Map<String, dynamic> wallet, 
      DataManager dataManager, AppState appState, CurrencyProvider currencyUtils) {
    
    final String address = wallet['address'] as String;
    final double walletValue = wallet['walletValueSum'] as double? ?? 0;
    final double rmmValue = wallet['rmmValue'] as double? ?? 0;
    final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
    final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
    final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
    final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
    
    // Récupérer les statistiques supplémentaires sur les tokens
    final int tokenCount = wallet['tokenCount'] as int? ?? 0;
    final double walletTokensSum = wallet['walletTokensSum'] as double? ?? 0;
    final double rmmTokensSum = wallet['rmmTokensSum'] as double? ?? 0;
    
    // Calculer le total pour ce wallet
    final double totalWalletValue = walletValue + rmmValue + usdcDeposit + 
        xdaiDeposit - usdcBorrow - xdaiBorrow;
    
    return Card(
      elevation: 3.0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _truncateWallet(address),
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey),
                  onPressed: () {
                    // Copier l'adresse dans le presse-papier
                    _copyToClipboard(context, address);
                  },
                  tooltip: 'Copier l\'adresse',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Valeur Totale',
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(totalWalletValue),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      S.of(context).wallet,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(walletValue),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      S.of(context).rmm,
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(rmmValue),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Statistiques des tokens
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      "Properties",
                      tokenCount.toString(),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      "Total Tokens",
                      (walletTokensSum + rmmTokensSum).toStringAsFixed(2),
                      context,
                      appState,
                    ),
                  ],
                ),
                // Statistiques par type de token
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      "Wallet Tokens",
                      walletTokensSum.toStringAsFixed(2),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      "RMM Tokens",
                      rmmTokensSum.toStringAsFixed(2),
                      context,
                      appState,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      "USDC Dépôt",
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(usdcDeposit),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      "XDAI Dépôt",
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(xdaiDeposit),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      "USDC Emprunt",
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(usdcBorrow),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      "XDAI Emprunt",
                      currencyUtils.getFormattedAmount(
                        currencyUtils.convert(xdaiBorrow),
                        currencyUtils.currencySymbol,
                        true
                      ),
                      context,
                      appState,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour tronquer l'adresse du wallet
  String _truncateWallet(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Méthode pour copier dans le presse-papier
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adresse copiée dans le presse-papier')),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context, 
      AppState appState, {bool isBold = false}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12 + appState.getTextSizeOffset(),
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoiGauge(double value, BuildContext context, AppState appState) {
    // Utiliser une valeur par défaut si 'value' est NaN ou négatif
    double displayValue = value.isNaN || value < 0 ? 0 : value;
    final dataManager = Provider.of<DataManager>(context, listen: false);
    Color gaugeColor = dataManager.apyManager.getApyColor(displayValue);

    return SizedBox(
      width: 90,
      height: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "ROI",
            style: TextStyle(
              fontSize: 16 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
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
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: displayValue,
                        width: 20,
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.transparent,
                        gradient: LinearGradient(
                          colors: [
                            gaugeColor,
                            gaugeColor.withOpacity(0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: const Color.fromARGB(255, 78, 78, 78)
                              .withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${displayValue.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
} 