import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:realtokens_apps/pages/Statistics/rmm_stats.dart';
import 'package:realtokens_apps/pages/Statistics/portfolio_stats.dart';
import 'package:realtokens_apps/pages/Statistics/wallet_stats.dart'; // Assurez-vous que cette page existe
import 'package:provider/provider.dart';
import 'package:realtokens_apps/app_state.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  StatsSelectorPageState createState() => StatsSelectorPageState();
}

class StatsSelectorPageState extends State<StatsSelectorPage> {
  String _selectedStats = 'PortfolioStats'; // Valeur par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: Utils.getSliverAppBarHeight(context),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildStatsSelector(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _getSelectedStatsPage(), // Appelle une méthode pour obtenir la page sélectionnée
      ),
    );
  }

  Widget _buildStatsSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          _buildStatsButton('WalletStats', 'Wallet', isFirst: true), // Nouveau bouton
          _buildStatsButton('PortfolioStats', 'Portfolio' ),
          _buildStatsButton('RMMStats', 'RMM', isLast: true),
        ],
      ),
    );
  }

  Widget _buildStatsButton(String value, String label, {bool isFirst = false, bool isLast = false}) {
    bool isSelected = _selectedStats == value;
    final appState = Provider.of<AppState>(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStats = value;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Theme.of(context).cardColor,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _getSelectedStatsPage() {
    switch (_selectedStats) {
      case 'WalletStats':
        return const WalletStats(); // Affiche la page Wallet Stats
      case 'PortfolioStats':
        return const PortfolioStats();
      case 'RMMStats':
        return const RmmStats();
      default:
        return const PortfolioStats();
    }
  }
}
