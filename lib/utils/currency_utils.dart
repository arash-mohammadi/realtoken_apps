import 'package:intl/intl.dart';

class CurrencyUtils {
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
      return formatCurrency(value, symbol); // Affiche le montant formaté si visible
    } else {
      String formattedValue = formatCurrency(value, symbol); // Format le montant normalement
      return '*' * formattedValue.length; // Retourne une série d'astérisques de la même longueur
    }
  }
}
