import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  _NotificationsSettingsPageState createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    bool isSubscribed = OneSignal.User.pushSubscription.optedIn ?? false;
    setState(() {
      _notificationsEnabled = isSubscribed;
    });
  }

  Future<void> _toggleNotificationStatus(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      OneSignal.User.pushSubscription.optIn();
    } else {
      OneSignal.User.pushSubscription.optOut();
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
              Icons.notifications,
              color: Colors.orange,
            ),
            SizedBox(width: 8),
            Text(S.of(context).notifications),
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
              title: Text('Activer les notifications', style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotificationStatus,
                activeColor: Theme.of(context).primaryColor, // Couleur du bouton en mode activé
                inactiveThumbColor: Colors.grey, // Couleur du bouton en mode désactivé
              ),
            ),
          ),
        ],
      ),
    );
  }
}
