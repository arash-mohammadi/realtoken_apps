import 'package:flutter/material.dart';
import 'package:realtokens/pages/Statistics/rmm/rmm_stats.dart';
import 'package:realtokens/pages/Statistics/portfolio/portfolio_stats.dart';
import 'package:realtokens/pages/Statistics/wallet/wallet_stats.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  StatsSelectorPageState createState() => StatsSelectorPageState();
}

class StatsSelectorPageState extends State<StatsSelectorPage> with TickerProviderStateMixin {
  String _selectedStats = 'WalletStats';
  String _previousSelectedStats = 'WalletStats';
  
  // Couleurs spécifiques pour chaque sélecteur
  final Map<String, Color> _statsColors = {
    'WalletStats': Colors.blue,
    'PortfolioStats': Colors.green,
    'RMMStats': Colors.orange,
  };

  // Contrôleurs d'animation pour chaque sélecteur
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _scaleAnimations = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Initialiser les contrôleurs d'animation pour chaque sélecteur
    for (String key in ['WalletStats', 'PortfolioStats', 'RMMStats']) {
      _animationControllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
        value: key == _selectedStats ? 1.0 : 0.0,
      );

      _scaleAnimations[key] = Tween<double>(
        begin: 0.95,  // Taille réduite
        end: 1.05,    // Taille augmentée
      ).animate(
        CurvedAnimation(
          parent: _animationControllers[key]!,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs d'animation
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateAnimations(String newValue) {
    _previousSelectedStats = _selectedStats;
    _selectedStats = newValue;

    // Animer la réduction du sélecteur qui devient inactif
    if (_animationControllers[_previousSelectedStats] != null) {
      _animationControllers[_previousSelectedStats]!.reverse();
    }

    // Animer l'agrandissement du sélecteur qui devient actif
    if (_animationControllers[newValue] != null) {
      _animationControllers[newValue]!.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewPadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: false,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: NestedScrollView(
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
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
        ),
      ),
    );
  }

  Widget _buildStatsSelector() {
    return Row(
      children: [
        _buildStatsChip('WalletStats', S.of(context).wallet, Icons.account_balance_wallet),
        _buildStatsChip('PortfolioStats', S.of(context).portfolio, Icons.business),
        _buildStatsChip('RMMStats', S.of(context).rmm, Icons.money),
      ],
    );
  }

  Widget _buildStatsChip(String value, String label, IconData icon) {
    final appState = Provider.of<AppState>(context);
    bool isSelected = _selectedStats == value;
    Color chipColor = _statsColors[value] ?? Theme.of(context).primaryColor;

    double textSizeOffset = appState.getTextSizeOffset();
    TextStyle textStyle = TextStyle(
      fontSize: (isSelected ? 18 : 16) + textSizeOffset,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );

    double minWidth = isSelected 
        ? _calculateTextWidth(context, label, textStyle) 
        : 56; // Largeur minimale pour les icônes non sélectionnées

    // Utiliser l'animation d'échelle si disponible
    Widget animatedContent = _scaleAnimations.containsKey(value) 
      ? AnimatedBuilder(
          animation: _scaleAnimations[value]!,
          builder: (context, child) {
            return Transform.scale(
              scale: isSelected ? _scaleAnimations[value]!.value : 1.0,
              child: child,
            );
          },
          child: isSelected
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    style: textStyle.copyWith(color: Colors.white),
                    child: Text(label),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  icon,
                  color: Colors.grey, // Icônes inactives en gris
                  size: 20,
                ),
              ),
        )
      : isSelected
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                style: textStyle.copyWith(color: Colors.white),
                child: Text(label),
              ),
            ],
          )
        : Center(
            child: Icon(
              icon,
              color: Colors.grey, // Icônes inactives en gris
              size: 20,
            ),
          );

    return isSelected
        ? Expanded(
            // La chip sélectionnée prend toute la place restante
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _updateAnimations(value);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: animatedContent,
              ),
            ),
          )
        : ConstrainedBox(
            // Les chips non sélectionnées ont une largeur minimale
            constraints: BoxConstraints(minWidth: minWidth),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _updateAnimations(value);
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: animatedContent,
              ),
            ),
          );
  }

  double _calculateTextWidth(
      BuildContext context, String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width +
        24; // Ajout de padding pour éviter que le texte touche les bords
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
