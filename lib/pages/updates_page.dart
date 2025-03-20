import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtokens/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart'; // Assurez-vous d'importer votre DataManager
import 'package:realtokens/generated/l10n.dart';
import 'package:show_network_image/show_network_image.dart'; // Import pour les traductions

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
    final appState = Provider.of<AppState>(
        context); // Ajouter cette ligne pour récupérer appState

    if (dataManager.recentUpdates.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
          middle: Text(S.of(context).recentUpdatesTitle),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.refresh_thin,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).noRecentUpdates,
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filtrer les mises à jour en fonction du switch
    List recentUpdatesToShow = showUserTokensOnly
        ? dataManager.recentUpdates.where((update) {
            // Garder uniquement les tokens de l'utilisateur
            return dataManager.portfolio
                .any((token) => token['shortName'] == update['shortName']);
          }).toList()
        : dataManager.recentUpdates;

    // Regrouper les mises à jour par date puis par token
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedUpdates = {};
    for (var update in recentUpdatesToShow) {
      final String dateKey = DateTime.parse(update['timsync'])
          .toLocal()
          .toString()
          .split(' ')[0]; // Date sans l'heure
      final String tokenKey =
          update['shortName'] ?? S.of(context).unknownTokenName;

      // Si la date n'existe pas, on la crée
      if (!groupedUpdates.containsKey(dateKey)) {
        groupedUpdates[dateKey] = {};
      }

      // Si le token n'existe pas pour cette date, on le crée
      if (!groupedUpdates[dateKey]!.containsKey(tokenKey)) {
        groupedUpdates[dateKey]![tokenKey] = [];
      }

      // Ajouter les updates pour ce token
      groupedUpdates[dateKey]![tokenKey]!.add(update);
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Text(S.of(context).recentUpdatesTitle),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // En-tête avec le Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
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
                      fontSize: 15 + appState.getTextSizeOffset(),
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
                  ),
                ],
              ),
            ),
            
            // Liste des mises à jour
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: groupedUpdates.keys.length,
                itemBuilder: (context, dateIndex) {
                  final String dateKey = groupedUpdates.keys.elementAt(dateIndex);
                  final Map<String, List<Map<String, dynamic>>> updatesForDate =
                      groupedUpdates[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête de date sticky
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          dateKey,
                          style: TextStyle(
                            fontSize: 17 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ),
                      
                      // Cartes des tokens
                      ...updatesForDate.entries.map((tokenEntry) {
                        final String tokenName = tokenEntry.key;
                        final List<Map<String, dynamic>> updatesForToken = tokenEntry.value;
                        final String imageUrl = updatesForToken.first['imageLink'] ??
                            S.of(context).noImageAvailable;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBackground.resolveFrom(context),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image du token
                                  if (imageUrl != S.of(context).noImageAvailable)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
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
                                                placeholder: (context, url) => const Center(
                                                  child: CupertinoActivityIndicator(),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    const Icon(CupertinoIcons.exclamationmark_triangle),
                                              ),
                                      ),
                                    ),
                                  
                                  // Contenu de la carte
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nom du token
                                        Text(
                                          tokenName,
                                          style: TextStyle(
                                            fontSize: 17 + appState.getTextSizeOffset(),
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.label.resolveFrom(context),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Mises à jour
                                        ...updatesForToken.map((update) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: CupertinoColors.systemGrey6.resolveFrom(context),
                                                borderRadius: BorderRadius.circular(8),
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
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
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
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        CupertinoIcons.arrow_right,
                                                        size: 12,
                                                        color: CupertinoColors.systemGrey,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        update['formattedNewValue'],
                                                        style: TextStyle(
                                                          fontSize: 14 + appState.getTextSizeOffset(),
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
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
