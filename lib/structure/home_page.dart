import 'package:flutter/material.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/structure/agenda.dart';
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
  List<Map<String, dynamic>> portfolio = []; // Ajoute une variable portfolio

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

    print(
        "📊 Portfolio avant d'ouvrir le modal : $portfolio"); // 🔍 Vérification

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            0.8, // Modal limité à 60% de la hauteur
      ),
      builder: (context) => AgendaCalendar(portfolio: portfolio),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
                      IconButton(
                        icon: Icon(Icons.calendar_today,
                            size: 20,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color),
                        onPressed: () => _openAgendaModal(context),
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
