import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:realtokens/api/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

class Utils {
  static final logger = Logger(); // Initialiser une instance de logger

  static double getAppBarHeight(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; // Hauteur en dips
    double screenWidth = MediaQuery.of(context).size.width; // Largeur en dips
    double pixelRatio = MediaQuery.of(context).devicePixelRatio; // Ratio de densité
    double longestSide = MediaQuery.of(context).size.longestSide * pixelRatio;
    double shortestSide = MediaQuery.of(context).size.shortestSide * pixelRatio;

    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

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

  static Future<void> loadData(BuildContext context) async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.updateGlobalVariables();
    dataManager.fetchRentData(); //f Charger les données de loyer
    dataManager.fetchAndCalculateData(); // Charger les données du portefeuille
    dataManager.updatedDetailRentVariables();
    dataManager.fetchAndStoreAllTokens();
    dataManager.fetchAndStoreYamMarketData();
    dataManager.fetchAndStorePropertiesForSale();
  }

  static Future<void> refreshData(BuildContext context) async {
    // Forcer la mise à jour des données en appelant les méthodes de récupération avec forceFetch = true
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.updateGlobalVariables(forceFetch: true);
    await dataManager.fetchRentData(forceFetch: true);
    await dataManager.fetchAndCalculateData(forceFetch: true);
    await dataManager.updatedDetailRentVariables(forceFetch: true);
    await dataManager.fetchAndStoreAllTokens();
    await dataManager.fetchAndStoreYamMarketData();
    await dataManager.fetchAndStorePropertiesForSale();
  }

  // Méthode pour formater une date en une chaîne compréhensible
  static String formatReadableDate(String dateString) {
    try {
      // Parse la date depuis le format donné
      DateTime parsedDate = DateTime.parse(dateString);

      // Formater la date dans un format lisible, par exemple: 1 Dec 2024
      String formattedDate = DateFormat('d MMM yyyy').format(parsedDate);

      return formattedDate;
    } catch (e) {
      // Si une erreur survient, retourne la date d'origine
      return dateString;
    }
  }

  // Fonction utilitaire pour formater la date et le montant
  static String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  static String formatReadableDateWithTime(String dateString) {
    try {
      // Parse la date en UTC
      DateTime parsedDate = DateTime.parse(dateString).toUtc();
      // Convertit en heure locale
      DateTime localDate = parsedDate.toLocal();

      // Formate la date avec l'heure dans un format lisible: 1 Dec 2024 14:30:45
      String formattedDate = DateFormat('d MMM yyyy HH:mm:ss').format(localDate);

      return formattedDate;
    } catch (e) {
      // Si une erreur survient, retourne la date d'origine
      return dateString;
    }
  }

  static Future<void> launchURL(String url) async {
    logger.i('Tentative d\'ouverture de l\'URL: $url'); // Log pour capturer l'URL
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView, // Ouvre dans un navigateur externe
        );
      } else {
        throw 'Impossible de lancer l\'URL : $url';
      }
    } catch (e) {
      logger.i('Erreur lors du lancement de l\'URL: $e');
    }
  }

// Fonction pour obtenir un offset de taille de texte à partir des préférences
  static Future<double> getTextSizeOffset() async {
    final prefs = await SharedPreferences.getInstance();
    String selectedTextSize = prefs.getString('selectedTextSize') ?? 'normal'; // 'normal' par défaut

    switch (selectedTextSize) {
      case 'petit':
        return -2.0; // Réduire la taille de 2
      case 'grand':
        return 2.0; // Augmenter la taille de 2
      default:
        return 0.0; // Taille normale
    }
  }

// Fonction de formatage des valeurs monétaires avec des espaces pour les milliers
  static String formatCurrency(double value, String symbol) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: symbol, // Utilisation du symbole sélectionné
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // Méthode pour formater ou masquer les montants en série de ****
  static String getFormattedAmount(double value, String symbol, bool showAmount) {
    if (showAmount) {
      return Utils.formatCurrency(value, symbol); // Affiche le montant formaté si visible
    } else {
      String formattedValue = Utils.formatCurrency(value, symbol); // Format le montant normalement
      return '*' * formattedValue.length; // Retourne une série d'astérisques de la même longueur
    }
  }

// Fonction pour extraire le nom de la ville à partir du fullName
  static String extractCity(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.length >= 2 ? parts[1].trim() : S.current.unknownCity; // Traduction pour "Ville inconnue"
  }

  static Color shadeColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
      1,
    );
  }

  static int weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekNumber;
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

  // Fonction pour convertir les sqft en m²
static String formatSquareFeet(double sqft, bool convertToSquareMeters) {
  if (convertToSquareMeters) {
    double squareMeters = sqft * 0.092903; // Conversion des pieds carrés en m²
    return '${squareMeters.toStringAsFixed(2)} m²';
  } else {
    return '${sqft.toStringAsFixed(2)} sqft';
  }
}

}
