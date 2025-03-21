import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';

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

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    physics: const BouncingScrollPhysics(), // Comportement de scroll iOS
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            S.of(context).transactionHistory,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20, // Titre plus grand
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),

        // Gestion de l'état de chargement avec Shimmer
        if (isLoadingTransactions)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5, // Placeholder pour 5 items simulés
            itemBuilder: (context, index) {
              return Card(
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
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
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
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
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
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
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
              );
            },
          )
        else if (token['transactions'] != null &&
            token['transactions'].isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: token['transactions'].length,
            itemBuilder: (context, index) {
              final transaction = token['transactions'][index];
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

              if (transactionType == S.of(context).purchase) {
                icon = Icons.shopping_cart;
                iconColor = Colors.white;
                bgColor = Colors.blue;
              } else if (transactionType == S.of(context).internal_transfer) {
                icon = Icons.swap_horiz;
                iconColor = Colors.white;
                bgColor = Colors.grey;
              } else if (transactionType == S.of(context).yam) {
                icon = Icons.price_change;
                iconColor = Colors.white;
                bgColor = Colors.orange;
              } else {
                icon = Icons.attach_money;
                iconColor = Colors.white;
                bgColor = Colors.green;
              }

              // Afficher chaque transaction dans une belle carte style iOS
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.transparent,
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
                                    transactionType,
                                    style: TextStyle(
                                      fontSize: 16 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.w600,
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
                                      color: Colors.grey[600],
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
              );
            },
          )
        else
          Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(top: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
