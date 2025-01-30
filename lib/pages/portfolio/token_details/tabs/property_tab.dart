import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:realtokens/utils/utils.dart';

Widget buildPropertiesTab(BuildContext context, Map<String, dynamic> token, bool convertToSquareMeters) {
  final appState = Provider.of<AppState>(context, listen: false);

// Méthode pour construire les lignes de détails
Widget _buildDetailRow(BuildContext context, String label, String value, {IconData? icon, bool isNegative = false, Color? color, Widget? trailing}) {
  final appState = Provider.of<AppState>(context, listen: false);

  // Ajout du signe "-" et de la couleur rouge si isNegative est true
  final displayValue = isNegative ? '-$value' : value;
  final valueStyle = TextStyle(
    fontSize: 13 + appState.getTextSizeOffset(),
    color: isNegative ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color, // couleur rouge si isNegative
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) // Affiche l'icône si elle est spécifiée
              Icon(icon, size: 18, color: Colors.blueGrey),
            if (isNegative) // Affiche la puce rouge uniquement si isNegative est true
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: color ?? Colors.red,
                ),
              ),
            SizedBox(width: icon != null || isNegative ? 8 : 0), // Espacement conditionnel entre l'icône et le texte
            Text(
              label,
              style: TextStyle(
                fontWeight: isNegative ? FontWeight.normal : FontWeight.bold,
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
            SizedBox(
              height: 16 + appState.getTextSizeOffset(), // Hauteur constante pour le trailing
              child: trailing ?? SizedBox(), // Si trailing est null, on met un espace vide
            ),
          ],
        ),
        Row(
          children: [
            Text(displayValue, style: valueStyle), // Texte avec style conditionnel
          ],
        ),
      ],
    ),
  );
}


  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).characteristics,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          context,
          S.of(context).constructionYear,
          token['constructionYear']?.toString() ?? S.of(context).notSpecified,
          icon: Icons.calendar_today,
        ),
        _buildDetailRow(
          context,
          S.of(context).propertyType,
          Parameters.getPropertyTypeName(token['propertyType'] ?? -1, context),
          icon: Icons.home,
        ),
        _buildDetailRow(
          context,
          S.of(context).rentalType,
          token['rentalType']?.toString() ?? S.of(context).notSpecified,
          icon: Icons.assignment,
        ),
        _buildDetailRow(
          context,
          S.of(context).bedroomBath,
          token['bedroomBath']?.toString() ?? S.of(context).notSpecified,
          icon: Icons.bed,
        ),
        _buildDetailRow(
          context,
          S.of(context).lotSize,
          Utils.formatSquareFeet(
            token['lotSize']?.toDouble() ?? 0,
            convertToSquareMeters,
          ),
          icon: Icons.landscape,
        ),
        _buildDetailRow(
          context,
          S.of(context).squareFeet,
          Utils.formatSquareFeet(
            token['squareFeet']?.toDouble() ?? 0,
            convertToSquareMeters,
          ),
          icon: Icons.square_foot,
        ),
        const SizedBox(height: 10),
        Text(
          S.of(context).rents,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15 + appState.getTextSizeOffset(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Row(
              children: [
                Icon(
                  Icons.apartment,
                  size: 18,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  ' ${S.of(context).rentedUnits}',
                  style: TextStyle(
                    fontSize: 13 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Spacer(),
            Text(
              '${token['rentedUnits'] ?? 0.0} / ${token['totalUnits'] ?? 0.0}',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
            ),
            const SizedBox(width: 10),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Utils.getRentalStatusColor(
                  token['rentedUnits'] ?? 0,
                  token['totalUnits'] ?? 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 18,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  ' ${S.of(context).rentStartDate}',
                  style: TextStyle(
                    fontSize: 13 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Spacer(),
            Text(
              Utils.formatReadableDate(token['rentStartDate'] ?? ''),
              style: TextStyle(
                fontSize: 13 + appState.getTextSizeOffset(),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DateTime.parse(token['rentStartDate'] ?? '').isBefore(DateTime.now()) ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          context,
          S.of(context).section8paid,
          '${((token['section8paid']) / (token['grossRentMonth']) * 100).toStringAsFixed(2)}%',
          icon: Icons.attach_money,
        ),
      ],
    ),
  );

  
}