import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          title: const Text('Scan QR Code'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: const Text('Manage Wallets'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),

          _buildSectionHeader(context, "Ajouter une adresse", CupertinoIcons.plus_circle),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _evmAddressController,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        placeholder: 'Wallet Address',
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _scanQRCode,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.qrcode_viewfinder, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
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
                    child: Text(
                      'Save Address',
                      style: TextStyle(
                        fontSize: 15 + appState.getTextSizeOffset(),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (unlinkedAddresses.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader(context, "Adresses non associées", CupertinoIcons.creditcard),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: unlinkedAddresses.length,
              itemBuilder: (context, index) {
                final address = unlinkedAddresses[index];
                return _buildAddressCard(
                  context,
                  address: address,
                  onDelete: () => _deleteAddress(evmAddresses.indexOf(address)),
                );
              },
            ),
          ],

          if (dataManager.getAllUserIds().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader(context, "Adresses associées", CupertinoIcons.person_crop_circle),
            for (final userId in dataManager.getAllUserIds()) 
              _buildUserSection(
                context,
                userId: userId,
                addresses: dataManager.getAddressesForUserId(userId) ?? [],
                dataManager: dataManager,
              ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddressCard(
    BuildContext context, {
    required String address,
    required VoidCallback onDelete,
  }) {
    final appState = Provider.of<AppState>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 14 + appState.getTextSizeOffset(),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(CupertinoIcons.doc_on_clipboard, color: Theme.of(context).primaryColor, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Address copied: $address')),
                );
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserSection(
    BuildContext context, {
    required String userId,
    required List<String> addresses,
    required DataManager dataManager,
  }) {
    final appState = Provider.of<AppState>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        CupertinoIcons.person,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'User ID: $userId',
                      style: TextStyle(
                        fontSize: 15 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    dataManager.removeUserId(userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User ID $userId deleted')),
                    );
                  },
                ),
              ],
            ),
          ),
          for (var i = 0; i < addresses.length; i++) 
            Column(
              children: [
                if (i == 0)
                  const Divider(height: 1, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          addresses[i],
                          style: TextStyle(
                            fontSize: 14 + appState.getTextSizeOffset(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.doc_on_clipboard, color: Theme.of(context).primaryColor, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: addresses[i]));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Address copied: ${addresses[i]}')),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          dataManager.removeAddressForUserId(userId, addresses[i]);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Address ${addresses[i]} deleted')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (i < addresses.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
