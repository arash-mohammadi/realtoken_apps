import 'dart:convert';

import 'package:flutter/foundation.dart';
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
import 'package:realtokens/models/balance_record.dart';

class SynchronizationSettingsPage extends StatefulWidget {
  const SynchronizationSettingsPage({super.key});

  @override
  _SynchronizationSettingsPageState createState() =>
      _SynchronizationSettingsPageState();
}

class _SynchronizationSettingsPageState
    extends State<SynchronizationSettingsPage> {
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
        const SnackBar(
            content: Text('Synchronisation terminée avec Google Drive')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Connectez-vous à Google Drive avant la synchronisation')),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Drive',
                      style: TextStyle(
                          fontSize: 18.0 + appState.getTextSizeOffset())),
                  SizedBox(height: 8),
                  ListTile(
                    title: Text('Connexion Google Drive'),
                    subtitle: Row(
                      children: [
                        Icon(
                          _isGoogleDriveConnected
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: _isGoogleDriveConnected
                              ? Colors.green
                              : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isGoogleDriveConnected ? 'Connecté' : 'Non connecté',
                          style: TextStyle(
                              color: _isGoogleDriveConnected
                                  ? Colors.green
                                  : Colors.red),
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: _isGoogleDriveConnected,
                      onChanged: _toggleGoogleDriveConnection,
                      activeColor: Theme.of(context)
                          .primaryColor, // Couleur du bouton en mode activé
                      inactiveThumbColor:
                          Colors.grey, // Couleur du bouton en mode désactivé
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.of(context).localStorage,
                          style: TextStyle(
                              fontSize: 18.0 + appState.getTextSizeOffset())),
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title:
                                    Text(S.of(context).aboutImportExportTitle),
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
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0 + appState.getTextSizeOffset()),
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
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0 + appState.getTextSizeOffset()),
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
      debugPrint("=== Étape 1: Ouverture des boîtes Hive ===");
      // Ouverture des boîtes Hive
      var balanceHistoryBox = await Hive.openBox('balanceHistory');
      var walletValueArchiveBox = await Hive.openBox('walletValueArchive');
      var customInitPricesBox = await Hive.openBox('customInitPrices');
      var customRoiBox = await Hive.openBox('roiValueArchive');
      var customApyBox = await Hive.openBox('apyValueArchive');
      var customYamBox = await Hive.openBox('YamMarket');
      var customHealthAndLtvBox =
          await Hive.openBox('HealthAndLtvValueArchive');
      debugPrint("Hive boxes ouverts.");
      debugPrint("Contenu de balanceHistoryBox: ${balanceHistoryBox.toMap()}");
      debugPrint(
          "Contenu de walletValueArchiveBox: ${walletValueArchiveBox.toMap()}");
      debugPrint(
          "Contenu de customInitPricesBox: ${customInitPricesBox.toMap()}");
      debugPrint("Contenu de customRoiBox: ${customRoiBox.toMap()}");
      debugPrint("Contenu de customApyBox: ${customApyBox.toMap()}");
      debugPrint("Contenu de customYamBox: ${customYamBox.toMap()}");
      debugPrint(
          "Contenu de customHealthAndLtvBox : ${customHealthAndLtvBox.toMap()}");

      debugPrint(
          "=== Étape 2: Récupération et sanitisation des données Hive ===");
      Map balanceHistoryData = sanitizeValue(balanceHistoryBox.toMap());
      Map walletValueArchiveData = sanitizeValue(walletValueArchiveBox.toMap());
      Map customInitPricesData = sanitizeValue(customInitPricesBox.toMap());
      Map customRoiData = sanitizeValue(customRoiBox.toMap());
      Map customApyData = sanitizeValue(customApyBox.toMap());
      Map customYamData = sanitizeValue(customYamBox.toMap());
      Map customHealthAndLtvData = sanitizeValue(customHealthAndLtvBox.toMap());
      debugPrint(
          "Données récupérées:\n balanceHistoryData: $balanceHistoryData\n walletValueArchiveData: $walletValueArchiveData\n customInitPricesData: $customInitPricesData\n customRoiData: $customRoiData\n customApyData: $customApyData\n customYamData: $customYamData");

      debugPrint("=== Étape 3: Conversion des données en JSON ===");
      String balanceHistoryJson = jsonEncode(balanceHistoryData);
      String walletValueArchiveJson = jsonEncode(walletValueArchiveData);
      String customInitPricesJson = jsonEncode(customInitPricesData);
      String customRoiJson = jsonEncode(customRoiData);
      String customApyJson = jsonEncode(customApyData);
      String customYamJson = jsonEncode(customYamData);
      String customHealthAndLtvJson = jsonEncode(customHealthAndLtvData);
      debugPrint("JSON balanceHistoryJson: $balanceHistoryJson");
      debugPrint("JSON walletValueArchiveJson: $walletValueArchiveJson");
      debugPrint("JSON customInitPricesJson: $customInitPricesJson");
      debugPrint("JSON customRoiJson: $customRoiJson");
      debugPrint("JSON customApyJson: $customApyJson");
      debugPrint("JSON customYamJson: $customYamJson");
      debugPrint("JSON customHealthAndLtvJson: $customHealthAndLtvJson");

      // Récupérer et convertir les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> ethAddresses = prefs.getStringList('evmAddresses') ?? [];
      String? userIdToAddresses = prefs.getString('userIdToAddresses');
      String? selectedCurrency = prefs.getString('selectedCurrency');
      bool convertToSquareMeters =
          prefs.getBool('convertToSquareMeters') ?? false;
      Map<String, dynamic> preferencesData = {
        'ethAddresses': ethAddresses,
        'userIdToAddresses': userIdToAddresses,
        'selectedCurrency': selectedCurrency,
        'convertToSquareMeters': convertToSquareMeters
      };
      String preferencesJson = jsonEncode(preferencesData);
      debugPrint("JSON preferencesJson: $preferencesJson");

      debugPrint("=== Étape 4: Création et écriture des fichiers JSON ===");
      // Obtenir le répertoire de documents
      Directory directory = await getApplicationDocumentsDirectory();
      String balanceHistoryFilePath =
          path.join(directory.path, 'balanceHistoryBackup.json');
      String walletValueArchiveFilePath =
          path.join(directory.path, 'walletValueArchiveBackup.json');
      String customInitPricesFilePath =
          path.join(directory.path, 'customInitPricesBackup.json');
      String customRoiFilePath =
          path.join(directory.path, 'customRoiBackup.json');
      String customApyFilePath =
          path.join(directory.path, 'customApyBackup.json');
      String customYamFilePath =
          path.join(directory.path, 'customYamBackup.json');
      String customHealthAndLtvFilePath =
          path.join(directory.path, 'customHealthAndLtvBackup.json');
      String preferencesFilePath =
          path.join(directory.path, 'preferencesBackup.json');

      File balanceHistoryFile = File(balanceHistoryFilePath);
      File walletValueArchiveFile = File(walletValueArchiveFilePath);
      File customInitPricesFile = File(customInitPricesFilePath);
      File customRoiFile = File(customRoiFilePath);
      File customApyFile = File(customApyFilePath);
      File customYamFile = File(customYamFilePath);
      File customHealthAndLtvFile = File(customHealthAndLtvFilePath);
      File preferencesFile = File(preferencesFilePath);

      await balanceHistoryFile.writeAsString(balanceHistoryJson);
      await walletValueArchiveFile.writeAsString(walletValueArchiveJson);
      await customInitPricesFile.writeAsString(customInitPricesJson);
      await customRoiFile.writeAsString(customRoiJson);
      await customApyFile.writeAsString(customApyJson);
      await customYamFile.writeAsString(customYamJson);
      await customHealthAndLtvFile.writeAsString(customHealthAndLtvJson);
      await preferencesFile.writeAsString(preferencesJson);

      debugPrint("Fichiers JSON écrits:");
      debugPrint(
          "balanceHistory: $balanceHistoryFilePath (taille: ${balanceHistoryFile.lengthSync()} octets)");
      debugPrint(
          "walletValueArchive: $walletValueArchiveFilePath (taille: ${walletValueArchiveFile.lengthSync()} octets)");
      debugPrint(
          "customInitPrices: $customInitPricesFilePath (taille: ${customInitPricesFile.lengthSync()} octets)");
      debugPrint(
          "customRoi: $customRoiFilePath (taille: ${customRoiFile.lengthSync()} octets)");
      debugPrint(
          "customApy: $customApyFilePath (taille: ${customApyFile.lengthSync()} octets)");
      debugPrint(
          "customYam: $customYamFilePath (taille: ${customYamFile.lengthSync()} octets)");
      debugPrint(
          "customHealthAndLtv: $customHealthAndLtvFilePath (taille: ${customHealthAndLtvFile.lengthSync()} octets)");
      debugPrint(
          "preferences: $preferencesFilePath (taille: ${preferencesFile.lengthSync()} octets)");

      debugPrint("=== Étape 5: Construction de l'archive ZIP ===");
      final archive = Archive();
      archive.addFile(ArchiveFile(
        'balanceHistoryBackup.json',
        balanceHistoryFile.lengthSync(),
        balanceHistoryFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'walletValueArchiveBackup.json',
        walletValueArchiveFile.lengthSync(),
        walletValueArchiveFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'customInitPricesBackup.json',
        customInitPricesFile.lengthSync(),
        customInitPricesFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'customRoiBackup.json',
        customRoiFile.lengthSync(),
        customRoiFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'customApyBackup.json',
        customApyFile.lengthSync(),
        customApyFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'customYamBackup.json',
        customYamFile.lengthSync(),
        customYamFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'customHealthAndLtvBackup.json',
        customHealthAndLtvFile.lengthSync(),
        customHealthAndLtvFile.readAsBytesSync(),
      ));
      archive.addFile(ArchiveFile(
        'preferencesBackup.json',
        preferencesFile.lengthSync(),
        preferencesFile.readAsBytesSync(),
      ));
      debugPrint(
          "Archive construite avec succès. Nombre de fichiers ajoutés: ${archive.length}");

      debugPrint("=== Étape 6: Encodage de l'archive en ZIP ===");
      String zipFilePath = path.join(directory.path, 'realToken_Backup.zip');
      final zipData = ZipEncoder().encode(archive);
      File(zipFilePath).writeAsBytesSync(zipData);
      debugPrint(
          "Fichier ZIP créé: $zipFilePath (taille: ${File(zipFilePath).lengthSync()} octets)");

      debugPrint("=== Étape 7: Partage du fichier ZIP ===");
      XFile xfile = XFile(zipFilePath);
      await Share.shareXFiles(
        [xfile],
        sharePositionOrigin: Rect.fromCenter(
          center: MediaQuery.of(context).size.center(Offset.zero),
          width: 100,
          height: 100,
        ),
      );
      debugPrint("Fichier ZIP partagé avec succès.");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data successfully exported')),
      );
    } catch (e) {
      debugPrint("Erreur lors du partage des données Hive : $e");
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
        List<int> bytes;
        if (kIsWeb) {
          bytes = result.files.single.bytes!;
        } else {
          File zipFile = File(result.files.single.path!);
          bytes = await zipFile.readAsBytes();
        }

        // Lire le fichier ZIP et le décompresser
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
            try {
              debugPrint("📥 Début de l'importation de walletValueArchiveBackup.json");
              
              // Ouvrir les deux boîtes Hive
              var walletValueArchiveBox = await Hive.box('walletValueArchive');
              var balanceHistoryBox = await Hive.box('balanceHistory');
              
              // Décoder le contenu JSON
              dynamic decodedData = jsonDecode(jsonContent);
              debugPrint("📊 Type de données décodées: ${decodedData.runtimeType}");
              
              // Préparer les données pour la sauvegarde
              List<dynamic> recordsToSave;
              
              if (decodedData is Map) {
                debugPrint("🗺️ Données reçues sous forme de Map");
                
                // Si les données sont une Map, chercher la clé balanceHistory_totalWalletValue
                if (decodedData.containsKey('balanceHistory_totalWalletValue')) {
                  recordsToSave = decodedData['balanceHistory_totalWalletValue'];
                  debugPrint("✅ Clé 'balanceHistory_totalWalletValue' trouvée avec ${recordsToSave.length} enregistrements");
                } else {
                  // Si la clé n'existe pas, utiliser toutes les valeurs de la Map
                  recordsToSave = decodedData.values.expand((v) => v is List ? v : [v]).toList();
                  debugPrint("⚠️ Clé 'balanceHistory_totalWalletValue' non trouvée, utilisation de l'ensemble des valeurs: ${recordsToSave.length} enregistrements");
                }
              } else if (decodedData is List) {
                debugPrint("📋 Données reçues sous forme de Liste avec ${decodedData.length} éléments");
                recordsToSave = decodedData;
              } else {
                debugPrint("⚠️ Format de données non reconnu: ${decodedData.runtimeType}");
                throw Exception("Format de données non supporté");
              }
              
              // Convertir les enregistrements en objets BalanceRecord
              List<BalanceRecord> balanceRecords = recordsToSave
                  .map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson)))
                  .toList();
              
              debugPrint("✅ Conversion effectuée: ${balanceRecords.length} objets BalanceRecord créés");
              
              // Convertir en JSON pour la sauvegarde
              List<Map<String, dynamic>> balanceHistoryJsonToSave =
                  balanceRecords.map((record) => record.toJson()).toList();
              
              // Sauvegarder dans les deux boîtes
              await walletValueArchiveBox.put('balanceHistory_totalWalletValue', balanceHistoryJsonToSave);
              await balanceHistoryBox.put('balanceHistory_totalWalletValue', balanceHistoryJsonToSave);
              
              debugPrint("✅ Sauvegarde terminée dans les deux boîtes Hive");
              
              // Mettre à jour le DataManager avec les nouvelles données
              final appState = Provider.of<AppState>(context, listen: false);
              if (appState.dataManager != null) {
                appState.dataManager!.walletBalanceHistory = balanceRecords;
                appState.dataManager!.balanceHistory = List.from(balanceRecords);
                appState.dataManager!.notifyListeners();
                debugPrint("✅ DataManager mis à jour avec ${balanceRecords.length} enregistrements");
              }
              
            } catch (e) {
              debugPrint("❌ Erreur lors de l'importation de walletValueArchiveBackup.json: $e");
              rethrow;
            }
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
          } else if (file.name == 'customHealthAndLtvBackup.json') {
            // Décoder et insérer les données dans la boîte 'HealthAndLtvValueArchive'
            Map<String, dynamic> customHealthAndLtvData =
                jsonDecode(jsonContent);
            var customHealthAndLtvBox =
                await Hive.openBox('HealthAndLtvValueArchive');
            await customHealthAndLtvBox.putAll(customHealthAndLtvData);
          } else if (file.name == 'preferencesBackup.json') {
            // Décoder et insérer les préférences dans SharedPreferences
            Map<String, dynamic> preferencesData = jsonDecode(jsonContent);
            final prefs = await SharedPreferences.getInstance();

            // Restaurer les préférences sauvegardées
            List<String> ethAddresses =
                List<String>.from(preferencesData['ethAddresses'] ?? []);
            String? userIdToAddresses = preferencesData['userIdToAddresses'];
            String? selectedCurrency = preferencesData['selectedCurrency'];
            bool convertToSquareMeters =
                preferencesData['convertToSquareMeters'] ?? false;

            // Sauvegarder les préférences restaurées
            await prefs.setStringList('evmAddresses', ethAddresses);
            if (userIdToAddresses != null)
              await prefs.setString('userIdToAddresses', userIdToAddresses);
            if (selectedCurrency != null)
              await prefs.setString('selectedCurrency', selectedCurrency);
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
      print(
          'Erreur lors de l\'importation des données Hive depuis le fichier ZIP : $e');
    }
    DataFetchUtils.refreshData(context);
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
