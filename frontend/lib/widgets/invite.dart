import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart';

class InviteMembersDialog {
  static void show(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => _InviteMembersDialog(groupId: groupId),
    );
  }
}

class _InviteMembersDialog extends StatefulWidget {
  final String groupId;

  const _InviteMembersDialog({required this.groupId});

  @override
  _InviteMembersDialogState createState() => _InviteMembersDialogState();
}

class _InviteMembersDialogState extends State<_InviteMembersDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];

  void _performUserSearch(String userId) async {
    if (userId.isEmpty) return;

    Response response = await Auth.makeAuthenticatedPostRequest("user/search", {
      "username": userId,
    });
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      print(responseData["users"]);
      List<User> results =
          responseData["users"]
              .map<User>(
                (user) => User(
                  id: user["id"],
                  name: "${user["first_name"]} ${user["last_name"]}",
                  avatarUrl: user["profile_picture"],
                  username: user["username"],
                ),
              )
              .toList();

      setState(() {
        _searchResults = results;
      });
    } else {
      print(responseData);
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite Members'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search for a user by ID:'),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter User ID',
                prefixIcon: Icon(Icons.person),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _performUserSearch(_searchController.text);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_searchResults.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user.name[0])),
                      title: Text(user.name),
                      subtitle: Text(user.username),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          await Auth.makeAuthenticatedPostRequest(
                            "groups/invite",
                            {
                              "groupId":
                                  widget.groupId, // Pass the groupId here
                              "toUserId": user.id, // Pass the user ID to invite
                            },
                          );
                          Navigator.pop(context);
                          // Optionally, show a confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invited ${user.name}')),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              Text('No results found'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
