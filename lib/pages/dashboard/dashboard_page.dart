import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/settings/manage_evm_addresses_page.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _showAmounts = true;
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyMode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DataFetchUtils.loadData(context);
      setState(() {
        _isPageLoading = false;
      });
    });
  }

  void _toggleAmountsVisibility() async {
    setState(() {
      _showAmounts = !_showAmounts;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAmounts', _showAmounts);
  }

  Future<void> _loadPrivacyMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAmounts = prefs.getBool('showAmounts') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final appState = Provider.of<AppState>(context);

    IconButton visibilityButton = IconButton(
      icon: Icon(_showAmounts ? Icons.visibility : Icons.visibility_off),
      onPressed: _toggleAmountsVisibility,
    );

    final lastRentReceived = _getLastRentReceived(dataManager);
    final totalRentReceived = currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.getTotalRentReceived()), currencyUtils.currencySymbol, _showAmounts);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => DataFetchUtils.refreshData(context),
            displacement: 100,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(top: UIUtils.getAppBarHeight(context), left: 8.0, right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).hello,
                          style: TextStyle(fontSize: 24 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        visibilityButton,
                      ],
                    ),
                    if (!_isPageLoading && (dataManager.evmAddresses.isEmpty)) _buildNoWalletCard(context),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          // Partie statique pour "Last Rent Received"
                          TextSpan(
                            text: S.of(context).lastRentReceived,
                            style: TextStyle(
                              fontSize: 16 + appState.getTextSizeOffset(),
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          // Partie dynamique avec ou sans shimmer pour "lastRentReceived"
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: dataManager.isLoadingMain
                                ? Shimmer.fromColors(
                                    baseColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[300]!,
                                    highlightColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9) ?? Colors.grey[100]!,
                                    child: Container(
                                      width: 100, // Largeur placeholder
                                      height: 20, // Hauteur placeholder
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2),
                                    ),
                                  )
                                : Text(
                                    lastRentReceived,
                                    style: TextStyle(
                                      fontSize: 18 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                          ),
                          // Partie statique pour "Total Rent Received"
                          TextSpan(
                            text: '\n${S.of(context).totalRentReceived}: ',
                            style: TextStyle(
                              fontSize: 16 + appState.getTextSizeOffset(),
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          // Partie dynamique avec ou sans shimmer pour "totalRentReceived"
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: dataManager.isLoadingMain
                                ? Shimmer.fromColors(
                                    baseColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                                    highlightColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey[100]!,
                                    child: Container(
                                      width: 100, // Largeur placeholder
                                      height: 16, // Hauteur placeholder
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2),
                                    ),
                                  )
                                : Text(
                                    totalRentReceived,
                                    style: TextStyle(
                                      fontSize: 18 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    PortfolioCard(
                      showAmounts: _showAmounts,
                      isLoading: _isPageLoading,
                      context: context,
                    ),
                    const SizedBox(height: 8),
                    RmmCard(showAmounts: _showAmounts, isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    PropertiesCard(showAmounts: _showAmounts, isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    TokensCard(showAmounts: _showAmounts, isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    RentsCard(showAmounts: _showAmounts, isLoading: _isPageLoading),
                    const SizedBox(height: 8),
                    NextRondaysCard(showAmounts: _showAmounts, isLoading: _isPageLoading),
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
    return Center(
      child: Card(
        color: Theme.of(context).primaryColor.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                S.of(context).noDataAvailable,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
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
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(S.of(context).manageAddresses),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Récupère la dernière valeur de loyer
  String _getLastRentReceived(DataManager dataManager) {
    final rentData = dataManager.rentData;
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    if (rentData.isEmpty) {
      return S.of(context).noRentReceived;
    }

    rentData.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final lastRent = rentData.first['rent'];

    // Utiliser _getFormattedAmount pour masquer ou afficher la valeur
    return currencyUtils.getFormattedAmount(currencyUtils.convert(lastRent), currencyUtils.currencySymbol, _showAmounts);
  }
}
