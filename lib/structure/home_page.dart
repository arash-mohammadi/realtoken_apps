import 'package:flutter/material.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/modals/agenda.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';

import 'bottom_bar.dart';
import 'drawer.dart';
import 'package:realtokens/pages/dashboard/dashboard_page.dart';
import 'package:realtokens/pages/portfolio/portfolio_page.dart';
import 'package:realtokens/pages/Statistics/stats_selector_page.dart';
import 'package:realtokens/pages/maps_page.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final GlobalKey _walletIconKey =
      GlobalKey(); // Clé pour obtenir la position de l'icône

  List<Map<String, dynamic>> portfolio = [];

  double _getContainerHeight(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return bottomPadding > 0 ? 75 : 60;
  }

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    PortfolioPage(),
    StatsSelectorPage(),
    MapsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAgendaModal(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final portfolio = dataManager.portfolio;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => AgendaCalendar(portfolio: portfolio),
    );
  }

  void _showWalletPopup(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);

    // Récupération de la liste des détails par wallet (issue de fetchRmmBalances)
    final List<Map<String, dynamic>> walletDetails =
        dataManager.perWalletBalances ?? [];

    // Affichage dans la console pour debug
    for (var walletInfo in walletDetails) {
      debugPrint(
          "Wallet ${walletInfo['address']} → USDC Deposit: ${walletInfo['usdcDeposit']}, USDC Borrow: ${walletInfo['usdcBorrow']}, "
          "XDAI Deposit: ${walletInfo['xdaiDeposit']}, XDAI Borrow: ${walletInfo['xdaiBorrow']}, "
          "Gnosis USDC: ${walletInfo['gnosisUsdc']}, Gnosis XDAI: ${walletInfo['gnosisXdai']}, "
          "Timestamp: ${walletInfo['timestamp']}");
    }

    // Fonction locale pour tronquer l'adresse
    String truncateAddress(String address) {
      if (address.length <= 12) return address;
      return address.substring(0, 6) +
          "..." +
          address.substring(address.length - 4);
    }

    final double usdcBalance = dataManager.gnosisUsdcBalance;
    final double xdaiBalance = dataManager.gnosisXdaiBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de drag (poignée)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // En-tête
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 22 + appState.getTextSizeOffset(),
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Portefeuille",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18 + appState.getTextSizeOffset(),
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ],
                ),
              ),
              
              // Solde total
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Solde Total",
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // USDC et XDAI côte à côte
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // USDC
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/usdc.png',
                              width: 28 + appState.getTextSizeOffset(),
                              height: 28 + appState.getTextSizeOffset(),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "USDC",
                                  style: TextStyle(
                                    fontSize: 12 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  currencyUtils.formatCurrency(
                                    currencyUtils.convert(usdcBalance),
                                    currencyUtils.currencySymbol,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // XDAI
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/xdai.png',
                              width: 28 + appState.getTextSizeOffset(),
                              height: 28 + appState.getTextSizeOffset(),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "XDAI",
                                  style: TextStyle(
                                    fontSize: 12 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  currencyUtils.formatCurrency(
                                    currencyUtils.convert(xdaiBalance),
                                    currencyUtils.currencySymbol,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Détails par wallet
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Détails par Wallet",
                    style: TextStyle(
                      fontSize: 16 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: walletDetails.length,
                  itemBuilder: (context, index) {
                    final walletInfo = walletDetails[index];
                    final String truncated = truncateAddress(walletInfo['address']);
                    final String gnosisUsdc = currencyUtils.getFormattedAmount(
                      currencyUtils.convert(walletInfo['gnosisUsdc']),
                      currencyUtils.currencySymbol,
                      appState.showAmounts,
                    );
                    final String gnosisXdai = currencyUtils.getFormattedAmount(
                      currencyUtils.convert(walletInfo['gnosisXdai']),
                      currencyUtils.currencySymbol,
                      appState.showAmounts,
                    );
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 14 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    truncated,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: 14 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    // Logique pour copier l'adresse
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/usdc.png',
                                      width: 20 + appState.getTextSizeOffset(),
                                      height: 20 + appState.getTextSizeOffset(),
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "USDC",
                                          style: TextStyle(
                                            fontSize: 10 + appState.getTextSizeOffset(),
                                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          gnosisUsdc,
                                          style: TextStyle(
                                            fontSize: 14 + appState.getTextSizeOffset(),
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/xdai.png',
                                      width: 20 + appState.getTextSizeOffset(),
                                      height: 20 + appState.getTextSizeOffset(),
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "XDAI",
                                          style: TextStyle(
                                            fontSize: 10 + appState.getTextSizeOffset(),
                                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          gnosisXdai,
                                          style: TextStyle(
                                            fontSize: 14 + appState.getTextSizeOffset(),
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final double walletTotal =
        dataManager.gnosisUsdcBalance + dataManager.gnosisXdaiBalance;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _pages.elementAt(_selectedIndex),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: UIUtils.getAppBarHeight(context),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0.5,
                    actions: [
                      // Icône portefeuille avec un Popup Menu
                      IconButton(
                        key:
                            _walletIconKey, // Associe la clé pour obtenir la position
                        icon: Icon(
                          Icons.account_balance_wallet,
                          size: 21 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => _showWalletPopup(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Center(
                          child: Text(
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(walletTotal),
                              currencyUtils.currencySymbol,
                              appState
                                  .showAmounts, // Utilisation de showAmounts
                            ),
                            style: TextStyle(
                              fontSize: 16 + appState.getTextSizeOffset(),
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.calendar_today,
                          size: 19 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => _openAgendaModal(context),
                      ),
                      IconButton(
                        icon: Icon(
                          appState.showAmounts
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 22 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => appState.toggleShowAmounts(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: _getContainerHeight(context),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  child: SafeArea(
                    top: false,
                    child: CustomBottomNavigationBar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onThemeChanged: (value) {
          appState.updateTheme(value);
        },
      ),
    );
  }
}
