import 'package:flutter/material.dart';

Color generateColor(int index) {
  final List<Color> colorPalette = [
    const Color(0xFF007AFF), // iOS blue
    const Color(0xFF34C759), // iOS green
    const Color(0xFFFF9500), // iOS orange
    const Color(0xFFFF2D55), // iOS red
    const Color(0xFF5856D6), // iOS purple
    const Color(0xFFAF52DE), // iOS pink
    const Color(0xFF5AC8FA), // iOS light blue
    const Color(0xFFFF3B30), // iOS red alternative
    const Color(0xFFFFCC00), // iOS yellow
    const Color(0xFF4CD964), // iOS green alternative
  ];

  return colorPalette[index % colorPalette.length];
}

Color _getPropertyColor(int propertyType) {
  switch (propertyType) {
    case 1:
      return const Color(0xFF007AFF); // iOS blue
    case 2:
      return const Color(0xFF34C759); // iOS green
    case 3:
      return const Color(0xFFFF9500); // iOS orange
    case 4:
      return const Color(0xFFFF2D55); // iOS red
    case 5:
      return const Color(0xFF5856D6); // iOS purple
    case 6:
      return const Color(0xFFFFCC00); // iOS yellow
    case 7:
      return const Color(0xFF5AC8FA); // iOS light blue
    case 8:
      return const Color(0xFFAF52DE); // iOS pink
    case 9:
      return const Color(0xFFFF3B30); // iOS red alternative
    case 10:
      return const Color(0xFF4CD964); // iOS green alternative
    case 11:
      return const Color(0xFF00C7BE); // iOS teal
    case 12:
      return const Color(0xFF32ADE6); // iOS blue-green
    default:
      return Colors.grey.shade500;
  }
}
