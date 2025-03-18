import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';

class TokenDistributionByWalletCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByWalletCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByWalletCardState createState() =>
      _TokenDistributionByWalletCardState();
}

class _TokenDistributionByWalletCardState
    extends State<TokenDistributionByWalletCard> {
  int? _selectedIndexWallet;
  final ValueNotifier<int?> _selectedIndexNotifierWallet =
      ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistributionByWallet,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierWallet,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByWallet(
                              widget.dataManager, selectedIndex),
                          centerSpaceRadius: 70,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                PieTouchResponse? response) {
                              if (response != null &&
                                  response.touchedSection != null) {
                                final touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierWallet.value =
                                    touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifierWallet.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterTextByWallet(
                          widget.dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByWallet(widget.dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByWallet(
      DataManager dataManager, int? selectedIndex) {
    final appState = Provider.of<AppState>(context);
    
    // Créer une Map qui compte les tokens par wallet
    Map<String, int> walletTokenCounts = {};
    
    // Analyser les walletTokens pour compter les tokens dans chaque wallet
    for (var token in dataManager.walletTokens) {
      String walletAddress = token['wallet'] ?? 'Unknown';
      // Utiliser une version abrégée de l'adresse pour l'affichage
      String walletDisplayName = _formatWalletAddress(walletAddress);
      
      walletTokenCounts[walletDisplayName] = (walletTokenCounts[walletDisplayName] ?? 0) + 1;
    }
    
    // Calculer la somme totale des tokens dans tous les wallets
    int totalWalletTokens = walletTokenCounts.values.fold(0, (sum, count) => sum + count);
    
    // Trier les wallets par nombre de tokens (décroissant)
    final sortedWallets = walletTokenCounts.keys.toList()
      ..sort((a, b) => walletTokenCounts[b]!.compareTo(walletTokenCounts[a]!));

    // Créer les sections du graphique à secteurs
    return sortedWallets.asMap().entries.map((entry) {
      final index = entry.key;
      final wallet = entry.value;
      final int value = walletTokenCounts[wallet]!;
      final double percentage = (value / totalWalletTokens) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Générer une couleur basée sur l'index
      final Color baseColor = _generateWalletColor(index);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withOpacity(opacity),
        radius: isSelected ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: isSelected
              ? 14 + appState.getTextSizeOffset()
              : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildCenterTextByWallet(
      DataManager dataManager, int? selectedIndex) {
    Map<String, int> walletTokenCounts = {};
    
    // Analyser les walletTokens pour compter les tokens dans chaque wallet
    for (var token in dataManager.walletTokens) {
      String walletAddress = token['wallet'] ?? 'Unknown';
      String walletDisplayName = _formatWalletAddress(walletAddress);
      
      walletTokenCounts[walletDisplayName] = (walletTokenCounts[walletDisplayName] ?? 0) + 1;
    }
    
    // Calculer la somme totale des tokens dans tous les wallets
    int totalWalletTokens = walletTokenCounts.values.fold(0, (sum, count) => sum + count);

    if (selectedIndex == null) {
      // Afficher la valeur totale si aucun segment n'est sélectionné
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'total',
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            totalWalletTokens.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // Afficher les détails du segment sélectionné
    final sortedWallets = walletTokenCounts.keys.toList()
      ..sort((a, b) => walletTokenCounts[b]!.compareTo(walletTokenCounts[a]!));
    
    if (selectedIndex >= sortedWallets.length) return Container();
    
    final selectedWallet = sortedWallets[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedWallet,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          walletTokenCounts[selectedWallet].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendByWallet(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);
    
    // Créer une Map qui compte les tokens par wallet
    Map<String, int> walletTokenCounts = {};
    
    // Analyser les walletTokens pour compter les tokens dans chaque wallet
    for (var token in dataManager.walletTokens) {
      String walletAddress = token['wallet'] ?? 'Unknown';
      String walletDisplayName = _formatWalletAddress(walletAddress);
      
      walletTokenCounts[walletDisplayName] = (walletTokenCounts[walletDisplayName] ?? 0) + 1;
    }
    
    // Calculer la somme totale des tokens dans tous les wallets
    int totalWalletTokens = walletTokenCounts.values.fold(0, (sum, count) => sum + count);
    
    // Trier les wallets par nombre de tokens (décroissant)
    final sortedWallets = walletTokenCounts.keys.toList()
      ..sort((a, b) => walletTokenCounts[b]!.compareTo(walletTokenCounts[a]!));

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedWallets.map((wallet) {
        final int index = sortedWallets.indexOf(wallet);
        final color = _generateWalletColor(index);
        final count = walletTokenCounts[wallet];
        final percentage = (count! / totalWalletTokens) * 100;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$wallet (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Formater l'adresse du wallet pour l'affichage (ex: 0x1234...5678)
  String _formatWalletAddress(String address) {
    if (address.length <= 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  // Générer des couleurs basées sur l'index
  Color _generateWalletColor(int index) {
    final List<Color> baseColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    // Si nous avons plus de wallets que de couleurs de base, faisons tourner les couleurs mais ajustons légèrement
    if (index < baseColors.length) {
      return baseColors[index];
    } else {
      final baseColor = baseColors[index % baseColors.length];
      // Ajuster la teinte légèrement pour différencier
      return UIUtils.shadeColor(baseColor, 0.7 + (index / 20));
    }
  }
} 