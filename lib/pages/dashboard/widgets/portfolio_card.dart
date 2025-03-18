import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:shimmer/shimmer.dart';
import 'package:realtokens/settings/personalization_settings_page.dart';
import 'package:realtokens/pages/dashboard/detailsPages/portfolio_details_page.dart';

class PortfolioCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;
  final BuildContext context;

  const PortfolioCard({
    super.key,
    required this.showAmounts,
    required this.isLoading,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);
    
    // Calcul des totaux en tenant compte des paramètres
    double totalPortfolioValue = dataManager.totalWalletValue + Parameters.manualAdjustment;
    
    // Calcul du total sans les dépôts et emprunts si showNetTotal est false
    double portfolioDisplayValue = Parameters.showNetTotal 
        ? dataManager.yamTotalValue +
          dataManager.rwaHoldingsValue +
          dataManager.totalUsdcDepositBalance +
          dataManager.totalXdaiDepositBalance -
          dataManager.totalUsdcBorrowBalance -
          dataManager.totalXdaiBorrowBalance +
          Parameters.manualAdjustment
        : dataManager.yamTotalValue +
          dataManager.rwaHoldingsValue +
          Parameters.manualAdjustment;

    // Calcul du pourcentage de rendement par rapport à l'investissement total
    double percentageYam = ((portfolioDisplayValue / totalPortfolioValue - 1) * 100);
    String percentageYamDisplay = percentageYam.isNaN || percentageYam.isInfinite ? '0' : percentageYam.toStringAsFixed(0);

    return UIUtils.buildCard(
      S.of(context).portfolio,
      Icons.dashboard,
      Parameters.showYamProjection 
        ? UIUtils.buildValueBeforeText(
            context,
            currencyUtils.getFormattedAmount(
                currencyUtils.convert(portfolioDisplayValue),
                currencyUtils.currencySymbol,
                showAmounts),
            'projection YAM ($percentageYamDisplay%)',
            isLoading,
            highlightPercentage: true,
          )
        : const SizedBox.shrink(),
      [
        // Section des totaux - mise en évidence avec un style particulier
        _buildSectionTitle(context, S.of(context).totalPortfolio, theme),
        _buildTotalValue(
            context,
            currencyUtils.getFormattedAmount(
                currencyUtils.convert(totalPortfolioValue),
                currencyUtils.currencySymbol,
                showAmounts),
            isLoading,
            theme),
            
        // Ajout du total investi si l'option est activée
        if (Parameters.showTotalInvested)
          _buildSubtotalValue(
              context,
              currencyUtils.getFormattedAmount(
                  currencyUtils.convert(dataManager.initialTotalValue),
                  currencyUtils.currencySymbol,
                  showAmounts),
              S.of(context).initialInvestment,
              isLoading,
              theme),
              
        const SizedBox(height: 2), // Espace réduit entre les sections
        
        // Section des actifs - avec titre de section
        _buildSectionTitle(context, "Actifs", theme),
        _buildIndentedBalance(
            S.of(context).wallet,
            currencyUtils.convert(dataManager.walletValue),
            currencyUtils.currencySymbol,
            true,
            context,
            isLoading),
        _buildIndentedBalance(
            S.of(context).rmm,
            currencyUtils.convert(dataManager.rmmValue),
            currencyUtils.currencySymbol,
            true,
            context,
            isLoading),
        _buildIndentedBalance(
            S.of(context).rwaHoldings,
            currencyUtils.convert(dataManager.rwaHoldingsValue),
            currencyUtils.currencySymbol,
            true,
            context,
            isLoading),
            
        if (Parameters.showNetTotal) ...[
          const SizedBox(height: 2), // Espace réduit entre les sections
          // Section des dépôts et emprunts - avec titre de section
          _buildSectionTitle(context, "Dépôts & Emprunts", theme),
          _buildIndentedBalance(
              S.of(context).depositBalance,
              currencyUtils.convert(dataManager.totalUsdcDepositBalance +
                  dataManager.totalXdaiDepositBalance),
              currencyUtils.currencySymbol,
              true,
              context,
              isLoading),
          _buildIndentedBalance(
              S.of(context).borrowBalance,
              currencyUtils.convert(dataManager.totalUsdcBorrowBalance +
                  dataManager.totalXdaiBorrowBalance),
              currencyUtils.currencySymbol,
              false,
              context,
              isLoading),
        ],
        
        // Affichage de l'ajustement manuel si différent de zéro
        if (Parameters.manualAdjustment != 0) ...[
          const SizedBox(height: 2), // Espace réduit entre les sections
          _buildSectionTitle(context, "Ajustements", theme),
          _buildIndentedBalance(
              S.of(context).manualAdjustment,
              currencyUtils.convert(Parameters.manualAdjustment),
              currencyUtils.currencySymbol,
              Parameters.manualAdjustment > 0,
              context,
              isLoading),
        ],
      ],
      dataManager,
      context,
      hasGraph: true,
      rightWidget: _buildVerticalGauge(dataManager.roiGlobalValue, context),
      headerRightWidget: Row(
        children: [
          _buildSettingsIcon(context),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              size: 24,
              color: Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PortfolioDetailsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsIcon(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2.0),
      child: IconButton(
        icon: Icon(
          Icons.settings,
          size: 18,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        onPressed: () {
          _showPersonalizationModal(context);
        },
      ),
    );
  }

  void _showPersonalizationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: Theme.of(context).appBarTheme.backgroundColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Personnalisation",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Expanded(
                child: PersonalizationSettingsPage(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 1.0, bottom: 1.0), // Espacement vertical réduit
      child: Row(
        children: [
          Container(
            height: 12, // Hauteur réduite
            width: 3,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6), // Espacement horizontal réduit
          Text(
            title,
            style: TextStyle(
              fontSize: 11, // Taille de police légèrement réduite
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalValue(BuildContext context, String formattedAmount, bool isLoading, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 0.5, bottom: 0.5), // Espacement vertical réduit
      child: isLoading
          ? Shimmer.fromColors(
              baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
              highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!,
              child: Container(
                width: 120,
                height: 24,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
              ),
            )
          : Text(
              formattedAmount,
              style: TextStyle(
                fontSize: 16, // Taille de police légèrement réduite
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
    );
  }

  Widget _buildSubtotalValue(BuildContext context, String formattedAmount, String label, bool isLoading, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 0.5, bottom: 0.5), // Espacement vertical réduit
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                  highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                  ),
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 13, // Taille de police légèrement réduite
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndentedBalance(String label, double value, String symbol,
      bool isPositive, BuildContext context, bool isLoading) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    String formattedAmount = showAmounts
        ? (isPositive
            ? "+ ${currencyUtils.formatCurrency(value, symbol)}"
            : "- ${currencyUtils.formatCurrency(value, symbol)}")
        : (isPositive ? "+ " : "- ") + ('*' * 10);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 0.0, bottom: 0.0), // Espacement vertical minimal
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor:
                      theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ??
                          Colors.grey[300]!,
                  highlightColor:
                      theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                          Colors.grey[100]!,
                  child: Container(
                    width: 60,
                    height: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                  ),
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 12, // Taille de police légèrement réduite
                    fontWeight: FontWeight.w500,
                    color: isPositive 
                        ? theme.primaryColor.withOpacity(0.8)
                        : Colors.redAccent.withOpacity(0.8),
                  ),
                ),
          const SizedBox(width: 6), // Espacement horizontal réduit
          Text(
            label,
            style: TextStyle(
              fontSize: 10 + appState.getTextSizeOffset(), // Taille de police réduite
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalGauge(double value, BuildContext context) {
    // Récupérer directement du DataManager pour les calculs
    final dataManager = Provider.of<DataManager>(context, listen: false);
    
    // Utiliser la méthode d'origine qui calcule le ROI basé sur les loyers reçus
    // ROI = (Total des loyers reçus / Investissement initial) * 100
    double totalRentReceived = dataManager.getTotalRentReceived();
    double initialInvestment = dataManager.initialTotalValue;
    
    // Vérifier si l'investissement initial est valide pour éviter la division par zéro
    double displayValue = 0.0;
    if (initialInvestment > 0) {
      displayValue = (totalRentReceived / initialInvestment) * 100;
      
      // S'assurer que le ROI n'est jamais négatif
      displayValue = displayValue < 0 ? 0.0 : displayValue;
    }
    
    // Debug - afficher les valeurs utilisées pour le calcul
    print("Total Rent Received: $totalRentReceived, Initial Investment: $initialInvestment, ROI: $displayValue%");
    
    // S'assurer que la valeur est valide
    displayValue = displayValue.isNaN || displayValue.isInfinite ? 0.0 : displayValue;
    
    // Pourcentage limité entre 0% et 100% pour l'affichage (mais on peut avoir un ROI > 100%)
    double progress = (displayValue / 100).clamp(0.0, 1.0);

    // Calculer la couleur en fonction de la progression (rouge pour 0%, vert pour 100%)
    Color progressColor = Color.lerp(
      Colors.red, 
      Colors.green, 
      progress
    )!;

    return SizedBox(
      width: 90,
      height: 140, // Hauteur harmonisée avec les jauges RMM
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ROI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(S.of(context).roiPerProperties),
                        content: Text(S.of(context).roiAlertInfo),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 20,
                height: 100, // Même hauteur que les jauges RMM
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 20,
                height: progress * 100, // Hauteur proportionnelle à la valeur
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            displayValue > 3650 ? "∞" : "${displayValue.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
