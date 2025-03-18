import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/services/api_service.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:realtokens/managers/data_manager.dart';

class PersonalizationSettingsPage extends StatefulWidget {
  const PersonalizationSettingsPage({super.key});

  @override
  _PersonalizationSettingsPageState createState() =>
      _PersonalizationSettingsPageState();
}

class _PersonalizationSettingsPageState
    extends State<PersonalizationSettingsPage> {
  Map<String, dynamic> _currencies = {}; // Stockage des devises
  final TextEditingController _adjustmentController = TextEditingController();

  Future<void> _saveConvertToSquareMeters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('convertToSquareMeters', value);
    setState(() {
      Parameters.convertToSquareMeters = value;
    });
  }

  Future<void> _saveShowTotalInvested(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTotalInvested', value);
    setState(() {
      Parameters.showTotalInvested = value;
    });
  }

  Future<void> _saveShowNetTotal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNetTotal', value);
    setState(() {
      Parameters.showNetTotal = value;
    });
  }

  Future<void> _saveShowYamProjection(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showYamProjection', value);
    setState(() {
      Parameters.showYamProjection = value;
    });
  }

  Future<void> _saveManualAdjustment(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('manualAdjustment', value);
    setState(() {
      Parameters.manualAdjustment = value;
    });
    
    // Récupérer DataManager à partir du provider
    if (!mounted) return; // Vérifier que le widget est toujours monté
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndCalculateData();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Charger les paramètres initiaux
    _fetchCurrencies(); // Récupérer les devises lors de l'initialisation
    _adjustmentController.text = Parameters.manualAdjustment.toString();
  }

  @override
  void dispose() {
    _adjustmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.tune,
              color: Colors.green,
            ),
            SizedBox(width: 8),
            Text(S.of(context).personalization),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Section pour les paramètres du portfolio
          _buildSectionTitle(context, S.of(context).portfolio, Icons.dashboard),
          Card(
            color: Theme.of(context).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(S.of(context).showTotalInvested,
                      style: TextStyle(
                          fontSize: 16.0 + appState.getTextSizeOffset())),
                  value: Parameters.showTotalInvested,
                  onChanged: (value) {
                    _saveShowTotalInvested(value);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                Divider(),
                SwitchListTile(
                  title: Text(S.of(context).showNetTotal,
                      style: TextStyle(
                          fontSize: 16.0 + appState.getTextSizeOffset())),
                  subtitle: Text(
                    S.of(context).showNetTotalDescription,
                    style: TextStyle(fontSize: 12 + appState.getTextSizeOffset()),
                  ),
                  value: Parameters.showNetTotal,
                  onChanged: (value) {
                    _saveShowNetTotal(value);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                Divider(),
                SwitchListTile(
                  title: Text("Afficher projection YAM",
                      style: TextStyle(
                          fontSize: 16.0 + appState.getTextSizeOffset())),
                  subtitle: Text(
                    "Affiche la projection du portefeuille calculée par YAM",
                    style: TextStyle(fontSize: 12 + appState.getTextSizeOffset()),
                  ),
                  value: Parameters.showYamProjection,
                  onChanged: (value) {
                    _saveShowYamProjection(value);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).manualAdjustment,
                        style: TextStyle(
                            fontSize: 16.0 + appState.getTextSizeOffset()),
                      ),
                      SizedBox(height: 8),
                      Text(
                        S.of(context).manualAdjustmentDescription,
                        style: TextStyle(
                            fontSize: 12 + appState.getTextSizeOffset(),
                            color: Colors.grey),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _adjustmentController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: S.of(context).amount,
                                prefixIcon: Icon(Icons.money),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              // Convertir le texte en nombre
                              final String text = _adjustmentController.text;
                              double? value = double.tryParse(text);
                              if (value != null) {
                                _saveManualAdjustment(value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          S.of(context).adjustmentSaved)),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          S.of(context).enterValidNumber)),
                                );
                              }
                            },
                            child: Text(S.of(context).save),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Section pour les paramètres d'unités
          SizedBox(height: 24),
          _buildSectionTitle(context, S.of(context).units, Icons.straighten),
          Card(
            color: Theme.of(context).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(S.of(context).convertSqft,
                  style:
                      TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
              trailing: Switch(
                value: Parameters.convertToSquareMeters,
                onChanged: (value) {
                  _saveConvertToSquareMeters(value);
                },
                activeColor: Theme.of(context).primaryColor,
                inactiveThumbColor: Colors.grey,
              ),
            ),
          ),
          
          // Section pour le choix de la devise
          SizedBox(height: 24),
          _buildSectionTitle(context, S.of(context).currency, Icons.monetization_on),
          Card(
            color: Theme.of(context).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                S.of(context).selectCurrency,
                style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: _currencies.isNotEmpty
                  ? Consumer<CurrencyProvider>(
                      builder: (context, currencyProvider, child) {
                        return DropdownButton<String>(
                          value: currencyProvider.selectedCurrency,
                          items: _currencies.keys.map((String key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Text(key.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              Provider.of<CurrencyProvider>(context,
                                      listen: false)
                                  .updateConversionRate(newValue, _currencies);
                            }
                          },
                        );
                      },
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCurrencies() async {
    try {
      final currencies = await ApiService.fetchCurrencies();
      if (!mounted) return; // Vérifier que le widget est toujours monté
      setState(() {
        _currencies = currencies;
      });
    } catch (e) {
      if (!mounted) return; // Vérifier que le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load currencies')),
      );
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Vérifier que le widget est toujours monté
    setState(() {
      Parameters.convertToSquareMeters =
          prefs.getBool('convertToSquareMeters') ?? false;
      Parameters.selectedCurrency =
          prefs.getString('selectedCurrency') ?? 'usd';
      Parameters.showTotalInvested = 
          prefs.getBool('showTotalInvested') ?? false;
      Parameters.showNetTotal = 
          prefs.getBool('showNetTotal') ?? true;
      Parameters.manualAdjustment = 
          prefs.getDouble('manualAdjustment') ?? 0.0;
      Parameters.showYamProjection = 
          prefs.getBool('showYamProjection') ?? true;
    });
  }
}
