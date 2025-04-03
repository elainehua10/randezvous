import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'privacy_security_page.dart';
import 'faq_page.dart';
import 'report_issue_page.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/util.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchNotificationSetting(); // Fetch the current setting when the page loads
  }

  Future<void> _fetchNotificationSetting() async {
    try {
      String? accessToken =
          await Auth.getAccessToken(); // Get the access token of the logged-in user

      final url = Uri.parse('${Util.BACKEND_URL}/api/v1/get-user-profile-info');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
        body: jsonEncode({
          'userId': 'user_id_here',
        }), // Replace with actual user ID
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notificationsEnabled = data['notifications_enabled'] ?? true;
        });
      } else {
        print('Failed to load notification setting: ${response.body}');
      }
    } catch (error) {
      print('Error fetching notification setting: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: const EdgeInsets.only(top: 16),
          children: [
            _buildSectionTitle("Preferences"),
            _buildToggleRow(
              title: "Notifications",
              subtitle: "Receive alerts and updates",
              icon: Icons.notifications_outlined,
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _updateNotificationSetting(value);
              },
            ),
            _buildSectionTitle("Support & Information"),
            _buildRow(
              title: "Privacy & Security",
              subtitle: "Manage your privacy settings",
              icon: Icons.shield_outlined,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivacySecurityPage(),
                    ),
                  ),
            ),
            _buildRow(
              title: "FAQ",
              subtitle: "Frequently asked questions",
              icon: Icons.help_outline_rounded,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FAQPage()),
                  ),
            ),
            _buildRow(
              title: "Report an Issue",
              subtitle: "Let us know if something's not working",
              icon: Icons.bug_report_outlined,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportIssuePage()),
                  ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                "App Version 1.0.0",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNotificationSetting(bool enableNotifications) async {
    try {
      String? accessToken =
          await Auth.getAccessToken(); // Get the access token of the logged-in user

      final url = Uri.parse('${Util.BACKEND_URL}/api/v1/toggle-notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
        body: jsonEncode({
          'enableNotifications':
              enableNotifications, // Send the new notification preference
        }),
      );

      if (response.statusCode == 200) {
        print('Notification preference updated successfully');
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Success!'),
                content: Text(
                  'Notifications ${enableNotifications ? 'enabled' : 'disabled'} successfully',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        print('Failed to update notifications: ${response.body}');
        _showErrorDialog('Failed to update notification preferences');
      }
    } catch (error) {
      print('Error: $error');
      _showErrorDialog(
        'An error occurred while updating the notification preferences',
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.amber[800],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        secondary: Icon(icon, color: Colors.amber[800]),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.amber[800],
      ),
    );
  }

  Widget _buildRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber[800]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
