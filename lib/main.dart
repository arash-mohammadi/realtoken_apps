import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/structure/home_page.dart';
import 'api/data_manager.dart';
import 'settings/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart'; // Import du fichier généré pour les traductions
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Import du package pour le splashscreen
import 'app_state.dart'; // Import the global AppState
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); // Préserver le splash screen natif

  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Hive.initFlutter(),
  ]);

  // Conditionner le chargement de FMTC uniquement si l'application n'est pas exécutée sur le Web
  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('mapStore').manage.create();
  }

  await Future.wait([
    Hive.openBox('realTokens'),
    Hive.openBox('balanceHistory'),
    Hive.openBox('walletValueArchive'),
    Hive.openBox('customInitPrices'),
    Hive.openBox('YamMarket'),
  ]);

  // Initialisation de SharedPreferences et DataManager
  final dataManager = DataManager();
  // Charger les premières opérations en parallèle
  await Future.wait([
    dataManager.updateGlobalVariables(),
    dataManager.loadSelectedCurrency(),
    dataManager.loadUserIdToAddresses(),
  ]);

  FlutterNativeSplash.remove(); // Supprimer le splash screen natif après l'initialisation

  // Ensuite, exécuter fetchAndCalculateData une fois que les précédentes sont terminées
  dataManager.fetchAndStorePropertiesForSale();
  await dataManager.fetchAndCalculateData();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager), // Utilisez ici la même instance
        ChangeNotifierProvider(create: (_) => AppState()), // AppState for global settings
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late DataManager dataManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialiser le DataManager ou le récupérer via Provider si déjà initialisé
    dataManager = Provider.of<DataManager>(context, listen: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'application est revenue au premier plan
      _reloadData();
    }
  }

  void _reloadData() async {
    // Recharger les données nécessaires
    await Future.wait([
      dataManager.updateGlobalVariables(),
      dataManager.loadSelectedCurrency(),
      dataManager.loadUserIdToAddresses(),
    ]);
    await dataManager.fetchAndCalculateData();
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
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: appState.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: const MyHomePage(),
        );
      },
    );
  }
}
