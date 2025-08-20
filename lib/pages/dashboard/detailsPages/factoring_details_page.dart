import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/managers/data_manager.dart';
import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_chart.dart';
import 'package:meprop_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_by_wallet_card.dart';
import 'package:flutter/services.dart';
import 'package:meprop_asset_tracker/app_state.dart';
import 'package:fl_chart/fl_chart.dart';

class FactoringDetailsPage extends StatelessWidget {
  const FactoringDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filtrer uniquement les tokens de factoring
    final factoringTokens = dataManager.portfolio
        .where((token) => (token['productType'] ?? '').toLowerCase() == 'factoring_profitshare')
        .toList();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Factoring',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 + appState.getTextSizeOffset(),
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: factoringTokens.isEmpty
          ? Center(
              child: Text(
                S.of(context).noDataAvailableDot,
                style: TextStyle(
                  fontSize: 17 + appState.getTextSizeOffset(),
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).overview,
                          style: TextStyle(
                            fontSize: 20 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildOverviewCards(context, factoringTokens, appState),
                        const SizedBox(height: 24),
                        Text(
                          'Revenus Factoring',
                          style: TextStyle(
                            fontSize: 20 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildIncomeChart(context, factoringTokens, appState),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, List<Map<String, dynamic>> factoringTokens, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;

    final totalTokens = factoringTokens.length;
    final totalTokensSum =
        factoringTokens.fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.business_center_outlined,
                  size: 28,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  totalTokens.toString(),
                  style: TextStyle(
                    fontSize: 22 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tokens',
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 28,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  totalTokensSum.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 22 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantité',
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeChart(BuildContext context, List<Map<String, dynamic>> factoringTokens, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;

    final today = DateTime.now();
    final activeTokens = factoringTokens.where((token) {
      final rentStartDateString = token['rentStartDate'] as String?;
      if (rentStartDateString != null) {
        final rentStartDate = DateTime.tryParse(rentStartDateString);
        return rentStartDate != null && rentStartDate.isBefore(today);
      }
      return false;
    }).length;

    final double activePercentage = factoringTokens.isNotEmpty ? (activeTokens / factoringTokens.length * 100) : 0.0;
    final Color progressColor = Colors.deepPurple.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 28 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                  Text(
                    'Tokens actifs ($activeTokens/${factoringTokens.length})',
                    style: TextStyle(
                      fontSize: 14 + appState.getTextSizeOffset(),
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Factoring',
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w500,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: activePercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [progressColor.withOpacity(0.7), progressColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDistribution(BuildContext context, DataManager dataManager) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 300,
      child: TokenDistributionCard(dataManager: dataManager),
    );
  }

  Widget _buildWalletCard(BuildContext context, Map<String, dynamic> wallet, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final String address = wallet['address'] as String;
    final int tokenCount = wallet['tokenCount'] as int? ?? 0;
    final double walletTokensSum = wallet['walletTokensSum'] as double? ?? 0;
    final double rmmTokensSum = wallet['rmmTokensSum'] as double? ?? 0;
    final double totalTokens = walletTokensSum + rmmTokensSum;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade600.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.creditcard,
                        color: Colors.deepPurple.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _truncateWallet(address),
                    style: TextStyle(
                      fontSize: 16 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(context, address),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_on_doc,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWalletStat(context, 'Tokens', tokenCount.toString(), appState),
                    _buildWalletStat(context, 'Wallet', walletTokensSum.toStringAsFixed(2), appState),
                    _buildWalletStat(context, 'RMM', rmmTokensSum.toStringAsFixed(2), appState),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).totalTokensLabel,
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      totalTokens.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStat(BuildContext context, String label, String value, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13 + appState.getTextSizeOffset(),
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  String _truncateWallet(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(S.of(context).copied),
        message: Text(S.of(context).addressCopiedMessage),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }
}
