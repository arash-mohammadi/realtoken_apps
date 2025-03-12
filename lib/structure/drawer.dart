import 'package:realtokens/pages/changelog_page.dart';
import 'package:realtokens/pages/links_page.dart';
import 'package:realtokens/pages/propertiesForSale/propertiesForSell_select.dart';
import 'package:realtokens/pages/support_page.dart';
import 'package:realtokens/settings/service_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/settings/settings_page.dart';
import 'package:realtokens/pages/realtokens_page.dart';
import 'package:realtokens/about.dart';
import 'package:realtokens/pages/updates_page.dart';
import 'package:realtokens/pages/realt_page.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/settings/manage_evm_addresses_page.dart';
import 'package:realtokens/app_state.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

import 'package:realtokens/utils/url_utils.dart';

class CustomDrawer extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const CustomDrawer({required this.onThemeChanged, super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? latestVersion;
  String? currentVersion;

  @override
  void initState() {
    super.initState();
    _fetchVersions();
  }

  Future<void> _fetchVersions() async {
    try {
      // Récupérer la version actuelle de l'application
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        currentVersion = packageInfo.version;
      });

      // Récupérer la version du fichier pubspec.yaml sur GitHub
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/RealToken-Community/realtoken_apps/main/pubspec.yaml'));

      if (response.statusCode == 200) {
        final pubspecContent = response.body;
        final versionMatch =
            RegExp(r'version:\s*([\d.]+)').firstMatch(pubspecContent);
        if (versionMatch != null) {
          setState(() {
            latestVersion = versionMatch.group(1);
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des versions : $e');
    }
  }

  Future<void> _requestReview(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;
    bool isReviewRequested = false;

    try {
      // Vérifie si l'API de notation est disponible
      final isAvailable = await inAppReview.isAvailable();
      if (isAvailable && !Platform.isAndroid) {
        // L'API fonctionne en mode release
        await inAppReview.requestReview();
        isReviewRequested = true;
      }
    } catch (e) {
      // Gère toute exception qui peut survenir
      isReviewRequested = false;
    }

    // Si la demande de notation n'est pas disponible ou échoue
    if (!isReviewRequested) {
      _showReviewNotAvailablePopup(context);
    }
  }

  void _showReviewNotAvailablePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Merci pour vos retours !"),
          content: Text(
              "La demande de notation n'a pas pu être affichée. Souhaitez-vous ouvrir la page de l'application dans le Store pour laisser un avis ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Non, merci"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await InAppReview.instance.openStoreListing();
              },
              child: Text("Oui, avec plaisir"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Drawer(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      UrlUtils.launchURL('https://realt.co/marketplace/');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo_community.png',
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RealTokens',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          23 + appState.getTextSizeOffset(),
                                    ),
                                  ),
                                  Text(
                                    S.of(context).appDescription,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize:
                                          15 + appState.getTextSizeOffset(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (latestVersion != null &&
                            currentVersion != null &&
                            latestVersion != currentVersion)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: Colors.green, // Bulle verte
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                '${S.of(context).newVersionAvailable}: $latestVersion',
                                style: TextStyle(
                                  color: Colors.white, // Texte blanc
                                  fontSize: 14 + appState.getTextSizeOffset(),
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.wallet,
                      size: 24 + appState.getTextSizeOffset()),
                  title: Text(
                    S.of(context).manageEvmAddresses,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageEvmAddressesPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.home_work),
                  title: Text(
                    S.of(context).propertiesForSale,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropertiesForSalePage(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.list),
                  title: Text(
                    S.of(context).realTokensList,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RealTokensPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: Text(
                    S.of(context).recentChanges,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdatesPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: Text(
                    'RealT stats',
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RealtPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(
                    S.of(context).links,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LinksPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.monitor),
                  title: Text(
                    S.of(context).serviceStatus,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceStatusPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: Text(
                    'Support',
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupportPage(),
                      ),
                    );
                  },
                ),

                // Item pour la notation de l'application
                ListTile(
                  leading: const Icon(Icons.star),
                  title: Text(
                    'Noter l\'application',
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () async {
                    Navigator.pop(
                        context); // Ferme le drawer avant la demande de notation
                    await _requestReview(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(
                    S.of(context).settings,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: Text(
                    'Changelog',
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child:
                              const ChangelogPage(), // votre widget qui affiche le changelog
                        );
                      },
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(
                    S.of(context).about,
                    style:
                        TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
