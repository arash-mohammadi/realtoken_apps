import 'package:package_info_plus/package_info_plus.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Pour accéder à AppState
import 'package:realtokens_apps/generated/l10n.dart'; // Importer pour les traductions
import 'package:realtokens_apps/app_state.dart'; // Importer pour accéder à l'offset de texte

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // Récupère la version de l'application
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accéder à AppState

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).about), // Traduction pour "About"
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            // Section Nom et Version de l'application
            SectionHeader(
              title: S.of(context).application, // Traduction pour "Application"
              textSizeOffset: appState.getTextSizeOffset(),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                S.of(context).appName, // Traduction pour "Nom de l'application"
                style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
              ),
              subtitle: const Text('RealToken App'),
            ),
            FutureBuilder<String>(
              future: _getAppVersion(),
              builder: (context, snapshot) {
                return ListTile(
                  leading: const Icon(Icons.verified),
                  title: Text(
                    S.of(context).version, // Traduction pour "Version"
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  subtitle: Text(snapshot.data ?? 'Chargement...'), // Affiche la version ou "Chargement..."
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                S.of(context).author, // Traduction pour "Auteur"
                style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
              ),
              subtitle: const Text('Byackee'),
            ),

            // Padding pour décaler les liens
            Padding(
              padding: const EdgeInsets.only(left: 32.0), // Décalage des ListTile pour LinkedIn et GitHub
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      'linktree',
                      style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                    ),
                    onTap: () => Utils.launchURL('https://linktr.ee/byackee'),
                    visualDensity: const VisualDensity(vertical: -4), // Réduction de l'espace vertical
                  ),
                ],
              ),
            ),

            const Divider(),

            // Section Remerciements
            SectionHeader(
              title: S.of(context).thanks, // Traduction pour "Remerciements"
              textSizeOffset: appState.getTextSizeOffset(),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(
                S.of(context).thankYouMessage, // Traduction pour "Merci à tous ceux qui ont contribué à ce projet"
                style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
              ),
              subtitle: Text(
                S.of(context).specialThanks, // Traduction pour "Remerciements particuliers à..."
                style: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final double textSizeOffset;

  const SectionHeader({required this.title, required this.textSizeOffset, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18 + textSizeOffset, // Ajustement pour Android avec offset
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
