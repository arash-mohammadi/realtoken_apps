import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'appearance_settings_page.dart';
import 'personalization_settings_page.dart';
import 'synchronization_settings_page.dart';
import 'notifications_settings_page.dart';
import 'advanced_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSettingsCard(
            context,
            icon: Icons.color_lens,
            color: Colors.lime,
            title: S.of(context).appearance,
            onTap: () => _navigateTo(context, AppearanceSettingsPage()),
          ),
          SizedBox(height: 16),
          _buildSettingsCard(
            context,
            icon: Icons.tune,
            color: Colors.green,
            title: S.of(context).personalization,
            onTap: () => _navigateTo(context, PersonalizationSettingsPage()),
          ),
          SizedBox(height: 16),
          _buildSettingsCard(
            context,
            icon: Icons.sync,
            color: Colors.blue,
            title: S.of(context).synchronization,
            onTap: () => _navigateTo(context, SynchronizationSettingsPage()),
          ),
          SizedBox(height: 16),
          _buildSettingsCard(
            context,
            icon: Icons.notifications,
            color: Colors.orange,
            title: S.of(context).notifications,
            onTap: () => _navigateTo(context, NotificationsSettingsPage()),
          ),
          SizedBox(height: 16),
          _buildSettingsCard(
            context,
            icon: Icons.build,
            color: Colors.purple,
            title: S.of(context).advanced,
            onTap: () => _navigateTo(context, AdvancedSettingsPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required VoidCallback onTap}) {
    final appState = Provider.of<AppState>(context);

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(fontSize: 16.0 + appState.getTextSizeOffset())),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }
}
