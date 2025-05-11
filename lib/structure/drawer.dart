import 'package:realtoken_asset_tracker/pages/changelog_page.dart';
import 'package:realtoken_asset_tracker/pages/links_page.dart';
import 'package:realtoken_asset_tracker/pages/propertiesForSale/propertiesForSell_select.dart';
import 'package:realtoken_asset_tracker/pages/support_page.dart';
import 'package:realtoken_asset_tracker/settings/service_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/settings/settings_page.dart';
import 'package:realtoken_asset_tracker/pages/realtokens_page.dart';
import 'package:realtoken_asset_tracker/about.dart';
import 'package:realtoken_asset_tracker/pages/updates_page.dart';
import 'package:realtoken_asset_tracker/pages/realt_page.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/settings/manage_evm_addresses_page.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'dart:convert';

import 'package:realtoken_asset_tracker/utils/url_utils.dart';

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

      // Récupérer la dernière version à partir des releases GitHub au lieu du pubspec.yaml
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final tagName = releaseData['tag_name'];

        // Supprimer le 'v' au début du tag si présent (ex: v1.0.0 -> 1.0.0)
        setState(() {
          latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        });
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
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            S.of(context).thankYouForFeedback,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(
            S.of(context).reviewRequestUnavailable,
            style: TextStyle(fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset()),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).noThanks),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await InAppReview.instance.openStoreListing();
              },
              isDefaultAction: true,
              child: Text(S.of(context).yesWithPleasure),
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
          // Supprimer le backgroundColor pour permettre à la couleur de l'en-tête d'aller jusqu'en haut
          child: ClipRRect(
            child: Column(
              children: [
                // En-tête avec sa propre SafeArea
                Material(
                  color: Theme.of(context).primaryColor.withOpacity(0.9),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          UrlUtils.launchURL('https://realt.co/marketplace/');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Image.asset(
                                    'assets/logo_community.png',
                                    width: 36,
                                    height: 36,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RealToken Asset Tracker',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        S.of(context).appDescription,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (latestVersion != null && currentVersion != null && latestVersion != currentVersion)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGreen,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.arrow_down_circle_fill,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${S.of(context).newVersionAvailable}: $latestVersion',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenu dans un Expanded + ScrollView
                Expanded(
                  child: Stack(
                    children: [
                      // Décaler le contenu vers le haut pour créer un chevauchement
                      Positioned(
                        top: -16,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground.resolveFrom(context),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),

                                  // Section Accounts
                                  _buildSectionCard(context, 'Comptes', appState, children: [
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.person_crop_circle_fill,
                                      title: S.of(context).manageEvmAddresses,
                                      appState: appState,
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
                                  ]),

                                  const SizedBox(height: 10),

                                  // Section Principales Fonctionnalités
                                  _buildSectionCard(context, 'Fonctionnalités', appState, children: [
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.house_fill,
                                      title: S.of(context).propertiesForSale,
                                      appState: appState,
                                      iconColor: Colors.teal,
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
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.list_bullet,
                                      title: S.of(context).realTokensList,
                                      appState: appState,
                                      iconColor: Colors.blue,
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
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.arrow_clockwise_circle_fill,
                                      title: S.of(context).recentChanges,
                                      appState: appState,
                                      iconColor: Colors.orange,
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
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.graph_square_fill,
                                      title: 'RealT stats',
                                      appState: appState,
                                      iconColor: Colors.purple,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RealtPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.link,
                                      title: S.of(context).links,
                                      appState: appState,
                                      iconColor: Colors.indigo,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LinksPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ]),

                                  const SizedBox(height: 10),

                                  // Section Support
                                  _buildSectionCard(context, 'Support & Paramètres', appState, children: [
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.gauge,
                                      title: S.of(context).serviceStatus,
                                      appState: appState,
                                      iconColor: Colors.red,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ServiceStatusPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.chat_bubble_text_fill,
                                      title: S.of(context).support,
                                      appState: appState,
                                      iconColor: Colors.green,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SupportPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.star_fill,
                                      iconColor: CupertinoColors.systemYellow,
                                      title: S.of(context).rateApp,
                                      appState: appState,
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _requestReview(context);
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.settings,
                                      title: S.of(context).settings,
                                      appState: appState,
                                      iconColor: Colors.grey,
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
                                  ]),

                                  const SizedBox(height: 10),

                                  // Section À propos
                                  _buildSectionCard(context, S.of(context).about, appState, children: [
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.arrow_up_doc_fill,
                                      title: S.of(context).changelog,
                                      appState: appState,
                                      iconColor: Colors.amber,
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          builder: (BuildContext context) {
                                            return SizedBox(
                                              height: MediaQuery.of(context).size.height * 0.8,
                                              child: const ChangelogPage(),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildMenuTile(
                                      context,
                                      icon: CupertinoIcons.info_circle_fill,
                                      title: S.of(context).about,
                                      appState: appState,
                                      iconColor: Colors.blue,
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
                                  ]),

                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, AppState appState, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 60);
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AppState appState,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w400,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
