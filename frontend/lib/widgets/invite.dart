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

    final response = await Auth.makeAuthenticatedPostRequest("user/search", {
      "username": userId,
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      setState(() {
        _searchResults =
            (data["users"] as List)
                .map(
                  (u) => User(
                    id: u["id"],
                    name: "${u["first_name"]} ${u["last_name"]}",
                    avatarUrl: u["profile_picture"],
                    username: u["username"],
                  ),
                )
                .toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Invite Members',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800]),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter username',
                prefixIcon: Icon(Icons.person, color: Colors.amber[800]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.amber[800]),
                  onPressed: () => _performUserSearch(_searchController.text),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_searchResults.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber[100],
                          backgroundImage:
                              user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                          child:
                              user.avatarUrl == null
                                  ? Icon(Icons.person, color: Colors.amber[800])
                                  : null,
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(user.username),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.person_add,
                            color: Colors.amber[800],
                          ),
                          onPressed: () async {
                            await Auth.makeAuthenticatedPostRequest(
                              "groups/invite",
                              {"groupId": widget.groupId, "toUserId": user.id},
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invited ${user.name}')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No results found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.amber[800])),
        ),
      ],
    );
  }
}
