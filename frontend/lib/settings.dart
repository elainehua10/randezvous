import 'package:flutter/material.dart';
import 'privacy_security_page.dart';
import 'faq_page.dart';
import 'report_issue_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildToggleRow(
            title: "Enable Notifications",
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // Handle saving notification settings here
            },
          ),
          _buildDivider(),
          _buildRow(
            title: "Privacy & Security",
            icon: Icons.lock_rounded,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacySecurityPage(),
                  ),
                ),
          ),
          _buildDivider(),
          _buildRow(
            title: "FAQ",
            icon: Icons.help_outline_rounded,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQPage()),
                ),
          ),
          _buildDivider(),
          _buildRow(
            title: "Report an Issue",
            icon: Icons.bug_report_rounded,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportIssuePage()),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.amber[800],
    );
  }

  Widget _buildRow({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber[800]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(indent: 16, endIndent: 16, height: 1);
  }
}
