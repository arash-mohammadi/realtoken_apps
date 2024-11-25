import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[100],
  cardColor: Colors.white,
  dialogBackgroundColor: Colors.white,
  secondaryHeaderColor:Colors.grey[300] ,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.black), // Couleur principale
    bodyMedium: TextStyle(color: Colors.grey[750]), // Couleur secondaire pour les textes
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: Colors.blue,
    unselectedItemColor: Colors.grey,
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.white,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.black,
  cardColor: Colors.grey[900],
  dialogBackgroundColor: Colors.black,
    secondaryHeaderColor:Color.fromARGB(255, 78, 78, 78).withOpacity(0.4) ,

  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white), // Couleur principale
    bodyMedium: TextStyle(color: Colors.grey[400]), // Couleur secondaire pour les textes
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: Colors.blueAccent,
    unselectedItemColor: Colors.grey,
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.grey[900],
  ),
);
