import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_chart.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_by_wallet_card.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'; // Pour Clipboard

class PropertiesDetailsPage extends StatelessWidget {
  const PropertiesDetailsPage({super.key});

  Widget _buildInfoCards(
      BuildContext context, DataManager dataManager, AppState appState) {
    final List<Map<String, dynamic>> walletDetails = dataManager.walletStats;
    final List<Map<String, dynamic>> perWalletBalances = dataManager.perWalletBalances;
    
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: walletDetails.isEmpty
            ? [
                Center(
                  child: Text(
                    'Aucun portefeuille disponible.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              ]
            : walletDetails
                .map((wallet) => _buildWalletCard(context, wallet, appState))
                .toList(),
      ),
    );
  }

  Widget _buildWalletCard(
      BuildContext context, Map<String, dynamic> wallet, AppState appState) {
    final String address = wallet['address'] as String;
    final int tokenCount = wallet['tokenCount'] as int? ?? 0;
    final double walletTokensSum = wallet['walletTokensSum'] as double? ?? 0;
    final double rmmTokensSum = wallet['rmmTokensSum'] as double? ?? 0;
    
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                  onPressed: () {
                    _copyToClipboard(context, address);
                  },
                  tooltip: 'Copier l\'adresse',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardInfo(context, tokenCount.toString(), S.of(context).properties, appState),
                _buildCardInfo(context, walletTokensSum.toStringAsFixed(2), S.of(context).wallet, appState),
                _buildCardInfo(context, rmmTokensSum.toStringAsFixed(2), S.of(context).rmm, appState),
              ],
            ),
            const SizedBox(height: 8),
            _buildCardInfo(context, (walletTokensSum + rmmTokensSum).toStringAsFixed(2), S.of(context).tokens, appState, fullWidth: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo(
      BuildContext context, String value, String label, AppState appState, {bool fullWidth = false}) {
    final cardWidget = Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12 + appState.getTextSizeOffset(),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
    
    return fullWidth 
        ? SizedBox(width: double.infinity, child: cardWidget)
        : Expanded(child: cardWidget);
  }

  String _truncateWallet(String address) {
    if (address.length <= 12) return address;
    return address.substring(0, 6) + '...' + address.substring(address.length - 6);
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adresse copiée dans le presse-papier'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).properties),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: dataManager.portfolio.isEmpty
            ? Center(
                child: Text(
                  'No data available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: _buildRentedUnitsGauge(context, dataManager, appState),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            height: 250,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: 300,
                                height: 350,
                                child: TokenDistributionByWalletCard(dataManager: dataManager),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildInfoCards(context, dataManager, appState),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SizedBox(
                      height: 300,
                      child: TokenDistributionCard(dataManager: dataManager),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRentedUnitsGauge(
      BuildContext context, DataManager dataManager, AppState appState) {
    final double rentedPercentage =
        (dataManager.rentedUnits / dataManager.totalUnits) * 100;
    Color gaugeColor = _getGaugeColor(rentedPercentage);

    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unités Louées',
              style: TextStyle(
                fontSize: 18 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 100,
                        showLabels: false,
                        showTicks: false,
                        startAngle: 270,
                        endAngle: 270,
                        axisLineStyle: AxisLineStyle(
                          thickness: 0.25,
                          cornerStyle: CornerStyle.bothCurve,
                          color: Colors.grey.shade300,
                          thicknessUnit: GaugeSizeUnit.factor,
                        ),
                        pointers: <GaugePointer>[
                          RangePointer(
                            value: rentedPercentage,
                            width: 0.25,
                            enableAnimation: true,
                            cornerStyle: CornerStyle.bothCurve,
                            color: gaugeColor,
                            sizeUnit: GaugeSizeUnit.factor,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 100, 
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${rentedPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: gaugeColor,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${dataManager.rentedUnits} / ${dataManager.totalUnits}',
                          style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _buildRentedLegend(context, rentedPercentage, gaugeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRentedLegend(BuildContext context, double percentage, Color gaugeColor) {
    final appState = Provider.of<AppState>(context);
    String status = percentage < 50 ? 'Faible' : 
                     percentage < 80 ? 'Moyen' : 'Élevé';
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: gaugeColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Taux d\'occupation: $status',
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getGaugeColor(double percentage) {
    if (percentage < 50) {
      return Colors.red;
    } else if (percentage < 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
