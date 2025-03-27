import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/settings/manage_evm_addresses_page.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/utils/shimmer_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui'; // Pour ImageFilter

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
      // Vérifier si les données sont déjà chargées
      final dataManager = Provider.of<DataManager>(context, listen: false);
      
      // Si les données principales sont déjà chargées (depuis main.dart)
      if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && dataManager.portfolio.isNotEmpty) {
        debugPrint("📊 Dashboard: données déjà chargées, skip chargement");
        setState(() {
          _isPageLoading = false;
        });
      } 
      // Sinon, charger les données avec cache
      else {
        debugPrint("📊 Dashboard: chargement des données nécessaire");
        await DataFetchUtils.loadDataWithCache(context);
        setState(() {
          _isPageLoading = false;
        });
      }
    });
  }

  // Calcule le temps écoulé depuis le premier loyer reçu
  String _getTimeElapsedSinceFirstRent(DataManager dataManager) {
    final rentData = dataManager.rentData;

    if (rentData.isEmpty) {
      return "";
    }

    // Trier les données par date (la plus ancienne en premier)
    rentData.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

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
      return years == 1 ? "$years year ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}" : "$years years ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}";
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
    final totalRentReceived = currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.getTotalRentReceived()), currencyUtils.currencySymbol, appState.showAmounts);
    final timeElapsed = _getTimeElapsedSinceFirstRent(dataManager);
    
    // Vérifier si des données sont en cours de mise à jour pour les shimmers
    final bool shouldShowShimmers = _isPageLoading || dataManager.isUpdatingData;

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
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).cardColor,
            displacement: 110,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(top: UIUtils.getAppBarHeight(context), left: 12.0, right: 12.0),
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
                            style: TextStyle(fontSize: 28 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ],
                      ),
                    ),
                    if (!_isPageLoading && (dataManager.evmAddresses.isEmpty)) _buildNoWalletCard(context),
                    const SizedBox(height: 8),
                    Container(
                      margin: EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.8),
                            Theme.of(context).primaryColor,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.2, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                             
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            S.of(context).lastRentReceived,
                                            style: TextStyle(
                                              fontSize: 13 + appState.getTextSizeOffset(),
                                              color: Colors.white70,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          dataManager.isLoadingMain || shouldShowShimmers
                                            ? ShimmerUtils.originalColorShimmer(
                                                child: Text(
                                                  lastRentReceived,
                                                  style: TextStyle(
                                                    fontSize: 20 + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                color: Colors.white,
                                              )
                                            : Text(
                                                lastRentReceived,
                                                style: TextStyle(
                                                  fontSize: 20 + appState.getTextSizeOffset(),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Total des loyers',
                                            style: TextStyle(
                                              fontSize: 13 + appState.getTextSizeOffset(),
                                              color: Colors.white70,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          dataManager.isLoadingMain || shouldShowShimmers
                                            ? ShimmerUtils.originalColorShimmer(
                                                child: Text(
                                                  totalRentReceived,
                                                  style: TextStyle(
                                                    fontSize: 20 + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                color: Colors.white,
                                              )
                                            : Text(
                                                totalRentReceived,
                                                style: TextStyle(
                                                  fontSize: 20 + appState.getTextSizeOffset(),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                   Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Depuis $timeElapsed',
                                            style: TextStyle(
                                              fontSize: 12 + appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    PortfolioCard(
                      showAmounts: appState.showAmounts,
                      isLoading: shouldShowShimmers,
                      context: context,
                    ),
                    const SizedBox(height: 8),
                    RmmCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                    const SizedBox(height: 8),
                    PropertiesCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                    const SizedBox(height: 8),
                    TokensCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                    const SizedBox(height: 8),
                    RentsCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                    const SizedBox(height: 8),
                    NextRondaysCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
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
        color: Theme.of(context).brightness == Brightness.light ? Color(0xFFE5F2FF) : Color(0xFF0A3060),
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
                fontSize: 17 + Provider.of<AppState>(context).getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.light ? Color(0xFF007AFF) : Colors.white,
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

    rentData.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final lastRent = rentData.first['rent'];

    // Utiliser _getFormattedAmount pour masquer ou afficher la valeur
    return currencyUtils.getFormattedAmount(currencyUtils.convert(lastRent), currencyUtils.currencySymbol, appState.showAmounts);
  }
}
