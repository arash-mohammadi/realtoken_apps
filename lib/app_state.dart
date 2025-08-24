import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meprop_asset_tracker/managers/data_manager.dart';
import 'package:meprop_asset_tracker/utils/preference_keys.dart';

// Fonction pour récupérer la couleur enregistrée
Future<Color> getSavedPrimaryColor() async {
  final prefs = await SharedPreferences.getInstance();
  String colorName = prefs.getString(PreferenceKeys.primaryColor) ?? 'cyan';
  return _getColorFromName(colorName);
}

// Fonction pour enregistrer la couleur choisie
Future<void> savePrimaryColor(String colorName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PreferenceKeys.primaryColor, colorName);
}

// Fonction pour convertir le nom de la couleur en objet Color
Color _getColorFromName(String colorName) {
  switch (colorName) {
    case 'blue':
      return Color(0xff4276fe);
    case 'cyan':
      return Color(0xff0f7581);
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
    default:
      return Color(0xff4276fe); // Default to blue if unknown
  }
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  bool isDarkTheme = false;
  String themeMode = 'auto'; // light, dark, auto
  String selectedTextSize = 'normal'; // Default text size
  String selectedLanguage = 'en'; // Default language
  List<String>? evmAddresses; // Variable for storing EVM addresses
  Color _primaryColor = Color(0xff0f7581);
  bool _showAmounts = true; // Par défaut, les montants sont visibles
  DataManager? dataManager; // Référence au DataManager
  // -------- Demo Auth --------
  DemoUser? _currentUser; // Utilisateur connecté (mock)
  bool _isUserRestored = false; // Track if user restoration is complete
  DemoUser? get currentUser => _isUserRestored ? _currentUser : null;
  bool get isUserRestored => _isUserRestored;

  // Variables de paramètres du portfolio
  bool _showTotalInvested = false;
  bool _showNetTotal = true;
  double _manualAdjustment = 0.0;
  bool _showYamProjection = true;
  double _initialInvestmentAdjustment = 0.0;

  // --- Gestion du compteur d'ouvertures de l'app pour la popup dons ---
  int _appOpenCount = 0;
  int _lastDonationPopupTimestamp = 0; // Timestamp de la dernière fois que la popup a été affichée
  int get appOpenCount => _appOpenCount;

  // Optimisation: Éviter les notifyListeners multiples
  bool _batchUpdateInProgress = false;

  /// Retourne true si la popup dons doit être affichée (après 10 ouvertures ET au moins 1h depuis la dernière)
  bool get shouldShowDonationPopup {
    if (_appOpenCount < 10) return false;

    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final oneHourInMillis = 60 * 60 * 1000; // 1 heure en millisecondes

    // Vérifier si au moins 1 heure s'est écoulée depuis la dernière popup
    return (currentTimestamp - _lastDonationPopupTimestamp) >= oneHourInMillis;
  }

  AppState() {
    DataManager.appStateRef = this; // تنظیم reference در DataManager
    _loadSettings();
    _restoreUser();
    loadAppOpenCount(); // Charger le compteur d'ouvertures
    loadLastDonationPopupTimestamp(); // Charger le timestamp de la dernière popup
    incrementAppOpenCount(); // Incrémenter à chaque lancement
    WidgetsBinding.instance.addObserver(this); // Add observer to listen to system changes
  }

  static const String _userPrefsKey = 'currentUser';

  Future<void> _restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userPrefsKey);
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = DemoUser.fromJson(map);
      } catch (_) {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }

    _isUserRestored = true;
    _notifyListenersIfNeeded();
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser == null) {
      await prefs.remove(_userPrefsKey);
    } else {
      await prefs.setString(_userPrefsKey, jsonEncode(_currentUser!.toJson()));
    }
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

    // Regrouper toutes les mises à jour pour éviter les notifications multiples
    batchUpdate(() {
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      themeMode = prefs.getString('themeMode') ?? 'auto'; // Load theme mode
      selectedTextSize = prefs.getString('textSize') ?? 'normal';
      selectedLanguage = prefs.getString('language') ?? 'en';
      evmAddresses = prefs.getStringList('evmAddresses'); // Load EVM addresses
      _showAmounts = prefs.getBool('showAmounts') ?? true; // Charge la préférence du montant affiché

      // Charger les paramètres du portfolio
      _showTotalInvested = prefs.getBool('showTotalInvested') ?? false;
      _showNetTotal = prefs.getBool('showNetTotal') ?? true;
      _manualAdjustment = prefs.getDouble('manualAdjustment') ?? 0.0;
      _showYamProjection = prefs.getBool('showYamProjection') ?? true;
      _initialInvestmentAdjustment = prefs.getDouble('initialInvestmentAdjustment') ?? 0.0;

      _applyTheme(); // Apply the theme based on the loaded themeMode
    });

    // Charger la couleur primaire séparément car elle est asynchrone
    _primaryColor = await getSavedPrimaryColor(); // Load primary color
    _notifyListenersIfNeeded();
  }

  void updatePrimaryColor(String colorName) async {
    await savePrimaryColor(colorName);
    _primaryColor = _getColorFromName(colorName);
    _notifyListenersIfNeeded(); // 🔥 Met à jour immédiatement l'UI avec la nouvelle couleur
  }

  void toggleShowAmounts() async {
    _showAmounts = !_showAmounts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAmounts', _showAmounts); // Sauvegarde la préférence utilisateur
    _notifyListenersIfNeeded(); // Notifie les widgets dépendants
  }

  // Update theme mode and save to SharedPreferences
  void updateThemeMode(String mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);

    _applyTheme(); // Apply the theme immediately after updating the mode
    _notifyListenersIfNeeded(); // Notify listeners about the theme mode change
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
    _notifyListenersIfNeeded();
  }

  // Overriding the didChangePlatformBrightness method to detect theme changes dynamically
  @override
  void didChangePlatformBrightness() {
    if (themeMode == 'auto') {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      isDarkTheme = brightness == Brightness.dark;
      _notifyListenersIfNeeded(); // Notify listeners to rebuild UI when system theme changes
    }
  }

  // Update dark/light theme directly and save to SharedPreferences (for manual switch)
  void updateTheme(bool value) async {
    isDarkTheme = value;
    themeMode = value ? 'dark' : 'light'; // Set theme mode based on manual selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    await prefs.setString('themeMode', themeMode); // Save theme mode
    _notifyListenersIfNeeded(); // Notify listeners about the theme change
  }

  // Update language and save to SharedPreferences
  void updateLanguage(String languageCode) async {
    selectedLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    _notifyListenersIfNeeded(); // Notify listeners about the language change
  }

  // Update text size and save to SharedPreferences
  void updateTextSize(String textSize) async {
    selectedTextSize = textSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('textSize', textSize);
    _notifyListenersIfNeeded(); // Notify listeners about the text size change
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
    _notifyListenersIfNeeded();
  }

  void updateShowNetTotal(bool value) async {
    _showNetTotal = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNetTotal', value);
    _notifyListenersIfNeeded();
  }

  void updateManualAdjustment(double value) async {
    _manualAdjustment = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('manualAdjustment', value);
    _notifyListenersIfNeeded();
  }

  void updateShowYamProjection(bool value) async {
    _showYamProjection = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showYamProjection', value);
    _notifyListenersIfNeeded();
  }

  void updateInitialInvestmentAdjustment(double value) async {
    _initialInvestmentAdjustment = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('initialInvestmentAdjustment', value);
    _notifyListenersIfNeeded();
  }

  Future<void> loadAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    _appOpenCount = prefs.getInt('appOpenCount') ?? 0;
  }

  Future<void> incrementAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    _appOpenCount = (prefs.getInt('appOpenCount') ?? 0) + 1;
    await prefs.setInt('appOpenCount', _appOpenCount);
  }

  Future<void> loadLastDonationPopupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    _lastDonationPopupTimestamp = prefs.getInt('lastDonationPopupTimestamp') ?? 0;
  }

  Future<void> updateLastDonationPopupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    _lastDonationPopupTimestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('lastDonationPopupTimestamp', _lastDonationPopupTimestamp);
  }

  // Méthode pour regrouper les mises à jour
  void batchUpdate(Function() updates) {
    _batchUpdateInProgress = true;
    updates();
    _batchUpdateInProgress = false;
    notifyListeners();
  }

  void _notifyListenersIfNeeded() {
    if (!_batchUpdateInProgress) {
      notifyListeners();
    }
  }

  // ================= Demo Login (Mock) =================
  Future<bool> login(String username, String password) async {
    // Normaliser pour comparaison
    final u = username.trim();
    if (u.toLowerCase() == 'russell' && password == '1234') {
      // Add wallet if not present
      const russellWallet = '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3';
      final addresses = <String>{
        ...(evmAddresses ?? ['0xDEMO1234...'])
      };
      addresses.add(russellWallet);
      // Sync to SharedPreferences and userIdToAddresses
      await DataManager().saveWalletForUserId(userId: 'Russell', address: russellWallet);
      // پر کردن داده‌های analytic با دیتای ماک برای راسل (فقط اگر داده‌ای موجود نباشد)
      DataManager().setMockAnalyticsDataForRussell();

      // تنظیم مستقیم موجودی کیف پول Russell
      final dataManager = DataManager();
      dataManager.gnosisUsdcBalance = 2000.0;
      dataManager.gnosisXdaiBalance = 0.0;
      dataManager.gnosisRegBalance = 0.0;
      dataManager.gnosisVaultRegBalance = 0.0;
      _currentUser = DemoUser(
        username: 'Russell',
        fullName: 'Russell Anderson',
        email: 'russell@example.com',
        preferredFiat: 'USD',
        avatarAssetPath: 'assets/logo_community.png',
        lastLogin: DateTime.now(),
        addresses: addresses.toList(),
        // Valeurs mock cohérentes pour le dashboard
        totalPortfolioValue: 127_540.62,
        netProfit: 8_245.12,
        investedCapital: 119_295.50,
      );
      await _persistUser();
      _notifyListenersIfNeeded();
      return true;
    }
    return false;
  }

  void logout() async {
    // برای Russell، داده‌ها را حفظ می‌کنیم و فقط وضعیت لاگین را تغییر می‌دهیم
    if (_currentUser?.username == 'Russell') {
      // داده‌های Russell را حفظ می‌کنیم، فقط addresses را پاک می‌کنیم
      _currentUser = _currentUser!.copyWith(addresses: []);
    }
    _currentUser = null;
    await _persistUser();
    _notifyListenersIfNeeded();
  }
}

// ================= DemoUser Model =================
class DemoUser {
  final String username;
  final String fullName;
  final String email;
  final double totalPortfolioValue;
  final double netProfit;
  final double investedCapital;
  final String avatarAssetPath;
  final String preferredFiat;
  final List<String> addresses;
  final DateTime lastLogin;

  DemoUser({
    required this.username,
    required this.fullName,
    required this.email,
    required this.totalPortfolioValue,
    required this.netProfit,
    required this.investedCapital,
    required this.avatarAssetPath,
    required this.preferredFiat,
    required this.addresses,
    required this.lastLogin,
  });

  factory DemoUser.fromJson(Map<String, dynamic> json) {
    return DemoUser(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      totalPortfolioValue: (json['totalPortfolioValue'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      investedCapital: (json['investedCapital'] ?? 0).toDouble(),
      avatarAssetPath: json['avatarAssetPath'] ?? '',
      preferredFiat: json['preferredFiat'] ?? 'USD',
      addresses: (json['addresses'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      lastLogin: DateTime.tryParse(json['lastLogin'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'fullName': fullName,
        'email': email,
        'totalPortfolioValue': totalPortfolioValue,
        'netProfit': netProfit,
        'investedCapital': investedCapital,
        'avatarAssetPath': avatarAssetPath,
        'preferredFiat': preferredFiat,
        'addresses': addresses,
        'lastLogin': lastLogin.toIso8601String(),
      };
}

extension DemoUserCopyWith on DemoUser {
  DemoUser copyWith({
    String? username,
    String? fullName,
    String? email,
    double? totalPortfolioValue,
    double? netProfit,
    double? investedCapital,
    String? avatarAssetPath,
    String? preferredFiat,
    List<String>? addresses,
    DateTime? lastLogin,
    bool? isGuest,
  }) {
    return DemoUser(
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      totalPortfolioValue: totalPortfolioValue ?? this.totalPortfolioValue,
      netProfit: netProfit ?? this.netProfit,
      investedCapital: investedCapital ?? this.investedCapital,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      preferredFiat: preferredFiat ?? this.preferredFiat,
      addresses: addresses ?? this.addresses,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
