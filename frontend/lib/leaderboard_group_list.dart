import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/leaderboard_page.dart';

class LeaderboardGroupList extends StatefulWidget {
  const LeaderboardGroupList({super.key});

  @override
  _LeaderboardGroupListState createState() => _LeaderboardGroupListState();
}

class _LeaderboardGroupListState extends State<LeaderboardGroupList> {
  List<dynamic> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest("groups/getgroups", {});
      if (response.statusCode == 200) {
        setState(() {
          groups = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Failed to fetch groups: ${response.body}");
      }
    } catch (e) {
      print("Error fetching groups: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groups"),
        backgroundColor: Colors.amber[800],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: group['icon_url'] != null
                      ? Image.network(group['icon_url'], width: 40, height: 40)
                      : Icon(Icons.group, size: 40),
                  title: Text(group['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaderboardPage(groupId: group['id'].toString()),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}