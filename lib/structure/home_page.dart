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
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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

    // Fonction locale pour tronquer l'adresse (affiche les 6 premiers et 4 derniers caractères)
    String truncateAddress(String address) {
      if (address.length <= 12) return address;
      return address.substring(0, 6) +
          "..." +
          address.substring(address.length - 4);
    }

    final RenderBox renderBox =
        _walletIconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final double iconSize = renderBox.size.height;

    final double usdcBalance = dataManager.gnosisUsdcBalance;
    final double xdaiBalance = dataManager.gnosisXdaiBalance;

    showMenu(
      context: context,
      color: Theme.of(context).cardColor,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + iconSize, // positionné juste en dessous de l'icône
        position.dx + renderBox.size.width,
        position.dy +
            iconSize +
            300, // hauteur ajustable pour contenir la liste
      ),
      items: [
        PopupMenuItem(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "💰 Solde Wallet",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14 + appState.getTextSizeOffset(),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/usdc.png',
                      width: 20 + appState.getTextSizeOffset(),
                      height: 20 + appState.getTextSizeOffset(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyUtils.formatCurrency(
                        currencyUtils.convert(usdcBalance),
                        currencyUtils.currencySymbol,
                      ),
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/xdai.png',
                      width: 22 + appState.getTextSizeOffset(),
                      height: 22 + appState.getTextSizeOffset(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyUtils.formatCurrency(
                        currencyUtils.convert(xdaiBalance),
                        currencyUtils.currencySymbol,
                      ),
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  "Détails par wallet :",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14 + appState.getTextSizeOffset(),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                // Affichage des détails pour chaque wallet
                ...walletDetails.map((walletInfo) {
                  final String truncated =
                      truncateAddress(walletInfo['address']);
                  // On formate les montants à 2 décimales.
                  final String gnosisUsdc =
                      (walletInfo['gnosisUsdc'] as num).toStringAsFixed(2);
                  final String gnosisXdai =
                      (walletInfo['gnosisXdai'] as num).toStringAsFixed(2);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ligne avec l'adresse tronquée
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                truncated,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Ligne avec l'icône USDC et sa valeur
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/usdc.png',
                              width: 16 + appState.getTextSizeOffset(),
                              height: 16 + appState.getTextSizeOffset(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              gnosisUsdc,
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Ligne avec l'icône XDAI et sa valeur
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/xdai.png',
                              width: 18 + appState.getTextSizeOffset(),
                              height: 18 + appState.getTextSizeOffset(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              gnosisXdai,
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
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
