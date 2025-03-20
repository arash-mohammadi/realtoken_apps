import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/settings/manage_evm_addresses_page.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:shimmer/shimmer.dart';

import 'widgets/portfolio_card.dart';
import 'widgets/rmm_card.dart';
import 'widgets/properties_card.dart';
import 'widgets/tokens_card.dart';
import 'widgets/rents_card.dart';
import 'widgets/next_rondays_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DataFetchUtils.loadData(context);
      setState(() {
        _isPageLoading = false;
      });
    });
  }

  // Calcule le temps écoulé depuis le premier loyer reçu
  String _getTimeElapsedSinceFirstRent(DataManager dataManager) {
    final rentData = dataManager.rentData;
    
    if (rentData.isEmpty) {
      return "";
    }
    
    // Trier les données par date (la plus ancienne en premier)
    rentData.sort((a, b) => 
      DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    
    // Date du premier loyer
    final firstRentDate = DateTime.parse(rentData.first['date']);
    final today = DateTime.now();
    
    // Calcul de la différence
    final difference = today.difference(firstRentDate);
    
    // Calcul en années et mois
    int years = difference.inDays ~/ 365;
    int months = (difference.inDays % 365) ~/ 30;
    
    // Format plus lisible
    if (years > 0) {
      return years == 1 
          ? "$years year ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}"
          : "$years years ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}";
    } else if (months > 0) {
      return "$months month${months > 1 ? 's' : ''}";
    } else {
      return "< 1 month";
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final appState = Provider.of<AppState>(context);

    final lastRentReceived = _getLastRentReceived(dataManager);
    final totalRentReceived = currencyUtils.getFormattedAmount(
        currencyUtils.convert(dataManager.getTotalRentReceived()),
        currencyUtils.currencySymbol,
        appState.showAmounts);
    final timeElapsed = _getTimeElapsedSinceFirstRent(dataManager);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Color(0xFFF2F2F7) // Couleur de fond iOS light mode
          : Color(0xFF000000), // Couleur de fond iOS dark mode
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isPageLoading = true;
              });
              await DataFetchUtils.refreshData(context);
              setState(() {
                _isPageLoading = false;
              });
            },
            color: Color(0xFF007AFF), // Couleur iOS
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            displacement: 80,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                    top: UIUtils.getAppBarHeight(context),
                    left: 12.0,
                    right: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.of(context).hello,
                            style: TextStyle(
                                fontSize: 28 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ],
                      ),
                    ),
                    if (!_isPageLoading && (dataManager.evmAddresses.isEmpty))
                      _buildNoWalletCard(context),
                    const SizedBox(height: 8),
                    Container(
                      margin: EdgeInsets.only(bottom: 12.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.white 
                            : Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                                                            dataManager.isLoadingMain
                                ? Shimmer.fromColors(
                                    baseColor: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.6) ??
                                        Colors.grey[300]!,
                                    highlightColor: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.9) ??
                                        Colors.grey[100]!,
                                    child: Container(
                                      width: 150,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  )
                                : Text(
                                    lastRentReceived,
                                    style: TextStyle(
                                      fontSize: 22 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(width: 8),

                                  Text(
                                S.of(context).lastRentReceived,
                                style: TextStyle(
                                  fontSize: 15 + appState.getTextSizeOffset(),
                                  color: Theme.of(context).brightness == Brightness.light 
                                      ? Colors.black54 
                                      : Colors.white70,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                             
                              SizedBox(width: 8),
                              dataManager.isLoadingMain
                                ? Shimmer.fromColors(
                                    baseColor: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.2) ??
                                        Colors.grey[300]!,
                                    highlightColor: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.5) ??
                                        Colors.grey[100]!,
                                    child: Container(
                                      width: 100,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Text(
                                        totalRentReceived,
                                        style: TextStyle(
                                          fontSize: 17 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'since $timeElapsed',
                                        style: TextStyle(
                                          fontSize: 14 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).primaryColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PortfolioCard(
                      showAmounts: appState.showAmounts,
                      isLoading: _isPageLoading,
                      context: context,
                    ),
                    const SizedBox(height: 8),
                    RmmCard(
                        showAmounts: appState.showAmounts,
                        isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    PropertiesCard(
                        showAmounts: appState.showAmounts,
                        isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    TokensCard(
                        showAmounts: appState.showAmounts,
                        isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    RentsCard(
                        showAmounts: appState.showAmounts,
                        isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    NextRondaysCard(
                        showAmounts: appState.showAmounts,
                        isLoading: _isPageLoading),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWalletCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light 
            ? Color(0xFFE5F2FF) 
            : Color(0xFF0A3060),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              S.of(context).noDataAvailable,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.light 
                    ? Color(0xFF007AFF) 
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageEvmAddressesPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF007AFF),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(S.of(context).manageAddresses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Récupère la dernière valeur de loyer
  String _getLastRentReceived(DataManager dataManager) {
    final rentData = dataManager.rentData;
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context);

    if (rentData.isEmpty) {
      return S.of(context).noRentReceived;
    }

    rentData.sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final lastRent = rentData.first['rent'];

    // Utiliser _getFormattedAmount pour masquer ou afficher la valeur
    return currencyUtils.getFormattedAmount(currencyUtils.convert(lastRent),
        currencyUtils.currencySymbol, appState.showAmounts);
  }
}
