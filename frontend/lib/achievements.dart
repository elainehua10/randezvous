import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'dart:convert';

class AchievementsPage extends StatefulWidget {
  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  List<dynamic> unlocked = [];
  List<dynamic> locked = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAchievements();
  }

  Future<void> _fetchAchievements() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "user/get-achievements",
        {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unlocked = data['unlocked'] ?? [];
          locked = data['locked'] ?? [];
          isLoading = false;
        });
      } else {
        print("Failed to load achievements");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement, bool unlocked) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unlocked ? Colors.amber[100] : Colors.grey[300],
          child: Icon(
            unlocked ? Icons.emoji_events : Icons.lock,
            color: unlocked ? Colors.amber[800] : Colors.grey[600],
          ),
        ),
        title: Text(
          achievement['title'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          achievement['description'] ?? '',
          style: TextStyle(color: unlocked ? Colors.black87 : Colors.grey),
        ),
        trailing: unlocked
            ? Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Achievements",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unlocked Achievements Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Unlocked Achievements",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (unlocked.isNotEmpty)
                    ...unlocked.map((ach) => _buildAchievementCard(ach, true)).toList()
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "No achievements unlocked yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  SizedBox(height: 24),

                  // Locked Achievements Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Locked Achievements",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (locked.isNotEmpty)
                    ...locked.map((ach) => _buildAchievementCard(ach, false)).toList()
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "All achievements unlocked!",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
