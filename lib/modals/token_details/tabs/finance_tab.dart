import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';

Widget buildFinanceTab(BuildContext context, Map<String, dynamic> token,
    bool convertToSquareMeters) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

  // Calculate the total costs
  double totalCosts = (token['realtListingFee']?.toDouble() ?? 0.0) +
      (token['initialMaintenanceReserve']?.toDouble() ?? 0.0) +
      (token['renovationReserve']?.toDouble() ?? 0.0) +
      (token['miscellaneousCosts']?.toDouble() ?? 0.0);

  double totalRentCosts =
      (token['propertyMaintenanceMonthly']?.toDouble() ?? 0.0) +
          (token['propertyManagement']?.toDouble() ?? 0.0) +
          (token['realtPlatform']?.toDouble() ?? 0.0) +
          (token['insurance']?.toDouble() ?? 0.0) +
          (token['propertyTaxes']?.toDouble() ?? 0.0);

  // Contrôle de la visibilité des détails
  final ValueNotifier<bool> showDetailsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showRentDetailsNotifier =
      ValueNotifier<bool>(false);

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    physics: const BouncingScrollPhysics(), // iOS-style scroll
    child: Column(
      children: [
        _buildCard(
          context,
          title: "Investissement",
          child: Column(
            children: [
              _buildDetailRow(
                context,
                S.of(context).totalInvestment,
                currencyUtils.formatCurrency(
                    currencyUtils.convert(token['totalInvestment']),
                    currencyUtils.currencySymbol),
                icon: Icons.monetization_on,
                iconColor: Colors.green,
              ),
              const Divider(height: 1, thickness: 0.5),

              // Section des dépenses totales
              GestureDetector(
                onTap: () => showDetailsNotifier.value = !showDetailsNotifier.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            S.of(context).totalExpenses,
                            style: TextStyle(
                                fontSize: 13 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          ValueListenableBuilder<bool>(
                            valueListenable: showDetailsNotifier,
                            builder: (context, showDetails, child) {
                              return Icon(
                                showDetails ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey,
                                size: 18 + appState.getTextSizeOffset(),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        currencyUtils.formatCurrency(
                            currencyUtils.convert(token['totalInvestment'] -
                                token['underlyingAssetPrice']),
                            currencyUtils.currencySymbol),
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              // Détails des dépenses
              ValueListenableBuilder<bool>(
                valueListenable: showDetailsNotifier,
                builder: (context, showDetails, child) {
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showDetails 
                      ? Column(
                        children: [
                          _buildDetailRow(
                            context,
                            S.of(context).realtListingFee,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(token['realtListingFee'] ?? 0),
                                currencyUtils.currencySymbol),
                            isNegative: true,
                            color: Colors.red,
                            iconColor: Colors.red.shade300,
                          ),
                          _buildDetailRow(
                            context,
                            S.of(context).initialMaintenanceReserve,
                            currencyUtils.formatCurrency(
                                currencyUtils
                                    .convert(token['initialMaintenanceReserve'] ?? 0),
                                currencyUtils.currencySymbol),
                            isNegative: true,
                            color: Colors.orange,
                            iconColor: Colors.orange.shade300,
                          ),
                          _buildDetailRow(
                            context,
                            S.of(context).renovationReserve,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(token['renovationReserve'] ?? 0),
                                currencyUtils.currencySymbol),
                            isNegative: true,
                            color: Colors.purple,
                            iconColor: Colors.purple.shade300,
                          ),
                          _buildDetailRow(
                            context,
                            S.of(context).miscellaneousCosts,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(token['miscellaneousCosts'] ?? 0),
                                currencyUtils.currencySymbol),
                            isNegative: true,
                            color: Colors.amber,
                            iconColor: Colors.amber.shade300,
                          ),
                          _buildDetailRow(
                            context,
                            S.of(context).others,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert((token['totalInvestment'] -
                                        token['underlyingAssetPrice'] -
                                        totalCosts) ??
                                    0),
                                currencyUtils.currencySymbol),
                            isNegative: true,
                            color: Colors.grey,
                            iconColor: Colors.grey.shade400,
                          ),
                          
                          // Jauge de répartition des coûts dans un container arrondi
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: totalCosts > 0
                                  ? [
                                      Expanded(
                                        flex: ((token['realtListingFee'] ?? 0) / totalCosts * 100)
                                            .round(),
                                        child: Container(
                                          height: 4,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Expanded(
                                        flex: ((token['initialMaintenanceReserve'] ?? 0) /
                                                totalCosts *
                                                100)
                                            .round(),
                                        child: Container(
                                          height: 4,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      Expanded(
                                        flex: ((token['renovationReserve'] ?? 0) / totalCosts * 100)
                                            .round(),
                                        child: Container(
                                          height: 4,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      Expanded(
                                        flex:
                                            ((token['miscellaneousCosts'] ?? 0) / totalCosts * 100)
                                                .round(),
                                        child: Container(
                                          height: 4,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      Expanded(
                                        flex: (((token['totalInvestment'] ?? 0) -
                                                    (token['underlyingAssetPrice'] ?? 0) -
                                                    totalCosts) /
                                                totalCosts *
                                                100)
                                            .round(),
                                        child: Container(
                                          height: 4,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ]
                                  : [
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 4,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
                  );
                },
              ),

              const Divider(height: 1, thickness: 0.5),
              _buildDetailRow(
                  context,
                  S.of(context).underlyingAssetPrice,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(token['underlyingAssetPrice'] ?? 0),
                      currencyUtils.currencySymbol),
                  icon: Icons.home,
                  iconColor: Colors.blue),
            ],
          ),
        ),

        const SizedBox(height: 4),
        
        // Section des loyers
        _buildCard(
          context,
          title: "Loyers",
          child: Column(
            children: [
              _buildDetailRow(
                  context,
                  S.of(context).grossRentMonth,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(token['grossRentMonth'] ?? 0),
                      currencyUtils.currencySymbol),
                  icon: Icons.attach_money,
                  iconColor: Colors.green),

              const Divider(height: 1, thickness: 0.5),

              // Détails des dépenses de loyer
              GestureDetector(
                onTap: () =>
                    showRentDetailsNotifier.value = !showRentDetailsNotifier.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            S.of(context).totalExpenses,
                            style: TextStyle(
                                fontSize: 13 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          ValueListenableBuilder<bool>(
                            valueListenable: showRentDetailsNotifier,
                            builder: (context, showDetails, child) {
                              return Icon(
                                showDetails ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey,
                                size: 18 + appState.getTextSizeOffset(),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        '- ${currencyUtils.formatCurrency(currencyUtils.convert(token['grossRentMonth'] - token['netRentMonth']), currencyUtils.currencySymbol)}',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              // Détails des dépenses de loyer
              ValueListenableBuilder<bool>(
                valueListenable: showRentDetailsNotifier,
                builder: (context, showDetails, child) {
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showDetails 
                      ? Column(
                        children: [
                          _buildDetailRow(
                              context,
                              S.of(context).propertyMaintenanceMonthly,
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(
                                      token['propertyMaintenanceMonthly'] ?? 0),
                                  currencyUtils.currencySymbol),
                              isNegative: true,
                              color: Colors.deepOrange,
                              iconColor: Colors.deepOrange.shade300),
                          _buildDetailRow(
                              context,
                              S.of(context).propertyManagement,
                              currencyUtils.formatCurrency(
                                  currencyUtils
                                      .convert(token['propertyManagement'] ?? 0),
                                  currencyUtils.currencySymbol),
                              isNegative: true,
                              color: Colors.amber,
                              iconColor: Colors.amber.shade300),
                          _buildDetailRow(
                              context,
                              S.of(context).realtPlatform,
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(token['realtPlatform'] ?? 0),
                                  currencyUtils.currencySymbol),
                              isNegative: true,
                              color: Colors.orange,
                              iconColor: Colors.orange.shade300),
                          _buildDetailRow(
                              context,
                              S.of(context).insurance,
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(token['insurance'] ?? 0),
                                  currencyUtils.currencySymbol),
                              isNegative: true,
                              color: Colors.purple,
                              iconColor: Colors.purple.shade300),
                          _buildDetailRow(
                              context,
                              S.of(context).propertyTaxes,
                              currencyUtils.formatCurrency(
                                  currencyUtils.convert(token['propertyTaxes'] ?? 0),
                                  currencyUtils.currencySymbol),
                              isNegative: true,
                              color: Colors.red,
                              iconColor: Colors.red.shade300),
                          _buildDetailRow(
                              context,
                              S.of(context).others,
                              currencyUtils.formatCurrency(
                                  (currencyUtils.convert(token['grossRentMonth'] -
                                      token['netRentMonth'] -
                                      totalRentCosts)),
                                  currencyUtils.currencySymbol),
                              isNegative: true,
                              color: Colors.grey,
                              iconColor: Colors.grey.shade400),
                              
                          // Jauge de répartition des coûts de loyer
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? ((token['propertyMaintenanceMonthly'] ?? 0) /
                                              totalRentCosts *
                                              100)
                                          .round()
                                      : 0,
                                  child: Container(
                                    height: 4,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? ((token['propertyManagement'] ?? 0) / totalRentCosts * 100)
                                          .round()
                                      : 0,
                                  child: Container(
                                    height: 4,
                                    color: Colors.amber,
                                  ),
                                ),
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? ((token['realtPlatform'] ?? 0) / totalRentCosts * 100)
                                          .round()
                                      : 0,
                                  child: Container(
                                    height: 4,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? ((token['insurance'] ?? 0) / totalRentCosts * 100).round()
                                      : 0,
                                  child: Container(
                                    height: 4,
                                    color: Colors.purple,
                                  ),
                                ),
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? ((token['propertyTaxes'] ?? 0) / totalRentCosts * 100)
                                          .round()
                                      : 0,
                                  child: Container(
                                    height: 4,
                                    color: Colors.red,
                                  ),
                                ),
                                Expanded(
                                  flex: totalRentCosts != 0
                                      ? (((token['grossRentMonth'] ?? 0.0) -
                                                  (token['netRentMonth'] ?? 0.0) -
                                                  totalRentCosts) /
                                              totalRentCosts *
                                              100)
                                          .round()
                                      : 0,
                                  child: Container(
                                    height: 4,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
                  );
                },
              ),

              const Divider(height: 1, thickness: 0.5),
              _buildDetailRow(
                  context,
                  S.of(context).netRentMonth,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(token['netRentMonth'] ?? 0),
                      currencyUtils.currencySymbol),
                  icon: Icons.account_balance,
                  iconColor: Colors.green),
            ],
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Section du prix initial
        _buildCard(
          context,
          title: "Prix et rendement",
          child: Column(
            children: [
              _buildDetailRow(
                context,
                S.of(context).initialPrice,
                currencyUtils.formatCurrency(
                    currencyUtils.convert(token['initPrice']),
                    currencyUtils.currencySymbol),
                icon: Icons.price_change_sharp,
                iconColor: Colors.indigo,
                trailing: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.edit,
                      color: Colors.grey, size: 16 + appState.getTextSizeOffset()),
                  onPressed: () {
                    _showEditPriceBottomModal(context, token, dataManager);
                  },
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              _buildDetailRow(
                context,
                S.of(context).realtActualPrice,
                currencyUtils.formatCurrency(
                    currencyUtils.convert(token['tokenPrice']),
                    currencyUtils.currencySymbol),
                icon: Icons.price_change_sharp,
                iconColor: Colors.teal,
              ),
              const Divider(height: 1, thickness: 0.5),
              // Section YAM
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  children: [
                    Icon(Icons.price_change_sharp, size: 18, color: Colors.blueGrey),
                    Text('  YAM ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13 + appState.getTextSizeOffset())),
                    Spacer(),
                    Text(
                      '${currencyUtils.formatCurrency(currencyUtils.convert((token['yamAverageValue'])), currencyUtils.currencySymbol)} (${((token['yamAverageValue'] / token['initPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w500,
                        color: (token['yamAverageValue'] * token['amount']) >
                                token['totalValue']
                            ? Colors.green
                            : Colors.red,
                      ),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              _buildDetailRow(
                context,
                S.of(context).annualPercentageYield,
                '${token['annualPercentageYield']?.toStringAsFixed(2) ?? S.of(context).notSpecified} %',
                icon: Icons.percent,
                iconColor: Colors.amber,
              ),
              const Divider(height: 1, thickness: 0.5),
              _buildDetailRow(
                context,
                S.of(context).totalRentReceived,
                currencyUtils.formatCurrency(
                    currencyUtils.convert(token['totalRentReceived'] ?? 0),
                    currencyUtils.currencySymbol),
                icon: Icons.receipt_long,
                iconColor: Colors.green,
              ),
              const Divider(height: 1, thickness: 0.5),
              _buildDetailRow(
                context,
                S.of(context).roiPerProperties,
                "${(token['totalRentReceived'] / token['initialTotalValue'] * 100).toStringAsFixed(2)} %",
                icon: Icons.show_chart,
                color: Colors.blue,
                iconColor: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Méthode pour construire une ligne de détail
Widget _buildDetailRow(BuildContext context, String label, String value,
    {IconData? icon, bool isNegative = false, Color? color, Color? iconColor, Widget? trailing}) {
  final appState = Provider.of<AppState>(context, listen: false);

  final displayValue = isNegative ? '-$value' : value;
  final valueStyle = TextStyle(
    fontSize: 13 + appState.getTextSizeOffset(),
    fontWeight: FontWeight.w500,
    color:
        isNegative ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) 
                Icon(icon, size: 18, color: iconColor ?? Colors.blueGrey),
              if (isNegative)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: color ?? Colors.red,
                  ),
                ),
              SizedBox(width: icon != null || isNegative ? 8 : 0),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isNegative ? FontWeight.normal : FontWeight.w600,
                    fontSize: 13 + appState.getTextSizeOffset(),
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null)
                SizedBox(
                  height: 16 + appState.getTextSizeOffset(),
                  child: trailing,
                ),
            ],
          ),
        ),
        Text(displayValue, style: valueStyle),
      ],
    ),
  );
}

// Méthode pour construire une carte
Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 6.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: child,
        ),
      ],
    ),
  );
}

// Méthode pour afficher le BottomModal de modification du prix
void _showEditPriceBottomModal(
    BuildContext context, Map<String, dynamic> token, DataManager dataManager) {
  final TextEditingController priceController = TextEditingController(
    text: token['initPrice']?.toString() ?? '0.00',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de drag en haut du modal
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre
              Text(
                S.of(context).initialPrice,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                S.of(context).initialPriceModified_description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Champ de texte modernisé
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: S.of(context).enterValidNumber,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  suffixText: '\$',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(height: 24),
              // Boutons modernisés
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Bouton pour sauvegarder 
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newPrice = double.tryParse(priceController.text);
                        if (newPrice != null) {
                          dataManager.setCustomInitPrice(token['uuid'], newPrice);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).initialPriceUpdated),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).enterValidNumber),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(S.of(context).save),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bouton pour supprimer
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        dataManager.removeCustomInitPrice(token['uuid']);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(S.of(context).initialPriceRemoved),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
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
