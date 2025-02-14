import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/pages/dashboard/properties_details_page.dart';
import 'package:realtokens/pages/dashboard/rent_details_page.dart';
import 'package:shimmer/shimmer.dart';

class UIUtils {
  static double getAppBarHeight(BuildContext context) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio; // Ratio de densité
    double longestSide = MediaQuery.of(context).size.longestSide * pixelRatio;
    double shortestSide = MediaQuery.of(context).size.shortestSide * pixelRatio;

    if (kIsWeb) {
      // Taille pour le Web, ajustée pour écrans larges
      return longestSide > 1200 ? kToolbarHeight : kToolbarHeight;
    } else if (Platform.isAndroid) {
      if (shortestSide >= 1500) {
        // Tablettes (toute orientation)
        return kToolbarHeight;
      } else if (longestSide > 2000) {
        // Grands téléphones
        return kToolbarHeight + 15;
      } else {
        // Taille par défaut pour les téléphones standards
        return kToolbarHeight + 10;
      }
    } else if (Platform.isIOS) {
      var orientation = MediaQuery.of(context).orientation;

      if (shortestSide >= 1500) {
        // Tablettes (toute orientation)
        return orientation == Orientation.portrait ? kToolbarHeight : kToolbarHeight; // Exemple d'ajustement en paysage
      } else if (longestSide > 2000) {
        // Grands téléphones
        return orientation == Orientation.portrait ? kToolbarHeight + 40 : kToolbarHeight; // Exemple d'ajustement en paysage
      } else {
        // Taille par défaut pour les téléphones standards
        return orientation == Orientation.portrait ? kToolbarHeight : kToolbarHeight - 10; // Exemple d'ajustement en paysage
      }
    } else {
      // Par défaut pour desktop
      return kToolbarHeight + 20;
    }
  }

  static double getSliverAppBarHeight(BuildContext context) {
    double baseHeight = getAppBarHeight(context);

    double pixelRatio = MediaQuery.of(context).devicePixelRatio; // Ratio de densité
    double longestSide = MediaQuery.of(context).size.longestSide * pixelRatio;
    double shortestSide = MediaQuery.of(context).size.shortestSide * pixelRatio;

    if (kIsWeb) {
      // SliverAppBar pour le Web
      return longestSide > 2500 ? baseHeight + 50 : baseHeight + 50;
    } else if (Platform.isAndroid) {
      if (shortestSide >= 1500) {
        // Tablettes
        return baseHeight + 30;
      } else if (longestSide > 2500) {
        // Grands téléphones
        return baseHeight + 10;
      } else {
        // Taille par défaut
        return baseHeight + 20;
      }
    } else if (Platform.isIOS) {
      var orientation = MediaQuery.of(context).orientation;

      if (shortestSide >= 1500) {
        // Tablettes
        return orientation == Orientation.portrait ? baseHeight + 25 : baseHeight + 25; // Ajustement en paysage pour les tablettes
      } else if (longestSide > 2500) {
        // Grands téléphones
        return orientation == Orientation.portrait ? baseHeight - 15 : baseHeight + 40; // Ajustement en paysage pour les grands téléphones
      } else {
        // Taille par défaut pour téléphones standards
        return orientation == Orientation.portrait ? baseHeight + 30 : baseHeight + 45; // Ajustement en paysage pour téléphones standards
      }
    } else {
      // Par défaut pour desktop
      return baseHeight + 20;
    }
  }

  static Color shadeColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
      1,
    );
  }

// Méthode pour déterminer la couleur de la pastille en fonction du taux de location
  static Color getRentalStatusColor(int rentedUnits, int totalUnits) {
    if (rentedUnits == 0) {
      return Colors.red; // Aucun logement loué
    } else if (rentedUnits == totalUnits) {
      return Colors.green; // Tous les logements sont loués
    } else {
      return Colors.orange; // Partiellement loué
    }
  }

  static Widget buildCard(
    String title,
    IconData icon,
    Widget firstChild,
    List<Widget> otherChildren,
    DataManager dataManager,
    BuildContext context, {
    bool hasGraph = false,
    Widget? rightWidget, // Ajout du widget pour le graphique
  }) {
    final appState = Provider.of<AppState>(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 24 + appState.getTextSizeOffset(),
                      color: getIconColor(title, context), // Appelle une fonction pour déterminer la couleur
                    ),
                    const SizedBox(width: 8), // Espacement entre l'icône et le texte
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 12), // Espacement entre le texte et l'icône
                    if (title == S.of(context).rents)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DashboardRentsDetailsPage(),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.arrow_forward,
                          size: 24, // Taille de l'icône
                          color: Colors.grey, // Couleur de l'icône
                        ),
                      ),
                    if (title == S.of(context).properties)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PropertiesDetailsPage(),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.arrow_forward,
                          size: 24, // Taille de l'icône
                          color: Colors.grey, // Couleur de l'icône
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                firstChild,
                const SizedBox(height: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: otherChildren,
                ),
              ],
            ),
            const Spacer(),
            if (hasGraph && rightWidget != null) rightWidget, // Affiche le graphique
          ],
        ),
      ),
    );
  }

  // Fonction pour obtenir la couleur en fonction du titre traduit
  static Color getIconColor(String title, BuildContext context) {
    final String translatedTitle = title.trim(); // Supprime les espaces éventuels

    if (translatedTitle == S.of(context).rents) {
      return Colors.green;
    } else if (translatedTitle == S.of(context).tokens) {
      return Colors.orange;
    } else if (translatedTitle == S.of(context).rmm) {
      return Colors.teal;
    } else if (translatedTitle == S.of(context).properties) {
      return Colors.blue;
    } else if (translatedTitle == S.of(context).portfolio) {
      return Colors.blueGrey;
    } else {
      return Colors.blue; // Couleur par défaut
    }
  }

  static Widget buildValueBeforeText(BuildContext context, String? value, String text, bool isLoading, {bool highlightPercentage = false}) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    String percentageText = '';
    Color percentageColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    if (highlightPercentage) {
      final regex = RegExp(r'\(([-+]?\d+)%\)');
      final match = regex.firstMatch(text);
      if (match != null) {
        percentageText = match.group(1)!;
        final percentageValue = double.tryParse(percentageText) ?? 0;
        percentageColor = percentageValue >= 0 ? Colors.green : Colors.red;
      }
    }

    return Row(
      children: [
        isLoading
            ? Shimmer.fromColors(
                baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!,
                child: Container(
                  width: 50,
                  height: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                ),
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 16 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
        const SizedBox(width: 6),
        highlightPercentage && percentageText.isNotEmpty
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: text.split('(').first,
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: '($percentageText%)',
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: percentageColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 13 + appState.getTextSizeOffset(),
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
      ],
    );
  }

  static Widget buildTextWithShimmer(String? value, String label, bool isLoading, BuildContext context) {
    final theme = Theme.of(context);

    // Couleurs pour le shimmer adaptées au thème
    final baseColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!;
    final highlightColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey[100]!;

    return Row(
      children: [
        // Partie label statique
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        // Partie valeur dynamique avec ou sans shimmer
        isLoading
            ? Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 100, // Largeur du shimmer
                  height: 16, // Hauteur du shimmer
                  color: baseColor,
                ),
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
      ],
    );
  }
}
