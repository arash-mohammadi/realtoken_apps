import 'package:flutter/material.dart';
import 'package:realtokens/pages/Statistics/rmm/rmm_stats.dart';
import 'package:realtokens/pages/Statistics/portfolio/portfolio_stats.dart';
import 'package:realtokens/pages/Statistics/wallet/wallet_stats.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  StatsSelectorPageState createState() => StatsSelectorPageState();
}

class StatsSelectorPageState extends State<StatsSelectorPage> {
  String _selectedStats = 'WalletStats';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: UIUtils.getSliverAppBarHeight(context) + 50,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: _buildStatsSelector(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.2, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _getSelectedStatsPage(),
        ),
      ),
    );
  }

  Widget _buildStatsSelector() {
    return Row(
      children: [
        _buildStatsChip('WalletStats', 'Wallet'),
        _buildStatsChip('PortfolioStats', 'Portfolio'),
        _buildStatsChip('RMMStats', 'RMM'),
      ],
    );
  }

  Widget _buildStatsChip(String value, String label) {
    final appState = Provider.of<AppState>(context);
    bool isSelected = _selectedStats == value;

    return Expanded(
      flex: isSelected ? 3 : 1,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStats = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: isSelected ? 18 + appState.getTextSizeOffset() : 16 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            child: Center(
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getSelectedStatsPage() {
    switch (_selectedStats) {
      case 'WalletStats':
        return const WalletStats(key: ValueKey('WalletStats'));
      case 'PortfolioStats':
        return const PortfolioStats(key: ValueKey('PortfolioStats'));
      case 'RMMStats':
        return const RmmStats(key: ValueKey('RMMStats'));
      default:
        return const PortfolioStats(key: ValueKey('PortfolioStats'));
    }
  }
}
