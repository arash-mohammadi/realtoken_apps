import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:realtokens_apps/api/data_manager.dart';
import 'package:realtokens_apps/app_state.dart';
import 'package:realtokens_apps/generated/l10n.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    // Accéder à DataManager pour récupérer les valeurs calculées
final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: Text('Links'), // Utilisation de S.of(context)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
  children: [
    _buildCard('assets/icons/RMM.jpg', 'RMM (RealToken Money Market)', 'https://rmm.realtoken.network'),
    const SizedBox(height: 10),
    _buildCard('assets/icons/YAM.jpg', 'YAM (You And Me)', 'https://yam.realtoken.network'),
    const SizedBox(height: 10),
    _buildCard('assets/logo_community.png', 'Wiki Community  ', 'https://community-realt.gitbook.io/tuto-community'),
  ],
) ),
      ),
    );
  }

  // Fonction pour créer une carte similaire à DashboardPage
Widget _buildCard(
  String imagePath, // Chemin de l'image à afficher
  String linkText, // Texte du lien
  String linkUrl, // URL du lien
) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image sur la gauche
          Image.asset(
            imagePath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12), // Espacement entre l'image et le texte
          // Lien texte sur la droite
          Expanded(
            child: GestureDetector(
              onTap: () => Utils.launchURL(linkUrl),
              child: Text(
                linkText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
