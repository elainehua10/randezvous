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
  String? groupName;

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
        groupName = data['groupName'] ?? 'Group'; // Add group name

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
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Group Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.blue[600]),
              )
              : members.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 100, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      'No members in this group',
                      style: TextStyle(color: Colors.grey[600], fontSize: 18),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          // Group Icon
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  groupIconUrl != null
                                      ? NetworkImage(groupIconUrl!)
                                      : null,
                              child:
                                  groupIconUrl == null
                                      ? Icon(
                                        Icons.group,
                                        size: 60,
                                        color: Colors.grey[500],
                                      )
                                      : null,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            groupName ?? 'Group',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${members.length} Members',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Members List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final member = members[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue[100]!,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[200],
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
                                              ? member.name[0].toUpperCase()
                                              : "U",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[600],
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                            title: Text(
                              member.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '@${member.username}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }, childCount: members.length),
                    ),
                  ),
                ],
              ),
    );
  }
}
