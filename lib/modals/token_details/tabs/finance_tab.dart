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

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section investissement
        _buildSectionCard(
          context,
          title: "Investissement",
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
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          S.of(context).totalExpenses,
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
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
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w400,
                        color: Colors.red,
                      ),
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
                          icon: Icons.circle,
                          iconColor: Colors.red.shade300,
                          isExpenseItem: true,
                        ),
                        _buildDetailRow(
                          context,
                          S.of(context).initialMaintenanceReserve,
                          currencyUtils.formatCurrency(
                              currencyUtils
                                  .convert(token['initialMaintenanceReserve'] ?? 0),
                              currencyUtils.currencySymbol),
                          icon: Icons.circle,
                          iconColor: Colors.orange.shade300,
                          isExpenseItem: true,
                        ),
                        _buildDetailRow(
                          context,
                          S.of(context).renovationReserve,
                          currencyUtils.formatCurrency(
                              currencyUtils.convert(token['renovationReserve'] ?? 0),
                              currencyUtils.currencySymbol),
                          icon: Icons.circle,
                          iconColor: Colors.purple.shade300,
                          isExpenseItem: true,
                        ),
                        _buildDetailRow(
                          context,
                          S.of(context).miscellaneousCosts,
                          currencyUtils.formatCurrency(
                              currencyUtils.convert(token['miscellaneousCosts'] ?? 0),
                              currencyUtils.currencySymbol),
                          icon: Icons.circle,
                          iconColor: Colors.amber.shade300,
                          isExpenseItem: true,
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
                          icon: Icons.circle,
                          iconColor: Colors.grey.shade400,
                          isExpenseItem: true,
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
                );
              },
            ),
            
            // Jauge de répartition des coûts dans un container arrondi
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: totalCosts > 0
                    ? [
                        Expanded(
                          flex: ((token['realtListingFee'] ?? 0) / totalCosts * 100)
                              .round(),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.red.shade600, Colors.red.shade400],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((token['initialMaintenanceReserve'] ?? 0) /
                                  totalCosts *
                                  100)
                              .round(),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.orange.shade600, Colors.orange.shade400],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((token['renovationReserve'] ?? 0) / totalCosts * 100)
                              .round(),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.purple.shade600, Colors.purple.shade400],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex:
                              ((token['miscellaneousCosts'] ?? 0) / totalCosts * 100)
                                  .round(),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.amber.shade600, Colors.amber.shade400],
                              ),
                            ),
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
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.grey.shade500, Colors.grey.shade400],
                              ),
                            ),
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.grey.shade500, Colors.grey.shade400],
                              ),
                            ),
                          ),
                        ),
                      ],
              ),
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

        const SizedBox(height: 5),
        
        // Section des loyers
        _buildSectionCard(
          context,
          title: "Loyers",
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
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          S.of(context).totalExpenses,
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
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
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w400,
                        color: Colors.red,
                      ),
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
                            icon: Icons.circle,
                            iconColor: Colors.deepOrange.shade300,
                            isExpenseItem: true),
                        _buildDetailRow(
                            context,
                            S.of(context).propertyManagement,
                            currencyUtils.formatCurrency(
                                currencyUtils
                                    .convert(token['propertyManagement'] ?? 0),
                                currencyUtils.currencySymbol),
                            icon: Icons.circle,
                            iconColor: Colors.amber.shade300,
                            isExpenseItem: true),
                        _buildDetailRow(
                            context,
                            S.of(context).realtPlatform,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(token['realtPlatform'] ?? 0),
                                currencyUtils.currencySymbol),
                            icon: Icons.circle,
                            iconColor: Colors.orange.shade300,
                            isExpenseItem: true),
                        _buildDetailRow(
                            context,
                            S.of(context).insurance,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(token['insurance'] ?? 0),
                                currencyUtils.currencySymbol),
                            icon: Icons.circle,
                            iconColor: Colors.purple.shade300,
                            isExpenseItem: true),
                        _buildDetailRow(
                            context,
                            S.of(context).propertyTaxes,
                            currencyUtils.formatCurrency(
                                currencyUtils.convert(token['propertyTaxes'] ?? 0),
                                currencyUtils.currencySymbol),
                            icon: Icons.circle,
                            iconColor: Colors.red.shade300,
                            isExpenseItem: true),
                        _buildDetailRow(
                            context,
                            S.of(context).others,
                            currencyUtils.formatCurrency(
                                (currencyUtils.convert(token['grossRentMonth'] -
                                    token['netRentMonth'] -
                                    totalRentCosts)),
                                currencyUtils.currencySymbol),
                            icon: Icons.circle,
                            iconColor: Colors.grey.shade400,
                            isExpenseItem: true),
                      ],
                    )
                    : const SizedBox.shrink(),
                );
              },
            ),
                            
            // Jauge de répartition des coûts de loyer
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
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
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: totalRentCosts != 0
                        ? ((token['propertyManagement'] ?? 0) / totalRentCosts * 100)
                            .round()
                        : 0,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.amber.shade600, Colors.amber.shade400],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: totalRentCosts != 0
                        ? ((token['realtPlatform'] ?? 0) / totalRentCosts * 100)
                            .round()
                        : 0,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.orange.shade600, Colors.orange.shade400],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: totalRentCosts != 0
                        ? ((token['insurance'] ?? 0) / totalRentCosts * 100).round()
                        : 0,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.purple.shade600, Colors.purple.shade400],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: totalRentCosts != 0
                        ? ((token['propertyTaxes'] ?? 0) / totalRentCosts * 100)
                            .round()
                        : 0,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.red.shade600, Colors.red.shade400],
                        ),
                      ),
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
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.grey.shade500, Colors.grey.shade400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        
        const SizedBox(height: 5),
        
        // Section du prix et rendement
        _buildSectionCard(
          context,
          title: "Prix et rendement",
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
            _buildDetailRow(
              context,
              'YAM',
              '${currencyUtils.formatCurrency(currencyUtils.convert((token['yamAverageValue'])), currencyUtils.currencySymbol)} (${((token['yamAverageValue'] / token['initPrice'] - 1) * 100).toStringAsFixed(0)}%)',
              icon: Icons.price_change_sharp,
              iconColor: Colors.blueGrey,
              textColor: (token['yamAverageValue'] * token['amount']) > token['totalValue'] ? Colors.green : Colors.red,
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
              iconColor: Colors.blue,
            ),
          ],
        ),
      ],
    ),
  );
}

// Méthode pour construire une section avec carte, comme dans property_tab.dart
Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
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
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Column(children: children),
      ],
    ),
  );
}

// Méthode pour construire les lignes de détails, comme dans property_tab.dart
Widget _buildDetailRow(
    BuildContext context, String label, String value,
    {IconData? icon, Color? iconColor, Color? textColor, Widget? trailing, bool isExpenseItem = false}) {
  final appState = Provider.of<AppState>(context, listen: false);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null)
              isExpenseItem 
              ? Icon(
                  icon,
                  size: 14,
                  color: iconColor ?? Colors.blue,
                )
              : Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (iconColor ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? Colors.blue,
                  ),
                ),
            SizedBox(width: isExpenseItem ? 6 : 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w300,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w400,
            color: isExpenseItem ? Colors.red : (textColor ?? Theme.of(context).textTheme.bodyLarge?.color),
          ),
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
                style: TextStyle(
                  fontSize: 20 + Provider.of<AppState>(context).getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                S.of(context).initialPriceModified_description,
                style: TextStyle(
                  fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
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
