import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/managers/data_manager.dart';

// Fonction pour récupérer la couleur enregistrée
Future<Color> getSavedPrimaryColor() async {
  final prefs = await SharedPreferences.getInstance();
  String colorName = prefs.getString('primaryColor') ?? 'blue';
  return _getColorFromName(colorName);
}

// Fonction pour enregistrer la couleur choisie
Future<void> savePrimaryColor(String colorName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('primaryColor', colorName);
}

// Fonction pour convertir le nom de la couleur en objet Color
Color _getColorFromName(String colorName) {
  switch (colorName) {
    case 'blue':
      return Colors.blue;
    case 'orange':
      return Color.fromRGBO(237, 137, 32, 1);
    case 'pink':
      return Colors.purple;
    case 'green':
      return Colors.green;
    case 'grey':
      return Colors.grey;
    case 'blueGrey':
      return Colors.blueGrey;
    case 'red':
      return Colors.red;
    case 'teal':
      return Colors.teal;
    case 'indigo':
      return Colors.indigo;
    case 'amber':
      return Colors.amber;
    case 'deepPurple':
      return Colors.deepPurple;
    case 'lightBlue':
      return Colors.lightBlue;
    case 'lime':
      return Colors.lime;
    case 'brown':
      return Colors.brown;
    case 'cyan':
      return Colors.cyan;
    default:
      return Colors.blue;
  }
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  bool isDarkTheme = false;
  String themeMode = 'auto'; // light, dark, auto
  String selectedTextSize = 'normal'; // Default text size
  String selectedLanguage = 'en'; // Default language
  List<String>? evmAddresses; // Variable for storing EVM addresses
  Color _primaryColor = Colors.blue; // Default primary color
  bool _showAmounts = true; // Par défaut, les montants sont visibles
  DataManager? dataManager; // Référence au DataManager

  // Variables de paramètres du portfolio
  bool _showTotalInvested = false;
  bool _showNetTotal = true;
  double _manualAdjustment = 0.0;
  bool _showYamProjection = true;
  double _initialInvestmentAdjustment = 0.0;

  AppState() {
    _loadSettings();
    WidgetsBinding.instance.addObserver(this); // Add observer to listen to system changes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer when AppState is disposed
    super.dispose();
  }

  Color get primaryColor => _primaryColor;
  bool get showAmounts => _showAmounts; // Getter pour accéder à l'état

  // Getters pour les paramètres du portfolio
  bool get showTotalInvested => _showTotalInvested;
  bool get showNetTotal => _showNetTotal;
  double get manualAdjustment => _manualAdjustment;
  bool get showYamProjection => _showYamProjection;
  double get initialInvestmentAdjustment => _initialInvestmentAdjustment;

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    themeMode = prefs.getString('themeMode') ?? 'auto'; // Load theme mode
    selectedTextSize = prefs.getString('textSize') ?? 'normal';
    selectedLanguage = prefs.getString('language') ?? 'en';
    evmAddresses = prefs.getStringList('evmAddresses'); // Load EVM addresses
    _primaryColor = await getSavedPrimaryColor(); // Load primary color
    _showAmounts = prefs.getBool('showAmounts') ?? true; // Charge la préférence du montant affiché

    // Charger les paramètres du portfolio
    _showTotalInvested = prefs.getBool('showTotalInvested') ?? false;
    _showNetTotal = prefs.getBool('showNetTotal') ?? true;
    _manualAdjustment = prefs.getDouble('manualAdjustment') ?? 0.0;
    _showYamProjection = prefs.getBool('showYamProjection') ?? true;
    _initialInvestmentAdjustment = prefs.getDouble('initialInvestmentAdjustment') ?? 0.0;

    _applyTheme(); // Apply the theme based on the loaded themeMode
    notifyListeners(); // Notify listeners to rebuild widgets
  }

  void updatePrimaryColor(String colorName) async {
    await savePrimaryColor(colorName);
    _primaryColor = _getColorFromName(colorName);
    notifyListeners(); // 🔥 Met à jour immédiatement l'UI avec la nouvelle couleur
  }

  void toggleShowAmounts() async {
    _showAmounts = !_showAmounts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAmounts', _showAmounts); // Sauvegarde la préférence utilisateur
    notifyListeners(); // Notifie les widgets dépendants
  }

  // Update theme mode and save to SharedPreferences
  void updateThemeMode(String mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);

    _applyTheme(); // Apply the theme immediately after updating the mode
    notifyListeners(); // Notify listeners about the theme mode change
  }

  // Apply theme based on themeMode
  void _applyTheme() {
    if (themeMode == 'auto') {
      // Detect system theme and apply
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      isDarkTheme = brightness == Brightness.dark;
    } else {
      isDarkTheme = themeMode == 'dark';
    }
    notifyListeners();
  }

  // Overriding the didChangePlatformBrightness method to detect theme changes dynamically
  @override
  void didChangePlatformBrightness() {
    if (themeMode == 'auto') {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      isDarkTheme = brightness == Brightness.dark;
      notifyListeners(); // Notify listeners to rebuild UI when system theme changes
    }
  }

  // Update dark/light theme directly and save to SharedPreferences (for manual switch)
  void updateTheme(bool value) async {
    isDarkTheme = value;
    themeMode = value ? 'dark' : 'light'; // Set theme mode based on manual selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    await prefs.setString('themeMode', themeMode); // Save theme mode
    notifyListeners(); // Notify listeners about the theme change
  }

  // Update language and save to SharedPreferences
  void updateLanguage(String languageCode) async {
    selectedLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners(); // Notify listeners about the language change
  }

  // Update text size and save to SharedPreferences
  void updateTextSize(String textSize) async {
    selectedTextSize = textSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('textSize', textSize);
    notifyListeners(); // Notify listeners about the text size change
  }

  // Get text size offset based on selected size
  double getTextSizeOffset() {
    switch (selectedTextSize) {
      case 'verySmall':
        return -4.0; // Reduce font size
      case 'small':
        return -2.0; // Reduce font size
      case 'big':
        return 2.0; // Increase font size
      case 'veryBig':
        return 4.0; // Increase font size
      default:
        return 0.0; // Default size
    }
  }

  // Ajuster la réactivité de l'APY
  void adjustApyReactivity(double reactivityLevel) {
    // Vérifier que dataManager est disponible
    if (dataManager == null) {
      debugPrint("❌ DataManager n'est pas initialisé dans AppState");
      return;
    }

    // Appeler la méthode adjustApyReactivity du DataManager
    dataManager!.adjustApyReactivity(reactivityLevel);

    // Pas besoin de notifier ici car le DataManager le fera
  }

  // Méthodes pour mettre à jour les paramètres du portfolio
  void updateShowTotalInvested(bool value) async {
    _showTotalInvested = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTotalInvested', value);
    notifyListeners();
  }

  void updateShowNetTotal(bool value) async {
    _showNetTotal = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNetTotal', value);
    notifyListeners();
  }

  void updateManualAdjustment(double value) async {
    _manualAdjustment = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('manualAdjustment', value);
    notifyListeners();
  }

  void updateShowYamProjection(bool value) async {
    _showYamProjection = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showYamProjection', value);
    notifyListeners();
  }

  void updateInitialInvestmentAdjustment(double value) async {
    _initialInvestmentAdjustment = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('initialInvestmentAdjustment', value);
    notifyListeners();
  }
}
