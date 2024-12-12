import 'dart:convert';
import 'dart:io'; // Pour détecter la plateforme (Android/iOS)
import 'package:realtokens_apps/app_state.dart';
import 'package:realtokens_apps/utils/parameters.dart';
import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens_apps/api/data_manager.dart';
import 'package:realtokens_apps/generated/l10n.dart'; // Importer le fichier généré pour les traductions
import 'package:hive/hive.dart'; // Import pour Hive
import 'package:provider/provider.dart';
import '/api/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path; // Ajoute cet import pour manipuler les chemins de fichiers
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic> _currencies = {}; // Stockage des devises
  bool _notificationsEnabled = true; // Valeur par défaut

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Charger les paramètres initiaux
    _fetchCurrencies(); // Récupérer les devises lors de l'initialisation
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    try {
      // Fetch the subscription status, default to false if null
      bool isSubscribed = OneSignal.User.pushSubscription.optedIn ?? false;
      setState(() {
        _notificationsEnabled = isSubscribed;
      });
    } catch (e) {
      print("Error fetching notification status: $e");
      setState(() {
        _notificationsEnabled = false; // Default to false in case of an error
      });
    }
  }

// Activer ou désactiver les notifications
  Future<void> _toggleNotificationStatus(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    try {
      if (value) {
        // Activer les notifications
        OneSignal.User.pushSubscription.optIn();
      } else {
        // Désactiver les notifications
        OneSignal.User.pushSubscription.optOut();
      }
    } catch (e) {
      print("Erreur lors de la mise à jour du statut des notifications : $e");
    }
  }

  // Fonction pour charger les paramètres stockés localement (conversion des m² et devise)
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      Parameters.convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
      Parameters.selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';
    });
  }

  // Fonction pour récupérer les devises depuis l'API
  Future<void> _fetchCurrencies() async {
    try {
      final currencies = await ApiService.fetchCurrencies(); // Utilisez l'instance pour appeler la méthode
      setState(() {
        _currencies = currencies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load currencies')),
      );
    }
  }

  // Fonction pour sauvegarder la conversion des sqft en m²
  Future<void> _saveConvertToSquareMeters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('convertToSquareMeters', value);
  }

  // Fonction pour sauvegarder la devise sélectionnée
  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);

    // Mettre à jour le taux de conversion et le symbole dans DataManager
    final dataManager = Provider.of<DataManager>(context, listen: false);
    dataManager.updateConversionRate(currency, Parameters.selectedCurrency, _currencies);

    setState(() {
      Parameters.selectedCurrency = currency; // Mettre à jour la devise sélectionnée localement
    });
  }

  // Fonction pour vider le cache et les données
  Future<void> _clearCacheAndData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Réinitialiser toutes les préférences

    final dataManager = DataManager();
    await dataManager.resetData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache and data cleared')),
    );
  }

  dynamic sanitizeValue(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, sanitizeValue(val)));
    } else if (value is List) {
      return value.map(sanitizeValue).toList();
    } else if (value is num) {
      // Convertir en double (y compris NaN géré comme 0.0)
      return value.isNaN ? 0.0 : value.toDouble();
    }
    return value;
  }

  Future<void> shareZippedHiveData() async {
    try {
      // Ouvrir les deux boîtes Hive
      var balanceHistoryBox = await Hive.openBox('balanceHistory');
      var walletValueArchiveBox = await Hive.openBox('walletValueArchive');
      var customInitPricesBox = await Hive.openBox('customInitPrices');
      var customRoiBox = await Hive.openBox('roiValueArchive');
      var customApyBox = await Hive.openBox('apyValueArchive');
      var customYamBox = await Hive.openBox('YamMarket');

      // Récupérer les données de chaque boîte Hive
      Map balanceHistoryData = sanitizeValue(balanceHistoryBox.toMap());
      Map walletValueArchiveData = sanitizeValue(walletValueArchiveBox.toMap());
      Map customInitPricesData = sanitizeValue(customInitPricesBox.toMap());
      Map customRoiData = sanitizeValue(customRoiBox.toMap());
      Map customApyData = sanitizeValue(customApyBox.toMap());
      Map customYamData = sanitizeValue(customYamBox.toMap());

      // Convertir les données en JSON
      String balanceHistoryJson = jsonEncode(balanceHistoryData);
      String walletValueArchiveJson = jsonEncode(walletValueArchiveData);
      String customInitPricesJson = jsonEncode(customInitPricesData);
      String customRoiJson = jsonEncode(customRoiData);
      String customApyJson = jsonEncode(customApyData);
      String customYamJson = jsonEncode(customYamData);

      // Obtenir les données des SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> ethAddresses = prefs.getStringList('evmAddresses') ?? [];
      String? userIdToAddresses = prefs.getString('userIdToAddresses');
      String? selectedCurrency = prefs.getString('selectedCurrency');
      bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;

      // Créer un Map pour les préférences
      Map<String, dynamic> preferencesData = {
        'ethAddresses': ethAddresses,
        'userIdToAddresses': userIdToAddresses,
        'selectedCurrency': selectedCurrency,
        'convertToSquareMeters': convertToSquareMeters
      };

      // Convertir les préférences en JSON
      String preferencesJson = jsonEncode(preferencesData);

      // Obtenir le répertoire des documents de l'application
      Directory directory = await getApplicationDocumentsDirectory();

      // Créer des fichiers JSON dans ce répertoire pour chaque boîte et les préférences
      String balanceHistoryFilePath = path.join(directory.path, 'balanceHistoryBackup.json');
      String walletValueArchiveFilePath = path.join(directory.path, 'walletValueArchiveBackup.json');
      String customInitPricesFilePath = path.join(directory.path, 'customInitPricesBackup.json');
      String customRoiFilePath = path.join(directory.path, 'customRoiBackup.json');
      String customApyFilePath = path.join(directory.path, 'customApyBackup.json');
      String customYamFilePath = path.join(directory.path, 'customYamBackup.json');

      String preferencesFilePath = path.join(directory.path, 'preferencesBackup.json');

      File balanceHistoryFile = File(balanceHistoryFilePath);
      File walletValueArchiveFile = File(walletValueArchiveFilePath);
      File customInitPricesFile = File(customInitPricesFilePath);
      File customRoiFile = File(customRoiFilePath);
      File customApyFile = File(customApyFilePath);
      File customYamFile = File(customYamFilePath);

      File preferencesFile = File(preferencesFilePath);

      // Écrire les données JSON dans les fichiers
      await balanceHistoryFile.writeAsString(balanceHistoryJson);
      await walletValueArchiveFile.writeAsString(walletValueArchiveJson);
      await customInitPricesFile.writeAsString(customInitPricesJson);
      await customRoiFile.writeAsString(customRoiJson);
      await customApyFile.writeAsString(customApyJson);
      await customYamFile.writeAsString(customYamJson);

      await preferencesFile.writeAsString(preferencesJson);

      // Créer un fichier ZIP dans le même répertoire
      String zipFilePath = path.join(directory.path, 'realToken_Backup.zip');

      // Utiliser archive pour compresser les fichiers JSON dans un fichier zip
      final archive = Archive();

      // Ajouter chaque fichier JSON à l'archive
      archive.addFile(ArchiveFile('balanceHistoryBackup.json', balanceHistoryFile.lengthSync(), balanceHistoryFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('walletValueArchiveBackup.json', walletValueArchiveFile.lengthSync(), walletValueArchiveFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('customInitPricesBackup.json', customInitPricesFile.lengthSync(), customInitPricesFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('customRoiBackup.json', customRoiFile.lengthSync(), customRoiFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('customApyBackup.json', customApyFile.lengthSync(), customApyFile.readAsBytesSync()));
      archive.addFile(ArchiveFile('customYamBackup.json', customYamFile.lengthSync(), customYamFile.readAsBytesSync()));

      archive.addFile(ArchiveFile('preferencesBackup.json', preferencesFile.lengthSync(), preferencesFile.readAsBytesSync()));

      // Écrire le fichier zip
      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFilePath);
      for (var file in [balanceHistoryFile, walletValueArchiveFile, customInitPricesFile, customRoiFile, customApyFile, customYamFile, preferencesFile]) {
        zipEncoder.addFile(file);
      }
      zipEncoder.close();

      // Partager le fichier ZIP
      XFile xfile = XFile(zipFilePath);
      await Share.shareXFiles([xfile]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data successfully exported')),
      );
    } catch (e) {
      print('Erreur lors du partage des données Hive : $e');
    }
  }

  Future<void> importZippedHiveData() async {
    try {
      // Utiliser file_picker pour permettre à l'utilisateur de sélectionner un fichier ZIP
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'], // Limiter à l'importation de fichiers ZIP
      );

      if (result != null) {
        // Obtenir le fichier sélectionné
        File zipFile = File(result.files.single.path!);

        // Lire le fichier ZIP et le décompresser
        List<int> bytes = zipFile.readAsBytesSync();
        Archive archive = ZipDecoder().decodeBytes(bytes);

        // Parcourir les fichiers dans l'archive ZIP
        for (ArchiveFile file in archive) {
          List<int> jsonBytes = file.content as List<int>;
          String jsonContent = utf8.decode(jsonBytes);

          if (file.name == 'balanceHistoryBackup.json') {
            // Décoder et insérer les données dans la boîte 'balanceHistory'
            Map<String, dynamic> balanceHistoryData = jsonDecode(jsonContent);
            var balanceHistoryBox = await Hive.openBox('balanceHistory');
            await balanceHistoryBox.putAll(balanceHistoryData);
          } else if (file.name == 'walletValueArchiveBackup.json') {
            // Décoder et insérer les données dans la boîte 'walletValueArchive'
            Map<String, dynamic> walletValueArchiveData = jsonDecode(jsonContent);
            var walletValueArchiveBox = await Hive.openBox('walletValueArchive');
            await walletValueArchiveBox.putAll(walletValueArchiveData);
          } else if (file.name == 'customInitPricesBackup.json') {
            // Décoder et insérer les données dans la boîte 'walletValueArchive'
            Map<String, dynamic> customInitPricesData = jsonDecode(jsonContent);
            var customInitPricesBox = await Hive.openBox('customInitPrices');
            await customInitPricesBox.putAll(customInitPricesData);
          } else if (file.name == 'customRoiBackup.json') {
            // Décoder et insérer les données dans la boîte 'walletValueArchive'
            Map<String, dynamic> customRoiData = jsonDecode(jsonContent);
            var customRoiBox = await Hive.openBox('roiValueArchive');
            await customRoiBox.putAll(customRoiData);
          } else if (file.name == 'customApyBackup.json') {
            // Décoder et insérer les données dans la boîte 'walletValueArchive'
            Map<String, dynamic> customApyData = jsonDecode(jsonContent);
            var customApyBox = await Hive.openBox('apyValueArchive');
            await customApyBox.putAll(customApyData);
          } else if (file.name == 'customYamBackup.json') {
            // Décoder et insérer les données dans la boîte 'walletValueArchive'
            Map<String, dynamic> customYamData = jsonDecode(jsonContent);
            var customYamBox = await Hive.openBox('YamMarket');
            await customYamBox.putAll(customYamData);
          } else if (file.name == 'preferencesBackup.json') {
            // Décoder et insérer les préférences dans SharedPreferences
            Map<String, dynamic> preferencesData = jsonDecode(jsonContent);
            final prefs = await SharedPreferences.getInstance();

            // Restaurer les préférences sauvegardées
            List<String> ethAddresses = List<String>.from(preferencesData['ethAddresses'] ?? []);
            String? userIdToAddresses = preferencesData['userIdToAddresses'];
            String? selectedCurrency = preferencesData['selectedCurrency'];
            bool convertToSquareMeters = preferencesData['convertToSquareMeters'] ?? false;

            // Sauvegarder les préférences restaurées
            await prefs.setStringList('evmAddresses', ethAddresses);
            if (userIdToAddresses != null) await prefs.setString('userIdToAddresses', userIdToAddresses);
            if (selectedCurrency != null) await prefs.setString('selectedCurrency', selectedCurrency);
            await prefs.setBool('convertToSquareMeters', convertToSquareMeters);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data successfully imported')),
        );
        print('Données importées avec succès depuis le fichier ZIP.');
      } else {
        print('Importation annulée par l\'utilisateur.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error during importation')),
      );
      print('Erreur lors de l\'importation des données Hive depuis le fichier ZIP : $e');
    }
    Utils.loadData(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accéder à l'état global

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: Text(S.of(context).settingsTitle), // Utilisation de la traduction
      ),
      body: SingleChildScrollView(
        // Ajout du scroll
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                title: Text(
                  'Enable Notifications',
                  style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
                ),
                trailing: Transform.scale(
                  scale: 0.8, // Réduit la taille du Switch
                  child: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      _toggleNotificationStatus(value);
                    },
                    activeColor: Colors.blue, // Couleur active
                    inactiveThumbColor: Colors.grey, // Couleur inactive
                  ),
                ),
              ),
              const Divider(),

              ListTile(
                title: Text(
                  S.of(context).darkTheme,
                  style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
                ),
                trailing: DropdownButton<String>(
                  value: appState.themeMode,
                  items: [
                    DropdownMenuItem(value: 'light', child: Text(S.of(context).light)),
                    DropdownMenuItem(value: 'dark', child: Text(S.of(context).dark)),
                    DropdownMenuItem(value: 'auto', child: Text('auto')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      appState.updateThemeMode(newValue);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.of(context).themeUpdated(
                                newValue == 'dark'
                                    ? S.of(context).dark
                                    : newValue == 'auto'
                                        ? 'auto'
                                        : S.of(context).light,
                              )),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Divider(),

              ListTile(
                title: Text(
                  S.of(context).language,
                  style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
                ),
                trailing: DropdownButton<String>(
                  value: appState.selectedLanguage,
                  items: Parameters.languages.map((String languageCode) {
                    return DropdownMenuItem<String>(
                      value: languageCode,
                      child: Text(
                        languageCode == 'en'
                            ? S.of(context).english
                            : languageCode == 'fr'
                                ? S.of(context).french
                                : languageCode == 'es'
                                    ? S.of(context).spanish
                                    : languageCode == 'it'
                                        ? S.of(context).italian
                                        : languageCode == 'pt'
                                            ? S.of(context).portuguese
                                            : languageCode == 'zh'
                                                ? S.of(context).chinese
                                                : S.of(context).english,
                        style: TextStyle(fontSize: 15.0 + appState.getTextSizeOffset()),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      appState.updateLanguage(newValue);
                      String languageName;

                      switch (newValue) {
                        case 'en':
                          languageName = S.of(context).english;
                          break;
                        case 'fr':
                          languageName = S.of(context).french;
                          break;
                        case 'es':
                          languageName = S.of(context).spanish;
                          break;
                        case 'it':
                          languageName = S.of(context).italian;
                          break;
                        case 'pt':
                          languageName = S.of(context).portuguese;
                          break;
                        case 'zh':
                          languageName = S.of(context).chinese;
                          break;
                        default:
                          languageName = S.of(context).english;
                          break;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).languageUpdated(languageName))),
                      );
                    }
                  },
                ),
              ),
              const Divider(),

              ListTile(
                title: Text(
                  S.of(context).textSize,
                  style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
                ),
                trailing: DropdownButton<String>(
                  value: appState.selectedTextSize,
                  items: Parameters.textSizeOptions.map((String sizeOption) {
                    return DropdownMenuItem<String>(
                      value: sizeOption,
                      child: Text(
                        sizeOption,
                        style: TextStyle(fontSize: 15.0 + appState.getTextSizeOffset()),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newSize) {
                    if (newSize != null) {
                      appState.updateTextSize(newSize);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Taille du texte mise à jour: $newSize')),
                      );
                    }
                  },
                ),
              ),
              const Divider(),

              ListTile(
                title: Text(
                  S.of(context).currency,
                  style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
                ),
                trailing: _currencies.isNotEmpty
                    ? DropdownButton<String>(
                        value: Parameters.selectedCurrency,
                        items: _currencies.keys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(key.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _saveCurrency(newValue);
                          }
                        },
                      )
                    : const CircularProgressIndicator(),
              ),
              const Divider(),

              ListTile(
                title: Text(
                  S.of(context).convertSqft,
                  style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
                ),
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: Parameters.convertToSquareMeters,
                    onChanged: (value) {
                      setState(() {
                        Parameters.convertToSquareMeters = value;
                      });
                      _saveConvertToSquareMeters(value);
                    },
                    activeColor: Colors.blue,
                    inactiveThumbColor: Colors.grey,
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  // Le texte
                  Text(
                    S.of(context).importExportData,
                    style: TextStyle(
                      fontSize: 16.0 + appState.getTextSizeOffset(),
                    ),
                  ),

                  // Un espace entre le texte et l'icône
                  SizedBox(width: 8.0),

                  // L'icône cliquable
                  IconButton(
                    icon: Icon(Icons.info_outline), // Icône d'information
                    onPressed: () {
                      // Afficher un modal lors du clic
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(S.of(context).aboutImportExportTitle),
                            content: Text(S.of(context).aboutImportExport),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Ferme le modal
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => shareZippedHiveData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      'Exporter',
                      style: TextStyle(color: Colors.white, fontSize: 16.0 + appState.getTextSizeOffset()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => importZippedHiveData(),
                    child: Text(
                      'Importer',
                      style: TextStyle(color: Colors.white, fontSize: 16.0 + appState.getTextSizeOffset()),
                    ),
                  ),
                ],
              ),
              const Divider(),

              const SizedBox(height: 30), // Espacement entre le titre et la jauge

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(S.of(context).confirmAction),
                          content: Text(S.of(context).areYouSureClearData),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(S.of(context).cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _clearCacheAndData();
                              },
                              child: Text(S.of(context).confirm),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(S.of(context).clearCacheData, style: TextStyle(color: Colors.white, fontSize: 16.0 + appState.getTextSizeOffset())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
