import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/ui_utils.dart';

class TokensCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const TokensCard(
      {super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    double rentedPercentage =
        dataManager.walletTokensSums / dataManager.totalTokens * 100;
    if (rentedPercentage.isNaN || rentedPercentage < 0) {
      rentedPercentage = 0;
    }

    return Stack(
      children: [
        UIUtils.buildCard(
          S.of(context).tokens,
          Icons.token_outlined,
          UIUtils.buildValueBeforeText(
              context,
              dataManager.totalTokens.toStringAsFixed(2) as String?,
              S.of(context).totalTokens,
              isLoading || dataManager.isLoadingMain),
          [
            UIUtils.buildTextWithShimmer(
              dataManager.walletTokensSums.toStringAsFixed(2),
              S.of(context).wallet,
              isLoading || dataManager.isLoadingMain,
              context,
            ),
            UIUtils.buildTextWithShimmer(
              dataManager.rmmTokensSums.toStringAsFixed(2),
              S.of(context).rmm,
              isLoading || dataManager.isLoadingMain,
              context,
            ),
          ],
          dataManager,
          context,
          hasGraph: false, // Ne pas utiliser le graphique dans la carte
        ),
        Positioned(
          top: 30, // Position négative pour remonter le donut
          right: 12, // Alignement à droite
          child: _buildPieChart(rentedPercentage, context),
        ),
      ],
    );
  }

  Widget _buildPieChart(double rentedPercentage, BuildContext context) {
    return SizedBox(
      width: 120, // Largeur du camembert
      height: 90, // Hauteur du camembert
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90, // Pour placer la petite section en haut
          sections: [
            PieChartSectionData(
              value: rentedPercentage,
              color: Colors.green, // Couleur pour les unités louées
              title: '',
              radius: 23, // Taille de la section louée
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              gradient: LinearGradient(
                colors: [Colors.green.shade300, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            PieChartSectionData(
              value: 100 - rentedPercentage,
              color: Theme.of(context)
                  .primaryColor, // Couleur pour les unités non louées
              title: '',
              radius: 17, // Taille de la section non louée
              gradient: LinearGradient(
                colors: [
                  Theme.of(context)
                      .primaryColor
                      .withOpacity(0.6), // Remplace Colors.blue.shade300
                  Theme.of(context)
                      .primaryColor, // Remplace Colors.blue.shade700
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
          sectionsSpace:
              2, // Un léger espace entre les sections pour les démarquer
          centerSpaceRadius: 23, // Taille de l'espace central
        ),
        swapAnimationDuration:
            const Duration(milliseconds: 800), // Durée de l'animation
        swapAnimationCurve:
            Curves.easeInOut, // Courbe pour rendre l'animation fluide
      ),
    );
  }
}
