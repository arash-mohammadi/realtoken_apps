import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/generated/l10n.dart';

class AdvancedSettingsPage extends StatefulWidget {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text('Effacer le cache et les données', style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
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
                      child: Text("Cancel", style: TextStyle(color: Colors.red)),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    });
  }

  Future<void> _saveDaysLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daysLimit', value);
  }
}
