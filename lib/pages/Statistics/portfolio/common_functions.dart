import 'package:flutter/material.dart';

Color generateColor(int index) {
  final hue = ((index * 57) + 193 * (index % 3)) % 360;
  final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
  final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
  return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness)
      .toColor();
}

Color _getPropertyColor(int propertyType) {
  switch (propertyType) {
    case 1:
      return Colors.blue;
    case 2:
      return Colors.green;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.red;
    case 5:
      return Colors.purple;
    case 6:
      return Colors.yellow;
    case 7:
      return Colors.teal;
    case 8:
      return Colors.brown;
    case 9:
      return Colors.pink;
    case 10:
      return Colors.cyan;
    case 11:
      return Colors.lime;
    case 12:
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}
