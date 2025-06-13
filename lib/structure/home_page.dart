import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/modals/agenda.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'dart:math';

import 'bottom_bar.dart';
import 'drawer.dart';
import 'package:realtoken_asset_tracker/pages/dashboard/dashboard_page.dart';
import 'package:realtoken_asset_tracker/pages/portfolio/portfolio_page.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/stats_selector_page.dart';
import 'package:realtoken_asset_tracker/pages/maps_page.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/components/donation_card_widget.dart';
import 'package:realtoken_asset_tracker/services/api_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final GlobalKey _walletIconKey = GlobalKey(); // Clé pour obtenir la position de l'icône

  List<Map<String, dynamic>> portfolio = [];

  bool _donationPopupShown = false;

  @override
  void initState() {
    super.initState();
    final random = Random();

    // Ajout de la condition de probabilité
    if (random.nextInt(3) == 0) { // Génère 0, 1, ou 2. La condition est vraie pour 0 (1/3 des cas)
      final delaySeconds = 5 + random.nextInt(26); // 5 à 30 inclus
      Future.delayed(Duration(seconds: delaySeconds), _showDonationPopupIfNeeded);
    }
  }

  void _showDonationPopupIfNeeded() async {
    if (_donationPopupShown) return;
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.shouldShowDonationPopup) return;
    _donationPopupShown = true;
    
    // Mettre à jour le timestamp de la dernière popup affichée
    await appState.updateLastDonationPopupTimestamp();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DonationPopupAsyncLoader();
      },
    );
  }

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
    final List<Map<String, dynamic>> walletDetails = dataManager.perWalletBalances ?? [];

    // Vérifie s'il y a au moins un wallet avec du staking
    final bool hasStaking = walletDetails.any((wallet) => (wallet['gnosisVaultReg'] ?? 0) > 0);

    // Affichage dans la console pour debug
    for (var walletInfo in walletDetails) {
      debugPrint("Wallet ${walletInfo['address']} → USDC Deposit: ${walletInfo['usdcDeposit']}, USDC Borrow: ${walletInfo['usdcBorrow']}, "
          "XDAI Deposit: ${walletInfo['xdaiDeposit']}, XDAI Borrow: ${walletInfo['xdaiBorrow']}, "
          "Gnosis USDC: ${walletInfo['gnosisUsdc']}, Gnosis XDAI: ${walletInfo['gnosisXdai']}, "
          "Gnosis REG: ${walletInfo['gnosisReg'] + walletInfo['gnosisVaultReg']}, "
          "Timestamp: ${walletInfo['timestamp']}");
    }

    // Fonction locale pour tronquer l'adresse
    String truncateAddress(String address) {
      if (address.length <= 12) return address;
      return address.substring(0, 6) + "..." + address.substring(address.length - 4);
    }

    final double usdcBalance = dataManager.gnosisUsdcBalance;
    final double xdaiBalance = dataManager.gnosisXdaiBalance;
    final double regBalance = dataManager.gnosisRegBalance;
    final double regVaultBalance = dataManager.gnosisVaultRegBalance;

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
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
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
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
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
                      S.of(context).wallet,
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
                      S.of(context).totalBalance,
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
                      // REG
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/reg.png',
                              width: 28 + appState.getTextSizeOffset(),
                              height: 28 + appState.getTextSizeOffset(),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "REG",
                                  style: TextStyle(
                                    fontSize: 12 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      (regBalance + regVaultBalance).toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 16 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    if (hasStaking)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          Icons.savings,
                                          size: 16 + appState.getTextSizeOffset(),
                                          color: Theme.of(context).primaryColor,
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
                  ],
                ),
              ),

              // Détails par wallet
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.of(context).walletDetails,
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
                    final double gnosisReg = walletInfo['gnosisReg'];
                    final double gnosisVaultReg = walletInfo['gnosisVaultReg'];
                    final String gnosisRegTotal = (gnosisReg + gnosisVaultReg).toStringAsFixed(2);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
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
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/reg.png',
                                      width: 20 + appState.getTextSizeOffset(),
                                      height: 20 + appState.getTextSizeOffset(),
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "REG",
                                          style: TextStyle(
                                            fontSize: 10 + appState.getTextSizeOffset(),
                                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              gnosisRegTotal,
                                              style: TextStyle(
                                                fontSize: 14 + appState.getTextSizeOffset(),
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            if (gnosisVaultReg > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4.0),
                                                child: Icon(
                                                  Icons.savings,
                                                  size: 14 + appState.getTextSizeOffset(),
                                                  color: Theme.of(context).primaryColor,
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
                            const SizedBox(height: 8),
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

    final double walletTotal = dataManager.gnosisUsdcBalance + dataManager.gnosisXdaiBalance;

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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0.5,
                    actions: [
                      // Icône portefeuille avec un Popup Menu
                      IconButton(
                        key: _walletIconKey, // Associe la clé pour obtenir la position
                        icon: Icon(
                          Icons.account_balance_wallet,
                          size: 21 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => _showWalletPopup(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: InkWell(
                          onTap: () => _showWalletPopup(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            child: Center(
                              child: Text(
                                currencyUtils.getFormattedAmount(
                                  currencyUtils.convert(walletTotal),
                                  currencyUtils.currencySymbol,
                                  appState.showAmounts, // Utilisation de showAmounts
                                ),
                                style: TextStyle(
                                  fontSize: 16 + appState.getTextSizeOffset(),
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
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
                          appState.showAmounts ? Icons.visibility : Icons.visibility_off,
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
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

// Widget interne pour gérer le chargement asynchrone du montant du wallet
class _DonationPopupAsyncLoader extends StatefulWidget {
  @override
  State<_DonationPopupAsyncLoader> createState() => _DonationPopupAsyncLoaderState();
}

class _DonationPopupAsyncLoaderState extends State<_DonationPopupAsyncLoader> {
  String? montant;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletAmount();
  }

  Future<void> _fetchWalletAmount() async {
    const walletAddress = '0xdc30b07aebaef3f15544a3801c6cb0f35f0118fc';
    try {
      // Appel direct à ApiService.fetchRmmBalances pour une seule adresse
      final balances = await ApiService.fetchRmmBalancesForAddress(walletAddress);
      if (balances.isNotEmpty) {
        final wallet = balances.first;
        print('DEBUG WALLET DON: ' + wallet.toString());
        final double gnosisUsdc = wallet['gnosisUsdcBalance'] ?? 0.0;
        final double gnosisXdai = wallet['gnosisXdaiBalance'] ?? 0.0;
        final double usdcDeposit = wallet['usdcDepositBalance'] ?? 0.0;
        final double xdaiDeposit = wallet['xdaiDepositBalance'] ?? 0.0;
        final double total = gnosisUsdc + gnosisXdai + usdcDeposit + xdaiDeposit;
        setState(() {
          montant = total.toStringAsFixed(2);
          isLoading = false;
        });
      } else {
        setState(() {
          montant = '0.00';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        montant = 'Erreur';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: DonationCardWidget(
                  montantWallet: montant,
                  isLoading: isLoading,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded, 
                    size: 28,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Fermer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
