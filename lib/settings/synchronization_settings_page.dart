import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/services/google_drive_service.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class SynchronizationSettingsPage extends StatefulWidget {
  @override
  _SynchronizationSettingsPageState createState() => _SynchronizationSettingsPageState();
}

class _SynchronizationSettingsPageState extends State<SynchronizationSettingsPage> {
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  bool _isGoogleDriveConnected = false;
  bool _autoSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleDriveConnection();
    _loadAutoSyncPreference(); // Ajouté ici
  }

  Future<void> _loadAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSyncEnabled = prefs.getBool('autoSync') ?? false;
    });
  }

  Future<void> _checkGoogleDriveConnection() async {
    await _googleDriveService.initDrive();
    setState(() {
      _isGoogleDriveConnected = _googleDriveService.isGoogleDriveConnected();
    });
  }

  Future<void> _toggleGoogleDriveConnection(bool value) async {
    if (value) {
      await _googleDriveService.connectToGoogleDrive();
    } else {
      await _googleDriveService.disconnectFromGoogleDrive();
    }
    _checkGoogleDriveConnection();
  }

  Future<void> _saveAutoSyncPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSync', value);
    setState(() {
      _autoSyncEnabled = value;
    });
  }

  Future<void> _syncWithGoogleDrive() async {
    if (_isGoogleDriveConnected) {
      await _googleDriveService.syncGoogleDrive(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation terminée avec Google Drive')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous à Google Drive avant la synchronisation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.sync,
              color: Colors.blue,
            ),
            SizedBox(width: 8),
            Text(S.of(context).synchronization),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Drive', style: TextStyle(fontSize: 18.0 + appState.getTextSizeOffset())),
                  SizedBox(height: 8),
                  ListTile(
                    title: Text('Connexion Google Drive'),
                    subtitle: Row(
                      children: [
                        Icon(
                          _isGoogleDriveConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _isGoogleDriveConnected ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isGoogleDriveConnected ? 'Connecté' : 'Non connecté',
                          style: TextStyle(color: _isGoogleDriveConnected ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: _isGoogleDriveConnected,
                      onChanged: _toggleGoogleDriveConnection,
                      activeColor: Theme.of(context).primaryColor, // Couleur du bouton en mode activé
                      inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Synchronisation automatique'),
                    trailing: Switch(
                      value: _autoSyncEnabled,
                      onChanged: (value) => _saveAutoSyncPreference(value),
                      activeColor: Theme.of(context).primaryColor,
                      inactiveThumbColor: Colors.grey,
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text(S.of(context).syncWithGoogleDrive),
                    trailing: IconButton(
                      icon: Icon(Icons.sync, color: Colors.blue),
                      onPressed: _syncWithGoogleDrive,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.of(context).localStorage, style: TextStyle(fontSize: 18.0 + appState.getTextSizeOffset())),
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(S.of(context).aboutImportExportTitle),
                                content: Text(S.of(context).aboutImportExport),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
                  SizedBox(height: 16),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    DataFetchUtils.loadData(context);
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
}
