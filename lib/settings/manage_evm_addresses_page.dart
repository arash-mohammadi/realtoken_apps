import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/services/api_service.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Pour copier dans le presse-papiers

class ManageEvmAddressesPage extends StatefulWidget {
  const ManageEvmAddressesPage({super.key});

  @override
  ManageEvmAddressesPageState createState() => ManageEvmAddressesPageState();
}

class ManageEvmAddressesPageState extends State<ManageEvmAddressesPage> {
  final TextEditingController _evmAddressController = TextEditingController();
  List<String> evmAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses(); // Charger les adresses sauvegardées
    // Charger les relations userId-adresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataManager = Provider.of<DataManager>(context, listen: false);
      dataManager.loadUserIdToAddresses(); // Charger les relations userId-adresses
      DataFetchUtils.loadData(context);
    });
  }

  @override
  void dispose() {
    _evmAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      evmAddresses = prefs.getStringList('evmAddresses') ?? [];
    });
  }

  String? _extractEvmereumAddress(String scannedData) {
    // Vérifiez si le code scanné contient une adresse Evmereum valide
    RegExp evmAddressRegExp = RegExp(r'(0x[a-fA-F0-9]{40})');
    final match = evmAddressRegExp.firstMatch(scannedData);
    if (match != null) {
      return match.group(0); // Retourne la première adresse valide
    }
    return null; // Aucune adresse trouvée
  }

  Future<void> _saveAddress(String address) async {
  if (!evmAddresses.contains(address.toLowerCase())) {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      evmAddresses.add(address.toLowerCase());
    });
    await prefs.setStringList('evmAddresses', evmAddresses);

    final dataManager = Provider.of<DataManager>(context, listen: false);

    // Utilisation de la nouvelle API pour récupérer le userId et les adresses associées
    final result = await ApiService.fetchUserAndAddresses(address.toLowerCase());

    if (result != null) {
      final String userId = result['userId'];
      final List<String> associatedAddresses = result['addresses'];

      dataManager.addAddressesForUserId(userId, associatedAddresses);

      setState(() {
        evmAddresses.addAll(
          associatedAddresses.where((addr) => !evmAddresses.contains(addr)),
        );
      });

      await prefs.setStringList('evmAddresses', evmAddresses);
    }

    // Recharger les données après l'ajout
    DataFetchUtils.loadData(context);
  }
}

  String? _validateEVMAddress(String address) {
    if (address.startsWith('0x') && address.length == 42) {
      return null; // Adresse valide
    }
    return 'Invalid Wallet address';
  }

  Future<void> _scanQRCode() async {
    bool isAddressSaved = false; // Pour éviter l'ajout multiple
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context)
                .scaffoldBackgroundColor, // Définir le fond noir
            title: const Text('Scan QR Code')),
        body: MobileScanner(onDetect: (BarcodeCapture barcodeCapture) {
          if (!isAddressSaved) {
            final List<Barcode> barcodes = barcodeCapture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                final String code = barcode.rawValue!;
                final String? extractedAddress = _extractEvmereumAddress(code);
                if (extractedAddress != null) {
                  _saveAddress(extractedAddress);
                  isAddressSaved = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Wallet saved: $extractedAddress')),
                  );
                  Navigator.of(context).pop(); // Fermer le scanner
                  break;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid wallet in QR Code')),
                  );
                }
              }
            }
          }
        }),
      ),
    ));
  }

  Future<void> _deleteAddress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      evmAddresses.removeAt(index);
    });
    await prefs.setStringList('evmAddresses', evmAddresses);
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState =
        Provider.of<AppState>(context); // Récupérer AppState pour le texte

    // Récupérer toutes les adresses liées à un userId
    final List linkedAddresses = dataManager
        .getAllUserIds()
        .expand((userId) => dataManager.getAddressesForUserId(userId) ?? [])
        .toList();

    // Filtrer les adresses non liées
    final unlinkedAddresses = evmAddresses
        .where((address) => !linkedAddresses.contains(address))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor, // Définir le fond noir
        title: const Text('Manage Wallets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _evmAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _scanQRCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Fond bleu
                    foregroundColor: Colors.white, // Icône blanche
                  ),
                  child: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String enteredAddress = _evmAddressController.text;
                if (_validateEVMAddress(enteredAddress) == null) {
                  _saveAddress(enteredAddress);
                  _evmAddressController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid wallet address')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Fond bleu
                foregroundColor: Colors.white, // Texte blanc
              ),
              child: Text(
                'Save Address',
                style: TextStyle(fontSize: 14 + appState.getTextSizeOffset()),
              ),
            ),
            const SizedBox(height: 20),
            if (unlinkedAddresses.isNotEmpty) ...[
              Text(
                'Unlinked Wallet Addresses',
                style: TextStyle(
                  fontSize: 18 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: unlinkedAddresses.length,
                  itemBuilder: (context, index) {
                    final address = unlinkedAddresses[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                  fontSize: 14 + appState.getTextSizeOffset()),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.blue),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: address));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Address copied: $address')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteAddress(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (dataManager.getAllUserIds().isNotEmpty) ...[
              Text(
                'User Linked Wallet Addresses',
                style: TextStyle(
                  fontSize: 18 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: dataManager.getAllUserIds().length,
                  itemBuilder: (context, index) {
                    final userId = dataManager.getAllUserIds()[index];
                    final addresses = dataManager.getAddressesForUserId(userId);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'User ID: $userId',
                                style: TextStyle(
                                  fontSize: 18 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  dataManager.removeUserId(userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('User ID $userId deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...addresses!.map((address) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(
                                                fontSize: 14 +
                                                    appState
                                                        .getTextSizeOffset()),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy,
                                              color: Colors.blue),
                                          onPressed: () {
                                            Clipboard.setData(
                                                ClipboardData(text: address));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Address copied: $address')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      dataManager.removeAddressForUserId(
                                          userId, address);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Address $address deleted')),
                                      );
                                    },
                                  ),
                                ],
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
