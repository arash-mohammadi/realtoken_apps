import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RealtPage extends StatefulWidget {
  const RealtPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<RealtPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Accéder à DataManager pour récupérer les valeurs calculées
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: Center(
          child: Image.asset(
            'assets/RealT_Logo.png', // Chemin vers l'image dans assets
            height: 100, // Ajuster la taille de l'image
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              _buildCard(
                'investment', // Utilisation de S.of(context)
                Icons.attach_money,
                _buildValueBeforeText(
                  currencyUtils.formatCurrency(currencyUtils.convert(dataManager.totalRealtInvestment), currencyUtils.currencySymbol),
                  S.of(context).totalInvestment,
                ),
                [
                  _buildValueBeforeText(
                    currencyUtils.formatCurrency(currencyUtils.convert(dataManager.netRealtRentYear), currencyUtils.currencySymbol),
                    'net rent',
                  ),
                ],
                dataManager,
                context,
              ),
              const SizedBox(height: 15),
              _buildCard(
                S.of(context).properties, // Utilisation de S.of(context)
                Icons.home,
                _buildValueBeforeText(
                  '${dataManager.totalRealtTokens}',
                  S.of(context).tokens, // Utilisation de S.of(context)
                ),
                [
                  _buildValueBeforeText(
                    '${dataManager.totalRealtUnits}',
                    S.of(context).units, // Utilisation de S.of(context)
                  ),
                  _buildValueBeforeText(
                    '${dataManager.rentedRealtUnits}',
                    S.of(context).rentedUnits, // Utilisation de S.of(context)
                  ),
                  _buildValueBeforeText(
                    '${(dataManager.rentedRealtUnits / dataManager.totalRealtUnits * 100).toStringAsFixed(1)}%',
                    S.of(context).rented, // Utilisation de S.of(context)
                    color: Colors.green,
                  ),
                ],
                dataManager,
                context,
              ),
              const SizedBox(height: 15),
              _buildCard(
                S.of(context).realTPerformance, // Utilisation de S.of(context)
                Icons.trending_up,
                _buildValueBeforeText(
                  '${dataManager.averageRealtAnnualYield.toStringAsFixed(2)}%',
                  S.of(context).annualYield, // Utilisation de S.of(context)
                ),
                [
                  _buildValueBeforeText(
                    '',
                    S.of(context).annualYield, // Utilisation de S.of(context)
                  ),
                ],
                dataManager,
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour créer une carte similaire à DashboardPage
  Widget _buildCard(
    String title,
    IconData icon,
    Widget firstChild,
    List<Widget> otherChildren,
    DataManager dataManager,
    BuildContext context, {
    bool hasGraph = false,
    Widget? rightWidget, // Ajout du widget pour le graphique
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 24, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                firstChild,
                const SizedBox(height: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: otherChildren,
                ),
              ],
            ),
            const Spacer(),
            if (hasGraph && rightWidget != null) rightWidget, // Affiche le graphique si nécessaire
          ],
        ),
      ),
    );
  }

  // Construction d'une ligne pour afficher la valeur avant le texte
  Widget _buildValueBeforeText(String value, String text, {Color? color}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).textTheme.bodyMedium?.color, // Utilise la couleur fournie ou la couleur par défaut
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
