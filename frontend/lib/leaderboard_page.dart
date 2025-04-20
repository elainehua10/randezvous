import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';

class LeaderboardPage extends StatefulWidget {
  final String groupId;

  const LeaderboardPage({super.key, required this.groupId});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest("groups/leaderboard", {
        "groupId": widget.groupId,
      });
      if (response.statusCode == 200) {
        setState(() {
          leaderboard = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Failed to fetch leaderboard: ${response.body}");
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Leaderboard"),
        backgroundColor: Colors.amber[800],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final member = leaderboard[index];
                return ListTile(
                  leading: member['profile_picture'] != null
                      ? Image.network(member['profile_picture'], width: 40, height: 40)
                      : Icon(Icons.person, size: 40),
                  title: Text("${member['first_name']} ${member['last_name']}"),
                  subtitle: Text("Points: ${member['points']}"),
                  trailing: Text("Rank: ${member['rank']}"),
                );
              },
            ),
    );
  }
}