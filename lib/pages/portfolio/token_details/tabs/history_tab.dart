import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';

Widget buildHistoryTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);

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

        // Liste des transactions
        if (token['transactions'] != null && token['transactions'].isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: token['transactions'].length,
            itemBuilder: (context, index) {
              final transaction = token['transactions'][index];
              final amount = transaction['amount'] ?? 0.0;
              final dateTime = transaction['dateTime'] != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(transaction['dateTime'])
                  : S.of(context).unknownDate;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: ListTile(
                  leading: Icon(
                    Icons.attach_money,
                    color: Colors.green,
                  ),
                  title: Text(
                    '${S.of(context).amount}: $amount',
                    style: TextStyle(
                      fontSize: 14 + appState.getTextSizeOffset(),
                    ),
                  ),
                  subtitle: Text(
                    '${S.of(context).date}: $dateTime',
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: Colors.grey,
                    ),
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