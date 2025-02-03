import 'package:realtokens/generated/l10n.dart';

class LocationUtils {
  static String extractCity(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.length >= 2 ? parts[1].trim() : S.current.unknownCity;
  }

  static String formatSquareFeet(double sqft, bool convertToSquareMeters) {
    if (convertToSquareMeters) {
      double squareMeters = sqft * 0.092903; // Conversion des pieds carrés en m²
      return '${squareMeters.toStringAsFixed(2)} m²';
    } else {
      return '${sqft.toStringAsFixed(2)} sqft';
    }
  }
}
