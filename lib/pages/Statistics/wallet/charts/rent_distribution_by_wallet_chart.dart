import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/currency_utils.dart';

class RentDistributionByWalletChart extends StatefulWidget {
  final DataManager dataManager;

  const RentDistributionByWalletChart({super.key, required this.dataManager});

  @override
  _RentDistributionByWalletChartState createState() => _RentDistributionByWalletChartState();
}

class _RentDistributionByWalletChartState extends State<RentDistributionByWalletChart> {
  int? _selectedIndex;
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${S.of(context).rentDistribution} par portefeuille",
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildRentDonutChartData(selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifier.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterText(selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildRentLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildRentDonutChartData(int? selectedIndex) {
    // Obtenir les données de loyers par wallet
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();
    
    // Calculer le total des loyers
    final double totalRent = walletRentTotals.values.fold(0.0, (sum, value) => sum + value);
    
    // Trier les entrées par montant décroissant
    final sortedEntries = walletRentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Créer les sections du donut chart
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value / totalRent) * 100;
      
      final bool isSelected = selectedIndex == index;
      final double opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;
      
      return PieChartSectionData(
        value: data.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: _generateColor(index).withOpacity(opacity),
        radius: isSelected ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: isSelected
              ? 14 + Provider.of<AppState>(context).getTextSizeOffset()
              : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildCenterText(int? selectedIndex) {
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();
    final double totalRent = walletRentTotals.values.fold(0.0, (sum, value) => sum + value);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    
    if (selectedIndex == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).totalValue,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyUtils.getFormattedAmount(
                currencyUtils.convert(totalRent),
                currencyUtils.currencySymbol,
                true),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
    
    final sortedEntries = walletRentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selectedEntry = sortedEntries[selectedIndex];
    
    // Raccourcir l'adresse du wallet pour l'affichage
    String displayWallet = _formatWalletAddress(selectedEntry.key);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayWallet,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          currencyUtils.getFormattedAmount(
              currencyUtils.convert(selectedEntry.value),
              currencyUtils.currencySymbol,
              true),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRentLegend() {
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();
    final appState = Provider.of<AppState>(context);
    
    final sortedEntries = walletRentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.map((entry) {
        final index = sortedEntries.indexOf(entry);
        final color = _generateColor(index);
        
        // Raccourcir l'adresse du wallet pour l'affichage
        String displayWallet = _formatWalletAddress(entry.key);
        
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
                  displayWallet,
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Méthode pour calculer le total des loyers par wallet
  Map<String, double> _calculateWalletRentTotals() {
    Map<String, double> result = {};
    
    // Obtenir les données de loyers par wallet depuis le DataManager
    Map<String, Map<String, double>> rentsByWallet = widget.dataManager.getRentsByWallet();
    
    // Calculer le total des loyers pour chaque wallet
    for (var walletEntry in rentsByWallet.entries) {
      String wallet = walletEntry.key;
      Map<String, double> tokenRents = walletEntry.value;
      
      // Somme des loyers pour tous les tokens de ce wallet
      double totalForWallet = tokenRents.values.fold(0.0, (sum, rent) => sum + rent);
      result[wallet] = totalForWallet;
    }
    
    return result;
  }

  // Méthode pour générer une couleur basée sur l'index
  Color _generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
  
  // Méthode pour formater l'adresse du wallet
  String _formatWalletAddress(String address) {
    if (address == 'unknown') return S.of(context).unknown;
    if (address.length <= 8) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
} 