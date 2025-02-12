import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:realtokens/utils/url_utils.dart';

Widget buildMarketTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section des offres secondaires
        Text(
          S.of(context).secondary_offers_related_to_token,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 8),

        // Liste des offres filtrées
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _getFilteredOffers(dataManager, token['uuid']), // Récupère les offres filtrées
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator()); // Affiche un indicateur de chargement
            } else if (snapshot.hasError) {
              return Center(child: Text(S.of(context).error_occurred(snapshot.error.toString()))); // Affiche une erreur
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(S.of(context).no_market_offers_available)); // Aucune offre disponible
            } else {
              final offers = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Désactive le défilement de la ListView
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  final delta = (offer['token_to_buy'] == null)
                      ? ((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100) // Calcul du delta pour les offres de vente
                      : ((offer['tokenValue'] / offer['tokenPrice'] - 1) * 100); // Calcul du delta pour les offres d'achat

                  return Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID de l'offre et date de création
                          Row(children: [
                            Text(
                              '${S.of(context).offer_id}: ${offer['id_offer']}',
                              style: TextStyle(
                                fontSize: 14 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Text(
                                  CustomDateUtils.formatReadableDate(offer['creationDate']),
                                  style: TextStyle(
                                    fontSize: 12 + appState.getTextSizeOffset(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                // Icône du token de paiement (xDai ou USDC)
                                if (offer['token_to_pay'] == '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' || offer['token_to_pay'] == '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d')
                                  Positioned(
                                    bottom: -30,
                                    child: Image.asset(
                                      'assets/icons/xdai.png',
                                      width: 28,
                                      height: 28,
                                    ),
                                  )
                                else if (offer['token_to_pay'] == '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' ||
                                    offer['token_to_pay'] == '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1')
                                  Positioned(
                                    bottom: -30,
                                    child: Image.asset(
                                      'assets/icons/usdc.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 4),

                          // Montant du token
                          Text(
                            '${S.of(context).token_amount}: ${offer['tokenAmount'].toStringAsFixed(3)}',
                            style: TextStyle(
                              fontSize: 12 + appState.getTextSizeOffset(),
                              color: Colors.grey[600],
                            ),
                          ),

                          // Valeur du token
                          Text(
                            '${S.of(context).token_value}: ${CurrencyUtils.formatCurrency(dataManager.convert(offer['tokenValue']), dataManager.currencySymbol)}',
                            style: TextStyle(
                              fontSize: 12 + appState.getTextSizeOffset(),
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Variation du prix (delta)
                          Row(
                            children: [
                              Text(
                                '${S.of(context).delta_price}: ',
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${delta.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  color: offer['token_to_buy'] == null
                                      ? (delta < 0 ? Colors.green : Colors.red) // Couleur pour les offres de vente
                                      : (delta < 0 ? Colors.red : Colors.green), // Couleur pour les offres d'achat
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Bouton pour acheter ou vendre
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                UrlUtils.launchURL('https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: offer['token_to_buy'] == null
                                    ? Colors.blue // Bouton bleu pour "acheter"
                                    : Colors.green, // Bouton vert pour "vendre"
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size(80, 30),
                              ),
                              child: Text(
                                offer['token_to_buy'] == null ? S.of(context).buy_token : S.of(context).sell_token,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    ),
  );
}

// Fonction pour récupérer les offres filtrées
Future<List<Map<String, dynamic>>> _getFilteredOffers(DataManager dataManager, String tokenUuid) async {
  return dataManager.yamMarket.where((offer) => offer['token_to_sell'] == tokenUuid.toLowerCase() || offer['token_to_buy'] == tokenUuid.toLowerCase()).toList();
}
