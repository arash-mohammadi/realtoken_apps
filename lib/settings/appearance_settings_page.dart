import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';

class AppearanceSettingsPage extends StatefulWidget {
  @override
  _AppearanceSettingsPageState createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late String _selectedColor;
  final Map<String, Color> _colorOptions = {
    'blue': Colors.blue,
    'orange': Colors.deepOrangeAccent,
    'pink': Colors.pink,
    'green': Colors.green,
    'grey': Colors.grey,
    'blueGrey': Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedColor = prefs.getString('primaryColor') ?? 'blue';
    });
  }

  Future<void> _updatePrimaryColor(String colorName) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updatePrimaryColor(colorName);
    setState(() {
      _selectedColor = colorName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).themeUpdated(colorName))),
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
              Icons.color_lens,
              color: Colors.lime,
            ),
            SizedBox(width: 8),
            Text(S.of(context).appearance),
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
              title: Text(S.of(context).darkTheme, style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
              trailing: DropdownButton<String>(
                value: appState.themeMode,
                items: [
                  DropdownMenuItem(value: 'light', child: Text(S.of(context).light)),
                  DropdownMenuItem(value: 'dark', child: Text(S.of(context).dark)),
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    appState.updateThemeMode(newValue);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).themeUpdated(newValue))),
                    );
                  }
                },
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
                  Text("Couleur principale", style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _colorOptions.entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _updatePrimaryColor(entry.key),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entry.value,
                            border: _selectedColor == entry.key ? Border.all(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey, width: 3) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
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
          ),
          SizedBox(height: 16),
          Card(
  color: Theme.of(context).cardColor,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: ListTile(
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
)

          ],
      ),
    );
  }
}
