import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  final List<Map<String, String>> unlockedAchievements = [
  ];

  final List<Map<String, String>> lockedAchievements = [
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Achievements", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Unlocked"),
          unlockedAchievements.isEmpty
              ? _buildEmptyState("No achievements unlocked yet!")
              : _buildAchievementList(unlockedAchievements, unlocked: true),

          SizedBox(height: 24),

          _buildSectionTitle("Locked"),
          lockedAchievements.isEmpty
              ? _buildEmptyState("All achievements unlocked!")
              : _buildAchievementList(lockedAchievements, unlocked: false),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAchievementList(List<Map<String, String>> achievements, {required bool unlocked}) {
    return Column(
      children: achievements.map((achievement) {
        return Card(
          color: unlocked ? Colors.white : Colors.grey[200],
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              unlocked ? Icons.emoji_events : Icons.lock,
              color: unlocked ? Colors.amber[800] : Colors.grey,
              size: 32,
            ),
            title: Text(
              achievement['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: unlocked ? Colors.grey[800] : Colors.grey[600],
              ),
            ),
            subtitle: Text(
              achievement['description'] ?? '',
              style: TextStyle(
                color: unlocked ? Colors.grey[700] : Colors.grey[500],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
