import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/utils/url_utils.dart';

class LinksPage extends StatefulWidget {
  const LinksPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<LinksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: Text('Links'), // Utilisation de S.of(context)
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildCard(
                    'assets/icons/RMM.jpg',
                    'RMM (RealToken Money Market)',
                    'https://rmm.realtoken.network',
                    S.of(context).rmm_description),
                const SizedBox(height: 10),
                _buildCard(
                    'assets/icons/YAM.jpg',
                    'YAM (You And Me)',
                    'https://yam.realtoken.network',
                    S.of(context).rmm_description),
                const SizedBox(height: 10),
                _buildCard(
                    'assets/logo_community.png',
                    'Wiki Community',
                    'https://community-realt.gitbook.io/tuto-community',
                    S.of(context).wiki_community_description),
                const SizedBox(height: 10),
                _buildCard(
                    'assets/DAO.png',
                    'RealToken governance Forum',
                    'https://forum.realtoken.community',
                    S.of(context).dao_description),
              ],
            )),
      ),
    );
  }

  // Fonction pour créer une carte similaire à DashboardPage
  Widget _buildCard(
    String imagePath, // Chemin de l'image à afficher
    String linkText, // Texte du lien
    String linkUrl, // URL du lien
    String description, // Description courte
  ) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image sur la gauche
            Image.asset(
              imagePath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12), // Espacement entre l'image et le texte
            // Lien texte et description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => UrlUtils.launchURL(linkUrl),
                    child: Text(
                      linkText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 4), // Espacement entre le lien et la description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
}
