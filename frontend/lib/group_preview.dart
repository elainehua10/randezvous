import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/auth.dart';

class GroupPreview extends StatefulWidget {
  final String groupId;

  const GroupPreview({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupPreviewState createState() => _GroupPreviewState();
}

class _GroupPreviewState extends State<GroupPreview> {
  late List<User> members;
  bool isLoading = true;
  String? groupIconUrl;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  // Fetch group details from the backend
  Future<void> fetchGroupDetails() async {
    final response = await Auth.makeAuthenticatedPostRequest("groups/members", {
      "groupId": widget.groupId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        groupIconUrl = data['iconUrl']; // Set the group icon URL

        members =
            (data['members'] as List)
                .map(
                  (m) => User(
                    id: m['id'],
                    name: "${m['first_name']} ${m['last_name']}",
                    avatarUrl: m['profile_picture'],
                    username: m['username'] ?? '',
                  ),
                )
                .toList();
        isLoading = false;
      });
    } else {
      print("Failed to load group data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Preview')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : members.isEmpty
              ? const Center(child: Text('No members found'))
              : Column(
                children: [
                  // Display Group Icon
                  groupIconUrl != null
                      ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(groupIconUrl!),
                      )
                      : const Icon(Icons.group, size: 100),
                  const SizedBox(height: 20),
                  // Display Members
                  Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                member.avatarUrl != null &&
                                        member.avatarUrl!.isNotEmpty
                                    ? NetworkImage(member.avatarUrl!)
                                    : null,
                            child:
                                member.avatarUrl == null ||
                                        member.avatarUrl!.isEmpty
                                    ? Text(
                                      member.name.isNotEmpty
                                          ? member.name[0]
                                          : "U",
                                    )
                                    : null,
                          ),
                          title: Text(member.name),
                          subtitle: Text('@${member.username}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
