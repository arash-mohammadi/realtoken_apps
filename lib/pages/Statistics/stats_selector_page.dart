import 'package:flutter/material.dart';
import 'package:realtokens/pages/Statistics/rmm/rmm_stats.dart';
import 'package:realtokens/pages/Statistics/portfolio/portfolio_stats.dart';
import 'package:realtokens/pages/Statistics/wallet/wallet_stats.dart'; // Assurez-vous que cette page existe
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  StatsSelectorPageState createState() => StatsSelectorPageState();
}

class StatsSelectorPageState extends State<StatsSelectorPage> {
  String _selectedStats = 'WalletStats'; // Valeur par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: UIUtils.getSliverAppBarHeight(context) + 10,
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
    return Center(
      // Centrer horizontalement
      child: Wrap(
        spacing: 8.0, // Espacement entre les chips
        children: [
          _buildStatsChip('WalletStats', 'Wallet'),
          _buildStatsChip('PortfolioStats', 'Portfolio'),
          _buildStatsChip('RMMStats', 'RMM'),
        ],
      ),
    );
  }

  Widget _buildStatsChip(String value, String label) {
    final appState = Provider.of<AppState>(context);
    bool isSelected = _selectedStats == value;

    return ActionChip(
      // Utilisation de ActionChip
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16 + appState.getTextSizeOffset(),
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: () {
        setState(() {
          _selectedStats = value;
        });
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Bords arrondis
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 80 : 5, // Agrandir davantage le chip sélectionné
        vertical: 5, // Augmenter la hauteur des chips
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
