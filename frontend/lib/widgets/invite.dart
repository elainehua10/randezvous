import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';

class InviteMembersDialog {
  static void show(BuildContext context, String groupId, bool isUserLeader) {
    showDialog(
      context: context,
      builder:
          (context) => _InviteMembersDialog(
            groupId: groupId,
            isUserLeader: isUserLeader,
          ),
    );
  }
}

class _InviteMembersDialog extends StatefulWidget {
  final String groupId;
  final bool isUserLeader;

  const _InviteMembersDialog({
    required this.groupId,
    required this.isUserLeader,
  });

  @override
  _InviteMembersDialogState createState() => _InviteMembersDialogState();
}

class _InviteMembersDialogState extends State<_InviteMembersDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  void _performUserSearch(String userId) async {
    if (userId.isEmpty) return;

    Response response = await Auth.makeAuthenticatedPostRequest("user/search", {
      "username": userId,
    });
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
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
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite Members'),
      content: SingleChildScrollView(
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
                      leading: CircleAvatar(child: Text(user.name![0])),
                      title: Text(user.name!),
                      subtitle: Text(user.username!),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
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
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              Text('No results found'),
            SizedBox(height: 16),
            if (widget.isUserLeader) ...[
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.upload),
                label: Text('Upload Image'),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(_selectedImage!, height: 100),
                ),
            ],
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
