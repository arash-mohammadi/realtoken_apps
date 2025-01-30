import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/api/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/utils.dart';

Widget buildFinanceTab(BuildContext context, Map<String, dynamic> token, bool convertToSquareMeters) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);

  // Calculate the total costs
  double totalCosts = (token['realtListingFee']?.toDouble() ?? 0.0) +
      (token['initialMaintenanceReserve']?.toDouble() ?? 0.0) +
      (token['renovationReserve']?.toDouble() ?? 0.0) +
      (token['miscellaneousCosts']?.toDouble() ?? 0.0);

  double totalRentCosts = (token['propertyMaintenanceMonthly']?.toDouble() ?? 0.0) +
      (token['propertyManagement']?.toDouble() ?? 0.0) +
      (token['realtPlatform']?.toDouble() ?? 0.0) +
      (token['insurance']?.toDouble() ?? 0.0) +
      (token['propertyTaxes']?.toDouble() ?? 0.0);

  // Contrôle de la visibilité des détails
  final ValueNotifier<bool> showDetailsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showRentDetailsNotifier = ValueNotifier<bool>(false);

  return SingleChildScrollView(
    child: Column(
      children: [
        _buildDetailRow(context, S.of(context).totalInvestment,
            Utils.formatCurrency(dataManager.convert(token['totalInvestment']), dataManager.currencySymbol),
            icon: Icons.monetization_on),

        // Section des dépenses totales
        GestureDetector(
          onTap: () => showDetailsNotifier.value = !showDetailsNotifier.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    S.of(context).totalExpenses,
                    style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: showDetailsNotifier,
                    builder: (context, showDetails, child) {
                      return Icon(
                        showDetails ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      );
                    },
                  ),
                ],
              ),
              Text(
                Utils.formatCurrency(dataManager.convert(token['totalInvestment'] - token['underlyingAssetPrice']),
                    dataManager.currencySymbol),
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Détails des dépenses
        ValueListenableBuilder<bool>(
          valueListenable: showDetailsNotifier,
          builder: (context, showDetails, child) {
            return Visibility(
              visible: showDetails,
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    S.of(context).realtListingFee,
                    Utils.formatCurrency(dataManager.convert(token['realtListingFee'] ?? 0), dataManager.currencySymbol),
                    isNegative: true,
                    color: Colors.red,
                  ),
                  _buildDetailRow(
                    context,
                    S.of(context).initialMaintenanceReserve,
                    Utils.formatCurrency(dataManager.convert(token['initialMaintenanceReserve'] ?? 0), dataManager.currencySymbol),
                    isNegative: true,
                    color: Colors.orange,
                  ),
                  _buildDetailRow(
                    context,
                    S.of(context).renovationReserve,
                    Utils.formatCurrency(dataManager.convert(token['renovationReserve'] ?? 0), dataManager.currencySymbol),
                    isNegative: true,
                    color: Colors.purple,
                  ),
                  _buildDetailRow(
                    context,
                    S.of(context).miscellaneousCosts,
                    Utils.formatCurrency(dataManager.convert(token['miscellaneousCosts'] ?? 0), dataManager.currencySymbol),
                    isNegative: true,
                    color: Colors.amber,
                  ),
                  _buildDetailRow(
                    context,
                    S.of(context).others,
                    Utils.formatCurrency(dataManager.convert((token['totalInvestment'] - token['underlyingAssetPrice'] - totalCosts) ?? 0),
                        dataManager.currencySymbol),
                    isNegative: true,
                    color: Colors.grey,
                  ),
                ],
              ),
            );
          },
        ),

        // Jauge de répartition des coûts
        Row(
          children: totalCosts > 0
              ? [
                  Expanded(
                    flex: ((token['realtListingFee'] ?? 0) / totalCosts * 100).round(),
                    child: Container(
                      height: 10,
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    flex: ((token['initialMaintenanceReserve'] ?? 0) / totalCosts * 100).round(),
                    child: Container(
                      height: 10,
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    flex: ((token['renovationReserve'] ?? 0) / totalCosts * 100).round(),
                    child: Container(
                      height: 10,
                      color: Colors.purple,
                    ),
                  ),
                  Expanded(
                    flex: ((token['miscellaneousCosts'] ?? 0) / totalCosts * 100).round(),
                    child: Container(
                      height: 10,
                      color: Colors.amber,
                    ),
                  ),
                  Expanded(
                    flex: (((token['totalInvestment'] ?? 0) - (token['underlyingAssetPrice'] ?? 0) - totalCosts) / totalCosts * 100).round(),
                    child: Container(
                      height: 10,
                      color: Colors.grey,
                    ),
                  ),
                ]
              : [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
        ),

        const SizedBox(height: 2),
        _buildDetailRow(context, S.of(context).underlyingAssetPrice,
            Utils.formatCurrency(dataManager.convert(token['underlyingAssetPrice'] ?? 0), dataManager.currencySymbol)),
        const SizedBox(height: 2),

        const Divider(),

        // Section des loyers
        _buildDetailRow(context, S.of(context).grossRentMonth,
            Utils.formatCurrency(dataManager.convert(token['grossRentMonth'] ?? 0), dataManager.currencySymbol),
            icon: Icons.attach_money),

        // Détails des dépenses de loyer
        GestureDetector(
          onTap: () => showRentDetailsNotifier.value = !showRentDetailsNotifier.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    S.of(context).totalExpenses,
                    style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: showRentDetailsNotifier,
                    builder: (context, showDetails, child) {
                      return Icon(
                        showDetails ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      );
                    },
                  ),
                ],
              ),
              Text(
                '- ${Utils.formatCurrency(dataManager.convert(token['grossRentMonth'] - token['netRentMonth']), dataManager.currencySymbol)}',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        // Détails des dépenses de loyer
        ValueListenableBuilder<bool>(
          valueListenable: showRentDetailsNotifier,
          builder: (context, showDetails, child) {
            return Visibility(
              visible: showDetails,
              child: Column(
                children: [
                  _buildDetailRow(context, S.of(context).propertyMaintenanceMonthly,
                      Utils.formatCurrency(dataManager.convert(token['propertyMaintenanceMonthly'] ?? 0), dataManager.currencySymbol),
                      isNegative: true, color: Colors.deepOrange),
                  _buildDetailRow(context, S.of(context).propertyManagement,
                      Utils.formatCurrency(dataManager.convert(token['propertyManagement'] ?? 0), dataManager.currencySymbol),
                      isNegative: true, color: Colors.amber),
                  _buildDetailRow(context, S.of(context).realtPlatform,
                      Utils.formatCurrency(dataManager.convert(token['realtPlatform'] ?? 0), dataManager.currencySymbol),
                      isNegative: true, color: Colors.orange),
                  _buildDetailRow(context, S.of(context).insurance,
                      Utils.formatCurrency(dataManager.convert(token['insurance'] ?? 0), dataManager.currencySymbol),
                      isNegative: true, color: Colors.purple),
                  _buildDetailRow(context, S.of(context).propertyTaxes,
                      Utils.formatCurrency(dataManager.convert(token['propertyTaxes'] ?? 0), dataManager.currencySymbol),
                      isNegative: true, color: Colors.red),
                  _buildDetailRow(
                      context,
                      S.of(context).others,
                      Utils.formatCurrency((dataManager.convert(token['grossRentMonth'] - token['netRentMonth'] - totalRentCosts) ?? 0),
                          dataManager.currencySymbol),
                      isNegative: true,
                      color: Colors.grey),
                ],
              ),
            );
          },
        ),

        // Jauge de répartition des coûts de loyer
        Row(
          children: [
            Expanded(
              flex: totalRentCosts != 0 ? ((token['propertyMaintenanceMonthly'] ?? 0) / totalRentCosts * 100).round() : 0,
              child: Container(
                height: 10,
                color: Colors.deepOrange,
              ),
            ),
            Expanded(
              flex: totalRentCosts != 0 ? ((token['propertyManagement'] ?? 0) / totalRentCosts * 100).round() : 0,
              child: Container(
                height: 10,
                color: Colors.amber,
              ),
            ),
            Expanded(
              flex: totalRentCosts != 0 ? ((token['realtPlatform'] ?? 0) / totalRentCosts * 100).round() : 0,
              child: Container(
                height: 10,
                color: Colors.orange,
              ),
            ),
            Expanded(
              flex: totalRentCosts != 0 ? ((token['insurance'] ?? 0) / totalRentCosts * 100).round() : 0,
              child: Container(
                height: 10,
                color: Colors.purple,
              ),
            ),
            Expanded(
              flex: totalRentCosts != 0 ? ((token['propertyTaxes'] ?? 0) / totalRentCosts * 100).round() : 0,
              child: Container(
                height: 10,
                color: Colors.red,
              ),
            ),
            Expanded(
              flex: totalRentCosts != 0
                  ? (((token['grossRentMonth'] ?? 0.0) - (token['netRentMonth'] ?? 0.0) - totalRentCosts) / totalRentCosts * 100).round()
                  : 0,
              child: Container(
                height: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),
        _buildDetailRow(context, S.of(context).netRentMonth,
            Utils.formatCurrency(dataManager.convert(token['netRentMonth'] ?? 0), dataManager.currencySymbol)),
        const SizedBox(height: 2),

        const Divider(),

        // Section du prix initial
        _buildDetailRow(
          context,
          S.of(context).initialPrice,
          Utils.formatCurrency(dataManager.convert(token['initPrice']), dataManager.currencySymbol),
          icon: Icons.price_change_sharp,
          trailing: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.edit, color: Colors.grey, size: 16 + appState.getTextSizeOffset()),
            onPressed: () {
              _showEditPriceBottomModal(context, token, dataManager);
            },
          ),
        ),
         _buildDetailRow(
          context,
          S.of(context).realtActualPrice,
          Utils.formatCurrency(dataManager.convert(token['tokenPrice']), dataManager.currencySymbol),
          icon: Icons.price_change_sharp,
        ),

        // Section YAM
        Row(children: [
          Icon(Icons.price_change_sharp, size: 18, color: Colors.blueGrey),
          Text('  YAM ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 + appState.getTextSizeOffset())),
          Spacer(),
          Text(
            '${Utils.formatCurrency(dataManager.convert((token['yamAverageValue'])), dataManager.currencySymbol)} (${((token['yamAverageValue'] / token['initPrice'] - 1) * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
              color: (token['yamAverageValue'] * token['amount']) > token['totalValue'] ? Colors.green : Colors.red,
            ),
          )
        ]),
        _buildDetailRow(
          context,
          S.of(context).annualPercentageYield,
          '${token['annualPercentageYield']?.toStringAsFixed(2) ?? S.of(context).notSpecified} %',
          icon: Icons.percent,
        ),
        _buildDetailRow(
          context,
          S.of(context).totalRentReceived,
          Utils.formatCurrency(dataManager.convert(token['totalRentReceived'] ?? 0), dataManager.currencySymbol),
          icon: Icons.receipt_long,
        ),
        _buildDetailRow(
          context,
          S.of(context).roiPerProperties,
          "${(token['totalRentReceived'] / token['initialTotalValue'] * 100).toStringAsFixed(2)} %",
          icon: Icons.show_chart,
          color: Colors.blue,
        ),
      ],
    ),
  );
}

// Méthode pour construire une ligne de détail
Widget _buildDetailRow(BuildContext context, String label, String value, {IconData? icon, bool isNegative = false, Color? color, Widget? trailing}) {
  final appState = Provider.of<AppState>(context, listen: false);

  final displayValue = isNegative ? '-$value' : value;
  final valueStyle = TextStyle(
    fontSize: 13 + appState.getTextSizeOffset(),
    color: isNegative ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 18, color: Colors.blueGrey),
            if (isNegative)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: color ?? Colors.red,
                ),
              ),
            SizedBox(width: icon != null || isNegative ? 8 : 0),
            Text(
              label,
              style: TextStyle(
                fontWeight: isNegative ? FontWeight.normal : FontWeight.bold,
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
            SizedBox(
              height: 16 + appState.getTextSizeOffset(),
              child: trailing ?? SizedBox(),
            ),
          ],
        ),
        Row(
          children: [
            Text(displayValue, style: valueStyle),
          ],
        ),
      ],
    ),
  );
}

// Méthode pour afficher le BottomModal de modification du prix
void _showEditPriceBottomModal(BuildContext context, Map<String, dynamic> token, DataManager dataManager) {
  final TextEditingController priceController = TextEditingController(
    text: token['initPrice']?.toString() ?? '0.00',
  );

  showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Text(
              S.of(context).initialPrice,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8), // Espacement entre le titre et la description
            // Description
            Text(
              S.of(context).initialPriceModified_description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16), // Espacement entre la description et le champ de texte
            // Champ de texte
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.of(context).enterValidNumber,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16), // Espacement entre le champ de texte et les boutons
            // Boutons avec icônes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Bouton pour sauvegarder avec une icône de validation
                IconButton(
                  onPressed: () {
                    final newPrice = double.tryParse(priceController.text);
                    if (newPrice != null) {
                      dataManager.setCustomInitPrice(token['uuid'], newPrice);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).initialPriceUpdated)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).enterValidNumber)),
                      );
                    }
                  },
                  icon: Icon(Icons.check, color: Colors.green), // Icône de validation
                  tooltip: S.of(context).save, // Texte d'aide au survol
                ),
                // Bouton pour supprimer avec une icône de suppression
                IconButton(
                  onPressed: () {
                    dataManager.removeCustomInitPrice(token['uuid']);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).initialPriceRemoved)),
                    );
                  },
                  icon: Icon(Icons.delete, color: Colors.red), // Icône de suppression
                  tooltip: 'delete', // Texte d'aide au survol
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
}