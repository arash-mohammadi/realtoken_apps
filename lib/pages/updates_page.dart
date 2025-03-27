// ignore_for_file: all

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtokens/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart'; // Assurez-vous d'importer votre DataManager
import 'package:realtokens/generated/l10n.dart';
import 'package:show_network_image/show_network_image.dart'; // Import pour les traductions
import 'dart:ui';



class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  _UpdatesPageState createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool showUserTokensOnly = false; // Ajout du booléen pour le switch
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Déclencher la récupération des données après le rendu initial de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context); // Ajouter cette ligne pour récupérer appState
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (dataManager.recentUpdates.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.8),
          border: null,
          middle: Text(
            S.of(context).recentUpdatesTitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17 + appState.getTextSizeOffset(),
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.refresh_thin,
                size: 56,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 20),
              Text(
                S.of(context).noRecentUpdates,
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filtrer les mises à jour en fonction du switch
    List<Map<String, dynamic>> recentUpdatesToShow = showUserTokensOnly
        ? dataManager.recentUpdates.where((Map<String, dynamic> update) {
            // Garder uniquement les tokens de l'utilisateur
            return dataManager.portfolio.any((Map<String, dynamic> token) => token['shortName'] == update['shortName']);
          }).toList()
        : List<Map<String, dynamic>>.from(dataManager.recentUpdates);

    // Regrouper les mises à jour par date puis par token
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedUpdates = {};
    for (Map<String, dynamic> update in recentUpdatesToShow) {
      final String dateKey = DateTime.parse(update['timsync']).toLocal().toString().split(' ')[0]; // Date sans l'heure
      final String tokenKey = update['shortName'] ?? S.of(context).unknownTokenName;

      // Si la date n'existe pas, on la crée
      if (!groupedUpdates.containsKey(dateKey)) {
        groupedUpdates[dateKey] = <String, List<Map<String, dynamic>>>{};
      }

      // Si le token n'existe pas pour cette date, on le crée
      if (!groupedUpdates[dateKey]!.containsKey(tokenKey)) {
        groupedUpdates[dateKey]![tokenKey] = <Map<String, dynamic>>[];
      }

      // Ajouter les updates pour ce token
      groupedUpdates[dateKey]![tokenKey]!.add(update);
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.8),
        border: null,
        middle: Text(
          S.of(context).recentUpdatesTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 + appState.getTextSizeOffset(),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).portfolio,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      CupertinoSwitch(
                        value: showUserTokensOnly,
                        onChanged: (value) {
                          setState(() {
                            showUserTokensOnly = value;
                          });
                        },
                        activeColor: CupertinoColors.activeBlue,
                        trackColor: isDarkMode 
                            ? CupertinoColors.systemGrey4.darkColor 
                            : CupertinoColors.systemGrey5.color,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Liste des mises à jour
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: groupedUpdates.keys.length,
                itemBuilder: (context, dateIndex) {
                  final String dateKey = groupedUpdates.keys.elementAt(dateIndex);
                  final Map<String, List<Map<String, dynamic>>> updatesForDate = groupedUpdates[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGroupedBackground.resolveFrom(context).withOpacity(0.7),
                              border: Border(
                                bottom: BorderSide(
                                  color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              dateKey,
                              style: TextStyle(
                                fontSize: 17 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Cartes des tokens
                      ...updatesForDate.entries.map((MapEntry<String, List<Map<String, dynamic>>> tokenEntry) {
                        final String tokenName = tokenEntry.key;
                        final List<Map<String, dynamic>> updatesForToken = tokenEntry.value;
                        final String imageUrl = updatesForToken.first['imageLink'] ?? S.of(context).noImageAvailable;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground.resolveFrom(context),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey6.resolveFrom(context).withOpacity(0.8),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image du token
                                  if (imageUrl != S.of(context).noImageAvailable)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: kIsWeb
                                            ? ShowNetworkImage(
                                                imageSrc: imageUrl,
                                                mobileBoxFit: BoxFit.cover,
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Center(
                                                  child: CupertinoActivityIndicator(
                                                    radius: 14,
                                                    color: CupertinoColors.activeBlue,
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: CupertinoColors.systemGrey6,
                                                  child: const Icon(
                                                    CupertinoIcons.exclamationmark_triangle,
                                                    color: CupertinoColors.systemGrey,
                                                    size: 36,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),

                                  // Contenu de la carte
                                  Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nom du token
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: CupertinoColors.activeBlue,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              tokenName,
                                              style: TextStyle(
                                                fontSize: 18 + appState.getTextSizeOffset(),
                                                fontWeight: FontWeight.bold,
                                                color: CupertinoColors.label.resolveFrom(context),
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),

                                        // Mises à jour
                                        ...updatesForToken.map((Map<String, dynamic> update) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: CupertinoColors.systemGrey6.resolveFrom(context),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    update['formattedKey'],
                                                    style: TextStyle(
                                                      fontSize: 15 + appState.getTextSizeOffset(),
                                                      fontWeight: FontWeight.w600,
                                                      color: CupertinoColors.systemBlue,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        update['formattedOldValue'],
                                                        style: TextStyle(
                                                          fontSize: 14 + appState.getTextSizeOffset(),
                                                          decoration: TextDecoration.lineThrough,
                                                          color: CupertinoColors.systemGrey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: CupertinoColors.systemGrey5.resolveFrom(context),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Icon(
                                                          CupertinoIcons.arrow_right,
                                                          size: 12,
                                                          color: CupertinoColors.systemGrey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        update['formattedNewValue'],
                                                        style: TextStyle(
                                                          fontSize: 15 + appState.getTextSizeOffset(),
                                                          fontWeight: FontWeight.w600,
                                                          color: CupertinoColors.label.resolveFrom(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
