import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/text_utils.dart';
import 'package:realtokens/utils/url_utils.dart';

Widget buildOthersTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);
  // Vérifier si le token est whitelisté
  final bool isWhitelisted = dataManager.whitelistTokens.any(
    (w) => w['token'].toLowerCase() == token['uuid'].toLowerCase(),
  );
  // Vérifier si le token est présent dans le portefeuille
  final bool isInWallet = dataManager.portfolio.any(
    (p) => p['uuid'].toLowerCase() == token['uuid'].toLowerCase(),
  );

  // Récupération de l'élément du portfolio correspondant à ce token (s'il existe)
  final portfolioItem = dataManager.portfolio.firstWhere(
    (p) => p['uuid'].toLowerCase() == token['uuid'].toLowerCase(),
    orElse: () => <String, dynamic>{},
  );
  // Extraction des wallets pour ce token, s'ils existent
  List<String> tokenWallets = [];
  if (portfolioItem.isNotEmpty && portfolioItem.containsKey('wallets')) {
    tokenWallets = List<String>.from(portfolioItem['wallets']);
  }

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
                  UrlUtils.launchURL(
                      'https://etherscan.io/address/$ethereumAddress');
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
                  UrlUtils.launchURL(
                      'https://gnosisscan.io/address/$gnosisAddress');
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
        // Section Whitelist
        const SizedBox(height: 10),
        Text(
          S.of(context).other,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isWhitelisted ? Icons.check_circle : Icons.cancel,
              color: isWhitelisted ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isWhitelisted
                  ? S.of(context).tokenWhitelisted
                  : S.of(context).tokenNotWhitelisted,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWhitelisted ? Colors.green : Colors.red,
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              isInWallet
                  ? Icons.account_balance_wallet
                  : Icons.account_balance_wallet_outlined,
              color: isInWallet ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isInWallet
                  ? S.of(context).presentInWallet
                  : S.of(context).filterNotInWallet,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInWallet ? Colors.green : Colors.red,
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
          ],
        ),
        const Divider(),
        // Nouvelle section pour afficher les wallets dans lesquels ce token est présent
        const SizedBox(height: 10),
        Text(
          "Wallets contenant ce token :",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 4),
        tokenWallets.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tokenWallets.map((walletAddress) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            appState.showAmounts ? walletAddress : TextUtils.truncateWallet(walletAddress),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13 + appState.getTextSizeOffset(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : Text(
                S.of(context).notSpecified,
                style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
              ),
        const Divider(),
        // Section Informations supplémentaires (si nécessaire)
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
