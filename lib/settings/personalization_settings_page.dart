import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/services/api_service.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/parameters.dart';

class PersonalizationSettingsPage extends StatefulWidget {
  const PersonalizationSettingsPage({super.key});

  @override
  _PersonalizationSettingsPageState createState() => _PersonalizationSettingsPageState();
}

class _PersonalizationSettingsPageState extends State<PersonalizationSettingsPage> {
  Map<String, dynamic> _currencies = {}; // Stockage des devises

  Future<void> _saveConvertToSquareMeters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('convertToSquareMeters', value);
    setState(() {
      Parameters.convertToSquareMeters = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Charger les paramètres initiaux
    _fetchCurrencies(); // Récupérer les devises lors de l'initialisation
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
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(S.of(context).convertSqft, style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
              trailing: Switch(
                value: Parameters.convertToSquareMeters,
                onChanged: (value) {
                  _saveConvertToSquareMeters(value);
                },
                activeColor: Theme.of(context).primaryColor, // Couleur du bouton en mode activé
                inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                S.of(context).currency,
                style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
              ),
              trailing: _currencies.isNotEmpty
                  ? Consumer<CurrencyProvider>(
                      builder: (context, currencyProvider, child) {
                        return DropdownButton<String>(
                          value: currencyProvider.selectedCurrency, // ✅ Maintenant l'UI est réactive
                          items: _currencies.keys.map((String key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Text(key.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              Provider.of<CurrencyProvider>(context, listen: false).updateConversionRate(newValue, _currencies);
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

  Future<void> _fetchCurrencies() async {
    try {
      final currencies = await ApiService.fetchCurrencies();
      setState(() {
        _currencies = currencies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load currencies')),
      );
    }
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);

    // ✅ Utilisation correcte du Provider avec `listen: false`
    Provider.of<CurrencyProvider>(context, listen: false).updateConversionRate(currency, _currencies);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      Parameters.convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
      Parameters.selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';
    });
  }
}
