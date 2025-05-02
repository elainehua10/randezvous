import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/util.dart';
import 'package:http/http.dart' as http;

import 'privacy_security_page.dart';
import 'faq_page.dart';
import 'contact_us_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _fetchNotificationSetting();
  }

  Future<void> _fetchNotificationSetting() async {
    try {
      final token = await Auth.getAccessToken();
      final url = Uri.parse('${Util.BACKEND_URL}/api/v1/get-user-profile-info');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        body: jsonEncode({'userId': 'user_id_here'}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notificationsEnabled = data['notifications_enabled'] ?? true;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updateNotificationSetting(bool enabled) async {
    try {
      final token = await Auth.getAccessToken();
      final url = Uri.parse('${Util.BACKEND_URL}/api/v1/toggle-notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        body: jsonEncode({'enableNotifications': enabled}),
      );

      if (response.statusCode == 200) {
        _showAlert(
          title: 'Success',
          message:
              'Notifications ${enabled ? 'enabled' : 'disabled'} successfully.',
        );
      } else {
        _showAlert(title: 'Error', message: 'Couldn\'t update settings.');
      }
    } catch (e) {
      _showAlert(
        title: 'Error',
        message: 'An error occurred while updating your preferences.',
      );
    }
  }

  void _showAlert({required String title, required String message}) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK', style: TextStyle(color: Colors.amber[800])),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.amber[800],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: child,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.amber[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.amber[800]),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          _buildSectionTitle('Preferences'),
          // Notifications toggle
          _buildCard(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Icon(
                Icons.notifications_outlined,
                color: Colors.amber[800],
              ),
              title: Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Receive alerts and updates',
                style: TextStyle(color: Colors.grey[600]),
              ),
              value: _notificationsEnabled ?? false,
              activeColor: Colors.amber[800],
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                _updateNotificationSetting(v);
              },
            ),
          ),

          _buildSectionTitle('Support & Information'),
          // Privacy & Security
          _buildCard(
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: Colors.amber[800]),
              title: Text(
                'Privacy & Security',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Manage your privacy settings',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacySecurityPage()),
                  ),
            ),
          ),

          // FAQ
          _buildCard(
            child: ListTile(
              leading: Icon(
                Icons.help_outline_rounded,
                color: Colors.amber[800],
              ),
              title: Text('FAQ', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                'Frequently asked questions',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FAQPage()),
                  ),
            ),
          ),

          // Contact Us
          _buildCard(
            child: ListTile(
              leading: Icon(Icons.mail_outline, color: Colors.amber[800]),
              title: Text(
                'Contact Us',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Ask questions or report an issue',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ContactUsPage()),
                  ),
            ),
          ),

          // App version
          const SizedBox(height: 24),
          Center(
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
