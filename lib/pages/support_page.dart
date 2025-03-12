import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/utils/url_utils.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<SupportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Accéder à DataManager pour récupérer les valeurs calculées
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: Text('Support'), // Utilisation de S.of(context)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10), // Espace sous l'image
              _buildCard(
                'GitHub support', // Titre de la carte
                Icons.bug_report_outlined, // Icône représentative pour GitHub
                Text(
                  'Contribuez ou signalez un problème sur GitHub :',
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                ), // Texte principal
                linkText: 'Github isssues link', // Texte du lien
                linkUrl:
                    'https://github.com/RealToken-Community/realtoken_apps/issues', // URL du lien
                iconColor: Colors.grey, // Couleur noire pour GitHub
              ),
              const SizedBox(height: 10),
              _buildCard(
                'Telegram support', // Titre de la carte
                Icons.telegram, // Icône de Telegram
                Text(
                  'Rejoignez-nous sur Telegram :',
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                ), // Texte principal
                linkText: 'Telegram Link here', // Texte du lien
                linkUrl: 'https://t.me/+ae_vCmnjg5JjNWQ0', // URL du lien
                iconColor: Color(0xFF0088CC), // Couleur officielle Telegram
              ),
              const SizedBox(height: 10), // Espace sous l'image
              _buildCard(
                'Discord support', // Titre de la carte
                Icons.discord,
                Text(
                  'Rejoignez-nous sur Discord :',
                  style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                ), // Texte principal
                linkText: 'Discord Link here', // Texte du lien
                linkUrl:
                    'https://discord.com/channels/681940057183092737/681966628527013891', // URL du lien
                iconColor: Colors.purple, // Couleur de l'icône
              ),
              const SizedBox(height: 10), // Espace sous l'image

              _buildCard(
                S.of(context).supportProject, // Titre de la carte
                Icons.monetization_on, // Icône pour la carte
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).donationMessage,
                      style: TextStyle(
                          fontSize: 13 + appState.getTextSizeOffset()),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(
                        'My linktree',
                        style: TextStyle(
                            fontSize: 13 + appState.getTextSizeOffset()),
                      ),
                      onTap: () =>
                          UrlUtils.launchURL('https://linktr.ee/byackee'),
                      visualDensity: const VisualDensity(
                          vertical: -4), // Réduction de l'espace vertical
                    ),
                    const SizedBox(height: 20),
                    if (kIsWeb ||
                        (!kIsWeb &&
                            !Platform
                                .isIOS)) // Condition pour afficher les boutons
                      Wrap(
                        spacing: 8.0, // Espacement horizontal entre les boutons
                        runSpacing:
                            8.0, // Espacement vertical entre les lignes de boutons
                        alignment: WrapAlignment.center, // Alignement au centre
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              UrlUtils.launchURL(
                                  'https://paypal.me/byackee?country.x=FR&locale.x=fr_FR');
                            },
                            icon:
                                const Icon(Icons.payment, color: Colors.white),
                            label: Text(
                              S.of(context).paypal,
                              style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              UrlUtils.launchURL(
                                  'https://buymeacoffee.com/byackee');
                            },
                            icon: Image.asset(
                              'assets/bmc.png', // Chemin de votre image dans les assets
                              height: 24, // Ajustez la taille de l'image
                              width: 24,
                            ),
                            label: Text(
                              'Buy Coffee',
                              style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showCryptoAddressDialog(
                                  context, appState.getTextSizeOffset());
                            },
                            icon: const Icon(Icons.currency_bitcoin,
                                color: Colors.white),
                            label: Text(
                              S.of(context).crypto,
                              style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour créer une carte similaire à DashboardPage
  Widget _buildCard(
    String title,
    IconData icon,
    Widget firstChild, {
    String? linkText, // Texte pour le lien
    String? linkUrl, // URL à ouvrir
    Color iconColor = Colors.blue, // Couleur par défaut de l'icône
  }) {
    final appState = Provider.of<AppState>(context);
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          size: 24,
                          color: iconColor), // Couleur personnalisable
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  firstChild,
                  const SizedBox(height: 10),
                  if (linkText != null && linkUrl != null)
                    GestureDetector(
                      onTap: () => UrlUtils.launchURL(linkUrl),
                      child: Text(
                        linkText,
                        style: TextStyle(
                          fontSize: 14 + appState.getTextSizeOffset(),
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
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
  }

  void _showCryptoAddressDialog(BuildContext context, double textSizeOffset) {
    const cryptoAddress = '0x2cb49d04890a98eb89f4f43af96ad01b98b64165';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            S.of(context).cryptoDonationAddress,
            style: TextStyle(fontSize: 14 + textSizeOffset),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).sendDonations,
                style: TextStyle(fontSize: 14 + textSizeOffset),
              ),
              const SizedBox(height: 10),
              SelectableText(
                cryptoAddress,
                style: TextStyle(
                    fontSize: 14 + textSizeOffset, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: cryptoAddress));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).addressCopied)),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(S.of(context).copy,
                    style: TextStyle(fontSize: 14 + textSizeOffset)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).close,
                  style: TextStyle(fontSize: 14 + textSizeOffset)),
            ),
          ],
        );
      },
    );
  }
}
