import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';

Widget buildHistoryTab(BuildContext context, Map<String, dynamic> token, bool isLoadingTransactions) {
  final appState = Provider.of<AppState>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).transactionHistory,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 10),

        // Gestion de l'état de chargement avec Shimmer
        if (isLoadingTransactions)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5, // Placeholder pour 5 items simulés
            itemBuilder: (context, index) {
              return Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: ListTile(
                  leading: Shimmer.fromColors(
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
                  title: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                  subtitle: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              );
            },
          )
        else if (token['transactions'] != null && token['transactions'].isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: token['transactions'].length,
            itemBuilder: (context, index) {
              final transaction = token['transactions'][index];
              final price = '${currencyUtils.convert(transaction['price'] ?? token['tokenPrice']).toStringAsFixed(2)} ${currencyUtils.currencySymbol}';
              final amount = transaction['amount'] ?? 0.0;
              final transactionType = transaction.containsKey('transactionType') ? transaction['transactionType'] : S.of(context).unknownTransaction;

              final dateTime = transaction['dateTime'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(transaction['dateTime']) : S.of(context).unknownDate;

              IconData icon;
              Color iconColor;

              if (transactionType == S.of(context).purchase) {
                icon = Icons.shopping_cart;
                iconColor = Colors.blue;
              } else if (transactionType == S.of(context).internal_transfer) {
                icon = Icons.swap_horiz;
                iconColor = Colors.grey;
              } else if (transactionType == S.of(context).yam) {
                icon = Icons.price_change;
                iconColor = Colors.orange;
              } else {
                icon = Icons.attach_money;
                iconColor = Colors.green;
              }

              return Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(
                    '${S.of(context).transactionType}: $transactionType',
                    style: TextStyle(
                      fontSize: 14 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${S.of(context).quantity}: $amount",
                          style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          )),
                      Text("${S.of(context).price}: $price",
                          style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          )),
                      Text("${S.of(context).date}: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(dateTime))}",
                          style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          )),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Center(
            child: Text(
              S.of(context).noTransactionsAvailable,
              style: TextStyle(
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
          ),
      ],
    ),
  );
}
