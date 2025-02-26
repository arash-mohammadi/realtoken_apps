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
              expandedHeight: UIUtils.getSliverAppBarHeight(context) + 10,
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

  double textSizeOffset = appState.getTextSizeOffset();
  TextStyle textStyle = TextStyle(
    fontSize: (isSelected ? 18 : 16) + textSizeOffset,
    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  );

  double minWidth = _calculateTextWidth(context, label, textStyle);

  return isSelected
      ? Expanded( // La chip sélectionnée prend toute la place restante
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
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  style: textStyle.copyWith(color: Colors.white),
                  child: Text(label),
                ),
              ),
            ),
          ),
        )
      : ConstrainedBox( // Les chips non sélectionnées ont une largeur minimale
          constraints: BoxConstraints(minWidth: minWidth),
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  style: textStyle.copyWith(color: Theme.of(context).primaryColor),
                  child: Text(label),
                ),
              ),
            ),
          ),
        );
}
double _calculateTextWidth(BuildContext context, String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();

  return textPainter.width + 24; // Ajout de padding pour éviter que le texte touche les bords
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
