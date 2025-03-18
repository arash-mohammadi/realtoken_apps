import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/generated/l10n.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  _AdvancedSettingsPageState createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  int _daysLimit = 30;
  double _apyReactivity = 0.2; // Valeur par défaut pour la réactivité de l'APY

  Future<void> _clearCacheAndData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache et données supprimés')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.build,
              color: Colors.purple,
            ),
            SizedBox(width: 8),
            Text(S.of(context).advanced),
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
            child: ListTile(
              title: Text(
                S.of(context).yamHistory,
                style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset()),
              ),
              subtitle: Text("${S.of(context).daysLimit}: $_daysLimit days"),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showNumberPicker(context),
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Theme.of(context).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réactivité de l\'APY',
                    style: TextStyle(
                      fontSize: 16.0 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajustez la sensibilité du calcul d\'APY aux variations récentes',
                    style: TextStyle(
                      fontSize: 14.0 + appState.getTextSizeOffset(),
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Lisse'),
                      Expanded(
                        child: Slider(
                          value: _apyReactivity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: _getApyReactivityLabel(),
                          onChanged: (value) {
                            setState(() {
                              _apyReactivity = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _saveApyReactivity(value);
                            // Appliquer immédiatement le changement via AppState
                            appState.adjustApyReactivity(value);
                          },
                        ),
                      ),
                      Text('Réactif'),
                    ],
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
            child: ListTile(
              title: Text('Effacer le cache et les données',
                  style:
                      TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _clearCacheAndData(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour obtenir un libellé descriptif en fonction de la valeur de réactivité
  String _getApyReactivityLabel() {
    if (_apyReactivity < 0.2) {
      return 'Très lisse';
    } else if (_apyReactivity < 0.4) {
      return 'Lisse';
    } else if (_apyReactivity < 0.6) {
      return 'Équilibré';
    } else if (_apyReactivity < 0.8) {
      return 'Réactif';
    } else {
      return 'Très réactif';
    }
  }

  void _showNumberPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int tempDaysLimit = _daysLimit;
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          Text("Cancel", style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _daysLimit = tempDaysLimit;
                        });
                        _saveDaysLimit(_daysLimit);
                        Navigator.pop(context);
                      },
                      child: Text("Done"),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  perspective: 0.005,
                  onSelectedItemChanged: (index) {
                    tempDaysLimit = index + 1;
                  },
                  physics: FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final isSelected = (index + 1) == tempDaysLimit;
                      return Center(
                        child: Text(
                          "${index + 1} days",
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                      );
                    },
                    childCount: 365,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _daysLimit = prefs.getInt('daysLimit') ?? 30;
      _apyReactivity = prefs.getDouble('apyReactivity') ?? 0.2;
    });
  }

  Future<void> _saveDaysLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daysLimit', value);
  }

  Future<void> _saveApyReactivity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('apyReactivity', value);
  }
}
