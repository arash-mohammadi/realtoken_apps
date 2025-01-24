import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:realtokens_apps/pages/links_page.dart';
import 'package:realtokens_apps/pages/propertiesForSale/propertiesForSell_select.dart';
import 'package:realtokens_apps/pages/support_page.dart';
import 'package:realtokens_apps/settings/service_status.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/settings/settings_page.dart';
import 'package:realtokens_apps/pages/real_tokens_page.dart';
import 'package:realtokens_apps/about.dart';
import 'package:realtokens_apps/pages/updates_page.dart';
import 'package:realtokens_apps/pages/realt_page.dart';
import 'package:realtokens_apps/generated/l10n.dart';
import 'package:realtokens_apps/settings/manage_evm_addresses_page.dart';
import 'package:realtokens_apps/app_state.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:io';

class CustomDrawer extends StatelessWidget {
  final Function(bool) onThemeChanged;
  const CustomDrawer({required this.onThemeChanged, super.key});

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
          content: Text("La demande de notation n'a pas pu être affichée. "
              "Souhaitez-vous ouvrir la page de l'application dans le Store pour laisser un avis ?"),
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
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Utils.launchURL('https://realt.co/marketplace/');
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_community.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'RealTokens',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23 + appState.getTextSizeOffset(),
                              ),
                            ),
                            Text(
                              S.of(context).appDescription,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15 + appState.getTextSizeOffset(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.wallet, size: 24 + appState.getTextSizeOffset()),
                  title: Text(
                    S.of(context).manageEvmAddresses,
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                  leading: const Icon(Icons.monitor),
                  title: Text(
                    'Service Status',
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                  leading: const Icon(Icons.link),
                  title: Text(
                    'Links',
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                  leading: const Icon(Icons.support_agent),
                  title: Text(
                    'Support',
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Ferme le drawer avant la demande de notation
                    await _requestReview(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(
                    S.of(context).settings,
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(
                    S.of(context).about,
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
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
                ListTile(
                  leading: const Icon(Icons.feedback),
                  title: Text(
                    S.of(context).feedback,
                    style: TextStyle(fontSize: 15 + appState.getTextSizeOffset()),
                  ),
                  onTap: () {
                    Utils.launchURL('https://github.com/RealToken-Community/realtoken-apps/issues');
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
