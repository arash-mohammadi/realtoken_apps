import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart'; // Pour accéder à AppState
import 'package:realtokens/generated/l10n.dart'; // Importer pour les traductions
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/url_utils.dart'; // Importer pour accéder à l'offset de texte

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          S.of(context).about,
          style: const TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListView(
            children: <Widget>[
              // Section Nom et Version de l'application
              _buildSectionHeader(
                context,
                S.of(context).application,
                appState.getTextSizeOffset(),
              ),
              _buildInfoCard(
                context,
                CupertinoIcons.info_circle,
                S.of(context).appName,
                'RealToken App',
                appState.getTextSizeOffset(),
              ),
              FutureBuilder<String>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  return _buildInfoCard(
                    context,
                    CupertinoIcons.checkmark_seal,
                    S.of(context).version,
                    snapshot.data ?? 'Chargement...',
                    appState.getTextSizeOffset(),
                  );
                },
              ),
              _buildInfoCard(
                context,
                CupertinoIcons.person,
                S.of(context).author,
                'Byackee',
                appState.getTextSizeOffset(),
              ),

              // Lien personnel
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 16.0),
                child: GestureDetector(
                  onTap: () => UrlUtils.launchURL('https://linktr.ee/byackee'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.link,
                            color: CupertinoColors.systemBlue.resolveFrom(context),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'My linktree',
                            style: TextStyle(
                              fontSize: 15 + appState.getTextSizeOffset(),
                              color: CupertinoColors.systemBlue.resolveFrom(context),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.systemGrey.resolveFrom(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Section Remerciements
              _buildSectionHeader(
                context,
                S.of(context).thanks,
                appState.getTextSizeOffset(),
              ),
              _buildThanksCard(
                context,
                S.of(context).thankYouMessage,
                S.of(context).specialThanks,
                appState.getTextSizeOffset(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, double textSizeOffset) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20 + textSizeOffset,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    double textSizeOffset,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.systemBlue.resolveFrom(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15 + textSizeOffset,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14 + textSizeOffset,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
  
  Widget _buildThanksCard(
    BuildContext context,
    String title,
    String subtitle,
    double textSizeOffset,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.heart_fill,
                color: CupertinoColors.systemPink.resolveFrom(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15 + textSizeOffset,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14 + textSizeOffset,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
