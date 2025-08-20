import 'package:meprop_asset_tracker/managers/data_manager.dart';
import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/app_state.dart';

class RealtPage extends StatefulWidget {
  const RealtPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<RealtPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Center(
          child: Image.asset(
            'assets/RealT_Logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // Carte Investissement
                _buildIOSStyleCard(
                  context,
                  S.of(context).investment,
                  CupertinoIcons.money_dollar_circle,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(dataManager.totalRealtInvestment), currencyUtils.currencySymbol),
                  S.of(context).totalInvestment,
                  [
                    _buildIOSValueRow(
                      context,
                      currencyUtils.formatCurrency(
                          currencyUtils.convert(dataManager.netRealtRentYear), currencyUtils.currencySymbol),
                      S.of(context).netAnnualRent,
                    ),
                    _buildIOSValueRow(
                      context,
                      currencyUtils.formatCurrency(
                          currencyUtils.convert(dataManager.realtInitialPrice), currencyUtils.currencySymbol),
                      S.of(context).initialPrice,
                    ),
                  ],
                  CupertinoColors.systemGreen,
                ),
                const SizedBox(height: 16),

                // Carte Performance/ROI
                _buildIOSStyleCard(
                  context,
                  S.of(context).realTPerformance,
                  CupertinoIcons.chart_bar_fill,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(dataManager.realtActualPrice), currencyUtils.currencySymbol),
                  S.of(context).realtActualPrice,
                  [
                    _buildIOSValueRow(
                      context,
                      '${dataManager.realtInitialPrice > 0 ? (((dataManager.realtActualPrice - dataManager.realtInitialPrice) / dataManager.realtInitialPrice * 100)).toStringAsFixed(2) : "0.00"}%',
                      S.of(context).priceEvolutionPercentage.replaceAll(':', ''),
                      valueColor: (dataManager.realtActualPrice >= dataManager.realtInitialPrice)
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                    ),
                    _buildIOSValueRow(
                      context,
                      currencyUtils.formatCurrency(
                          currencyUtils.convert(dataManager.realtActualPrice - dataManager.realtInitialPrice),
                          currencyUtils.currencySymbol),
                      'Gain/Perte',
                      valueColor: (dataManager.realtActualPrice >= dataManager.realtInitialPrice)
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                    ),
                  ],
                  CupertinoColors.systemIndigo,
                ),
                const SizedBox(height: 16),

                // Carte Propriétés
                _buildIOSStyleCard(
                  context,
                  S.of(context).properties,
                  CupertinoIcons.home,
                  '${dataManager.totalRealtTokens}',
                  S.of(context).tokens,
                  [
                    _buildIOSValueRow(
                      context,
                      '${dataManager.totalRealtUnits}',
                      S.of(context).units,
                    ),
                    _buildIOSValueRow(
                      context,
                      '${dataManager.rentedRealtUnits}',
                      S.of(context).rentedUnitsSimple,
                    ),
                    _buildIOSValueRow(
                      context,
                      '${dataManager.totalRealtUnits > 0 ? (dataManager.rentedRealtUnits / dataManager.totalRealtUnits * 100).toStringAsFixed(1) : "0.0"}%',
                      S.of(context).rented,
                      valueColor: CupertinoColors.systemGreen,
                    ),
                  ],
                  CupertinoColors.systemBlue,
                ),
                const SizedBox(height: 16),

                // Carte Revenus
                _buildIOSStyleCard(
                  context,
                  S.of(context).revenue,
                  CupertinoIcons.money_dollar,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(dataManager.netRealtRentYear / 365), currencyUtils.currencySymbol),
                  S.of(context).daily,
                  [
                    _buildIOSValueRow(
                      context,
                      currencyUtils.formatCurrency(
                          currencyUtils.convert(dataManager.netRealtRentYear / 12), currencyUtils.currencySymbol),
                      S.of(context).monthly,
                    ),
                    _buildIOSValueRow(
                      context,
                      currencyUtils.formatCurrency(
                          currencyUtils.convert(dataManager.netRealtRentYear), currencyUtils.currencySymbol),
                      S.of(context).annually,
                    ),
                  ],
                  CupertinoColors.systemOrange,
                ),
                const SizedBox(height: 16),

                // Carte Rendement
                _buildIOSStyleCard(
                  context,
                  S.of(context).realTPerformance,
                  CupertinoIcons.percent,
                  '${dataManager.averageRealtAnnualYield.toStringAsFixed(2)}%',
                  S.of(context).annualYield,
                  [
                    _buildIOSValueRow(
                      context,
                      '${dataManager.totalRealtInvestment > 0 ? (dataManager.netRealtRentYear / dataManager.totalRealtInvestment * 100).toStringAsFixed(2) : "0.00"}%',
                      'ROI',
                    ),
                  ],
                  CupertinoColors.systemPurple,
                ),
                const SizedBox(height: 16),

                // Carte Répartition par Type de Produit
                _buildProductTypeDistributionCard(context, dataManager, currencyUtils),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductTypeDistributionCard(
      BuildContext context, DataManager dataManager, CurrencyProvider currencyUtils) {
    Map<String, Map<String, dynamic>> productTypeStats = {};

    // Analyser les tokens pour calculer les statistiques par productType
    for (var token in dataManager.allTokens) {
      String productTypeKey = token['productType']?.toString() ?? 'other';
      String productType = _getLocalizedProductTypeName(context, productTypeKey);

      if (!productTypeStats.containsKey(productType)) {
        productTypeStats[productType] = {
          'count': 0,
          'totalValue': 0.0,
          'totalRent': 0.0,
        };
      }

      productTypeStats[productType]!['count'] += 1;
      productTypeStats[productType]!['totalValue'] += (token['totalValue'] ?? 0.0);
      productTypeStats[productType]!['totalRent'] += (token['yearlyIncome'] ?? 0.0);
    }

    List<Widget> productTypeRows = [];
    productTypeStats.forEach((productType, stats) {
      productTypeRows.add(
        _buildProductTypeRow(
          context,
          productType,
          stats['count'],
          currencyUtils.formatCurrency(currencyUtils.convert(stats['totalValue']), currencyUtils.currencySymbol),
          currencyUtils.formatCurrency(currencyUtils.convert(stats['totalRent']), currencyUtils.currencySymbol),
        ),
      );
    });

    return _buildIOSStyleCard(
      context,
      S.of(context).tokenDistributionByProductType,
      CupertinoIcons.square_grid_2x2,
      '${productTypeStats.length}',
      S.of(context).productTypeOther,
      productTypeRows,
      CupertinoColors.systemTeal,
    );
  }

  Widget _buildProductTypeRow(BuildContext context, String productType, int count, String value, String rent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              productType,
              style: TextStyle(
                fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue.resolveFrom(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedProductTypeName(BuildContext context, String productType) {
    switch (productType.toLowerCase()) {
      case 'real_estate_rental':
        return S.of(context).productTypeRealEstateRental;
      case 'factoring_profitshare':
        return S.of(context).productTypeFactoringProfitshare;
      case 'loan_income':
        return S.of(context).productTypeLoanIncome;
      default:
        return S.of(context).productTypeOther;
    }
  }

  Widget _buildIOSStyleCard(
    BuildContext context,
    String title,
    IconData icon,
    String mainValue,
    String mainLabel,
    List<Widget> additionalRows,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIOSValueRow(
              context,
              mainValue,
              mainLabel,
              valueSize: 18,
              valueColor: iconColor,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...additionalRows,
          ],
        ),
      ),
    );
  }

  Widget _buildIOSValueRow(
    BuildContext context,
    String value,
    String label, {
    double valueSize = 16,
    Color? valueColor,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: fontWeight,
              color: valueColor ?? CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
