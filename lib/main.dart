import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/services/google_drive_service.dart';
import 'package:realtokens/structure/home_page.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'managers/data_manager.dart';
import 'settings/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app_state.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 Importation de dotenv

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load(fileName: "env_config.txt"); // 🔥 Nouveau fichier
    debugPrint("✅ Variables d'environnement chargées avec succès !");
  } catch (e) {
    debugPrint("❌ Erreur lors du chargement de dotenv: $e");
  }

  Parameters.initialize(); // 🔥 Initialise les valeurs de `Parameters`

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint("✅ Firebase initialisé !");
    }
  } catch (e, stacktrace) {
    debugPrint("❌ Erreur Firebase : $e");
    debugPrint("📌 Stacktrace : $stacktrace");
  }


  await Hive.initFlutter();

  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('mapStore').manage.create();
  }

  await Future.wait([
    Hive.openBox('realTokens'),
    Hive.openBox('balanceHistory'),
    Hive.openBox('walletValueArchive'),
    Hive.openBox('roiValueArchive'),
    Hive.openBox('apyValueArchive'),
    Hive.openBox('customInitPrices'),
    Hive.openBox('YamMarket'),
    Hive.openBox('YamHistory'),
  ]);

  final dataManager = DataManager();
  final currencyProvider = CurrencyProvider();

  // ✅ Attendre que `loadSelectedCurrency()` récupère la bonne valeur avant de démarrer l'app
  await currencyProvider.loadSelectedCurrency();

  final prefs = await SharedPreferences.getInstance();
  final bool autoSyncEnabled = prefs.getBool('autoSync') ?? false;

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()), // ✅ Assurez-vous que CurrencyProvider est bien ici
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MyApp(autoSyncEnabled: autoSyncEnabled),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool autoSyncEnabled;
  const MyApp({super.key, required this.autoSyncEnabled});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late DataManager dataManager;
  final bool _requireConsent = false;
  DateTime? _lastSyncTime;
  final _googleDriveService = GoogleDriveService();
  bool _isGoogleDriveConnected = false;
  bool _autoSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    dataManager = Provider.of<DataManager>(context, listen: false);
    _checkGoogleDriveConnection();
    _autoSyncEnabled = widget.autoSyncEnabled;
    if (!kIsWeb) {
    initOneSignal();
  } else {
    debugPrint("🚫 OneSignal non activé sur le Web.");
  }
  }

  Future<void> _checkGoogleDriveConnection() async {
    await _googleDriveService.initDrive();
    setState(() {
      _isGoogleDriveConnected = _googleDriveService.isGoogleDriveConnected();
    });
  }

  void initOneSignal() {
    if (kIsWeb) {
    debugPrint("🚫 OneSignal désactivé sur le Web");
    return; // Ne pas exécuter OneSignal sur le Web
  }
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(_requireConsent);
    OneSignal.initialize("e7059f66-9c12-4d21-a078-edaf1a203dea");
    OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('Notification reçue en premier plan : ${event.notification.jsonRepresentation()}');
      event.preventDefault();
      event.notification.display();
    });
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('Notification cliquée : ${event.notification.jsonRepresentation()}');
    });
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint('Utilisateur inscrit aux notifications : ${state.current.jsonRepresentation()}');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadData();
    }
  }

  void _reloadData() async {
    debugPrint("🔄 Vérification avant mise à jour des données...");
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    await _loadAutoSyncPreference(); // 🔥 Charger la valeur de autoSync depuis SharedPreferences

    await Future.wait([
      dataManager.updateMainInformations(),
      dataManager.updateSecondaryInformations(context),
      currencyUtils.loadSelectedCurrency(),
      dataManager.loadUserIdToAddresses(),
    ]);
    await dataManager.fetchAndCalculateData();

    if (_autoSyncEnabled) {
      print("🟢 AutoSync activé: $_autoSyncEnabled");
      _checkAndSyncGoogleDrive();
    } else {
      print("🔴 AutoSync désactivé: $_autoSyncEnabled");
    }
  }

  Future<void> _loadAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool autoSync = prefs.getBool('autoSync') ?? false;
    print("⚙️ Chargement autoSync: $autoSync");
    setState(() {
      _autoSyncEnabled = autoSync;
    });
  }

  Future<void> _checkAndSyncGoogleDrive() async {
    if (_isGoogleDriveConnected) {
      final now = DateTime.now();
      if (_lastSyncTime == null || now.difference(_lastSyncTime!).inHours > 1) {
        debugPrint("🔄 Synchronisation avec Google Drive en cours...");
        await _googleDriveService.syncGoogleDrive(context);
        _lastSyncTime = now;
      } else {
        debugPrint("✅ Synchronisation non nécessaire");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'RealToken mobile app',
          locale: Locale(appState.selectedLanguage),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: getLightTheme(appState.primaryColor),
          darkTheme: getDarkTheme(appState.primaryColor),
          themeMode: appState.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: const MyHomePage(),
        );
      },
    );
  }
}
