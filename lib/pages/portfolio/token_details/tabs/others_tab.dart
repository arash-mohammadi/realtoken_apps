import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/url_utils.dart';

Widget buildOthersTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Blockchain
        Text(
          S.of(context).blockchain,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 10),

        // Contrat Ethereum
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/ethereum.png', // Chemin de l'image Ethereum
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).ethereumContract,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13 + appState.getTextSizeOffset(),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () {
                final ethereumAddress = token['ethereumContract'] ?? '';
                if (ethereumAddress.isNotEmpty) {
                  UrlUtils.launchURL('https://etherscan.io/address/$ethereumAddress');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).notSpecified)),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          token['ethereumContract'] ?? S.of(context).notSpecified,
          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
        ),

        const SizedBox(height: 10),

        // Contrat Gnosis
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/gnosis.png', // Chemin de l'image Gnosis
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).gnosisContract,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13 + appState.getTextSizeOffset(),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () {
                final gnosisAddress = token['gnosisContract'] ?? '';
                if (gnosisAddress.isNotEmpty) {
                  UrlUtils.launchURL('https://gnosisscan.io/address/$gnosisAddress');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).notSpecified)),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          token['gnosisContract'] ?? S.of(context).notSpecified,
          style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
        ),

        const Divider(),

        // Section Informations supplémentaires
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ajoutez ici d'autres informations si nécessaire
          ],
        ),
      ],
    ),
  );
}