import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Privacy & Security",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
            stops: [0.0, 0.3],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Icon(Icons.shield, size: 80, color: Colors.amber[800]),
            ),
            _buildSecurityCard(
              icon: Icons.lock_outline,
              title: "Data Privacy",
              content:
                  "We value your privacy. Your personal information, such as your name, username, and profile picture, is securely stored and only accessible by you. We do not share your data with third parties without your consent. You can turn off location sharing permissions at any time through your device settings",
            ),
            _buildSecurityCard(
              icon: Icons.key,
              title: "Authentication & Security",
              content:
                  "Your account is protected by multi-layer authentication mechanisms. We use secure token-based authentication to keep your session safe. Sensitive data, such as passwords, is always encrypted.",
            ),
            _buildSecurityCard(
              icon: Icons.data_usage,
              title: "Data Collection & Usage",
              content:
                  "We collect only the necessary data to provide a smooth user experience. This includes your profile details, location, and activity logs. All data will be deleted if you choose to delete your account.",
            ),
            _buildSecurityCard(
              icon: Icons.notifications_none,
              title: "Notification Preferences",
              content:
                  "You have full control over your notification settings. You can enable or disable push notifications from the Settings menu.",
            ),
            _buildSecurityCard(
              icon: Icons.warning_amber_outlined,
              title: "Reporting Issues",
              content:
                  "If you encounter security concerns or suspicious activity, please report it immediately using the 'Report an Issue' section. Our team will review and take appropriate action.",
              isLast: true,
            ),
            const SizedBox(height: 30),
            /*Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[100]!, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    "Your privacy and security are our top priorities.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.amber[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "If you have any questions, please contact our support team.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),*/

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    "Can't find what you're looking for?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Contact support action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Contact Support",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            /*const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Action for reporting issues
                },
                icon: Icon(Icons.help_outline, color: Colors.amber[800]),
                label: Text(
                  "Get Help",
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),*/
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.amber[800], size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[100],
              indent: 16,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}
