import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/components/info_card_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Widget _buildApplicationHeader(BuildContext context, double textSizeOffset) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.app_badge,
            color: CupertinoColors.systemBlue.resolveFrom(context),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            S.of(context).application,
            style: TextStyle(
              fontSize: 20 + Provider.of<AppState>(context, listen: false).getTextSizeOffset() + textSizeOffset,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThanksHeader(BuildContext context, double textSizeOffset) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.heart_fill,
            color: CupertinoColors.systemPink.resolveFrom(context),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            S.of(context).thanks,
            style: TextStyle(
              fontSize: 20 + Provider.of<AppState>(context, listen: false).getTextSizeOffset() + textSizeOffset,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomThanksCard(BuildContext context, double textSizeOffset) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).thankYouMessage,
              style: TextStyle(
                fontSize: 15 + Provider.of<AppState>(context, listen: false).getTextSizeOffset() + textSizeOffset,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 12),
            _buildTextWithIcon(
              context, 
              textSizeOffset,
              CupertinoIcons.person_3,
              S.of(context).specialThanks,
              FontWeight.normal,
              CupertinoColors.systemGreen.resolveFrom(context),
            ),
            const SizedBox(height: 12),
            _buildTextWithIcon(
              context, 
              textSizeOffset,
              CupertinoIcons.lab_flask,
              S.of(context).specialThanksJojodunet,
              FontWeight.normal,
              CupertinoColors.systemOrange.resolveFrom(context),
            ),
            const SizedBox(height: 12),
            _buildTextWithIcon(
              context, 
              textSizeOffset,
              CupertinoIcons.money_dollar_circle,
              S.of(context).thanksDonators,
              FontWeight.bold,
              CupertinoColors.systemYellow.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithIcon(
    BuildContext context,
    double textSizeOffset,
    IconData icon,
    String text,
    FontWeight fontWeight,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset() + textSizeOffset,
              fontWeight: fontWeight,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final textSizeOffset = Provider.of<AppState>(context, listen: false).getTextSizeOffset();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          S.of(context).about,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListView(
            children: <Widget>[
              // Section Application avec icône
              _buildApplicationHeader(context, textSizeOffset),
              
              InfoCardWidgets.buildInfoCard(
                context,
                icon: CupertinoIcons.info_circle,
                title: "Name",
                subtitle: S.of(context).appName,
                textSizeOffset: textSizeOffset,
              ),
              
              FutureBuilder<String>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  return InfoCardWidgets.buildInfoCard(
                    context,
                    icon: CupertinoIcons.checkmark_seal,
                    title: S.of(context).version,
                    subtitle: snapshot.data ?? 'Chargement...',
                    textSizeOffset: textSizeOffset,
                  );
                },
              ),
              
              InfoCardWidgets.buildInfoCard(
                context,
                icon: CupertinoIcons.person,
                title: S.of(context).author,
                subtitle: 'Byackee',
                textSizeOffset: textSizeOffset,
                linkUrl: 'https://linktr.ee/byackee',
              ),
              
              InfoCardWidgets.buildLinkCard(
                context,
                title: 'Linktree',
                url: 'https://linktr.ee/byackee',
                textSizeOffset: textSizeOffset,
                icon: CupertinoIcons.link,
              ),

              const Divider(height: 1),

              // Section Remerciements avec icône cœur
              _buildThanksHeader(context, textSizeOffset),
              
              _buildCustomThanksCard(context, textSizeOffset),
            ],
          ),
        ),
      ),
    );
  }
}
