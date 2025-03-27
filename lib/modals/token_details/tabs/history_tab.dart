import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/shimmer_utils.dart';

Widget buildHistoryTab(BuildContext context, Map<String, dynamic> token,
    bool isLoadingTransactions) {
  final appState = Provider.of<AppState>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

  // Tri des transactions par date (du plus récent au plus ancien) si disponibles
  if (token['transactions'] != null && token['transactions'].isNotEmpty) {
    List<dynamic> sortedTransactions = List.from(token['transactions']);
    sortedTransactions.sort((a, b) {
      final dateA = a['dateTime'] != null ? DateTime.parse(a['dateTime'].toString()) : DateTime.now();
      final dateB = b['dateTime'] != null ? DateTime.parse(b['dateTime'].toString()) : DateTime.now();
      return dateB.compareTo(dateA);
    });
    token['transactions'] = sortedTransactions;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section historique des transactions
        _buildSectionCard(
          context,
          title: S.of(context).transactionHistory,
          children: [
            // Gestion de l'état de chargement avec Shimmer
            if (isLoadingTransactions)
              ...List.generate(5, (index) => // Placeholder pour 5 items simulés
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Card(
                    elevation: 0, // Style iOS plat
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Coins arrondis style iOS
                    ),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ShimmerUtils.standardShimmer(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerUtils.standardShimmer(
                                  child: Container(
                                    width: double.infinity,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                ShimmerUtils.standardShimmer(
                                  child: Container(
                                    width: 100,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              )
            else if (token['transactions'] != null && token['transactions'].isNotEmpty)
              ...token['transactions'].map((transaction) {
                final price =
                    '${currencyUtils.convert(transaction['price'] ?? token['tokenPrice']).toStringAsFixed(2)} ${currencyUtils.currencySymbol}';
                final amount = transaction['amount'] ?? 0.0;
                final transactionType = transaction.containsKey('transactionType')
                    ? transaction['transactionType']
                    : S.of(context).unknownTransaction;

                final dateTime = transaction['dateTime'] != null
                    ? DateFormat('yyyy-MM-dd HH:mm')
                        .format(transaction['dateTime'])
                    : S.of(context).unknownDate;

                IconData icon;
                Color iconColor;
                Color bgColor;

                if (transactionType == DataManager.transactionTypePurchase) {
                  icon = Icons.shopping_cart;
                  iconColor = Colors.white;
                  bgColor = Colors.blue;
                } else if (transactionType == DataManager.transactionTypeTransfer) {
                  icon = Icons.swap_horiz;
                  iconColor = Colors.white;
                  bgColor = Colors.grey;
                } else if (transactionType == DataManager.transactionTypeYam) {
                  icon = Icons.price_change;
                  iconColor = Colors.white;
                  bgColor = Colors.orange;
                } else {
                  icon = Icons.attach_money;
                  iconColor = Colors.white;
                  bgColor = Colors.green;
                }

                // Afficher chaque transaction dans une belle carte style iOS
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Theme.of(context).cardColor,
                        child: InkWell(
                          onTap: () {
                            // Optionnellement: afficher plus de détails sur la transaction
                          },
                          splashColor: bgColor.withOpacity(0.1),
                          highlightColor: bgColor.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Icône avec cercle coloré
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      icon, 
                                      color: iconColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Contenu
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Type de transaction
                                      Text(
                                        _getLocalizedTransactionType(transactionType, context),
                                        style: TextStyle(
                                          fontSize: 16 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Détails principaux
                                      Row(
                                        children: [
                                          Text(
                                            price, 
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Text(" • "),
                                          Text(
                                            "${S.of(context).quantity}: $amount",
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Date
                                      Text(
                                        DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(dateTime)),
                                        style: TextStyle(
                                          fontSize: 12 + appState.getTextSizeOffset(),
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Indicateur de navigation (flèche droite)
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList()
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        S.of(context).noTransactionsAvailable,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

// Widget pour construire une section, comme dans property_tab.dart
Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
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

// Méthode pour traduire les constantes en textes localisés
String _getLocalizedTransactionType(String transactionType, BuildContext context) {
  if (transactionType == DataManager.transactionTypePurchase) {
    return S.of(context).purchase;
  } else if (transactionType == DataManager.transactionTypeTransfer) {
    return S.of(context).internal_transfer;
  } else if (transactionType == DataManager.transactionTypeYam) {
    return S.of(context).yam;
  } else {
    return S.of(context).unknownTransaction;
  }
}
