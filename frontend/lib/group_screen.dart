import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/invite.dart';
import 'package:frontend/auth.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;

  const GroupScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Group group;
  late List<User> members;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  bool isUserLeader = false;

  // Fetch group details from the backend
  Future<void> fetchGroupDetails() async {
    final response = await Auth.makeAuthenticatedPostRequest("groups/members", {
      "groupId": widget.groupId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        group = Group(
          id: data['groupId'],
          name: data['groupName'],
          leaderId: data['leaderId'],
          isPublic: data['isPublic'] == true, // Ensure it’s a boolean
          iconUrl: data['iconUrl'] as String?, // Allow it to be null
        );
        members =
            (data['members'] as List)
                .map(
                  (m) => User(
                    id: m['id'],
                    name: "${m['first_name']} ${m['last_name']}",
                    avatarUrl: m['profile_picture'],
                  ),
                )
                .toList();

        isUserLeader = data['isUserLeader'];
        isLoading = false;
      });
    } else {
      print("Failed to load group data");
    }
  }

  // API call to leave the group
  void _leaveGroup() async {
    final response = await Auth.makeAuthenticatedPostRequest("groups/leave", {
      "userId": "your_user_id",
      "groupId": widget.groupId,
    });

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("You have left the group.")));
    } else {
      print("Error leaving group: ${response.body}");
    }
  }

  // Show confirmation dialog before leaving the group
  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Leave Group"),
          content: Text(
            "Are you sure you want to leave this group? You will need an invite to rejoin.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _leaveGroup(); // Calls the API to leave
              },
              child: Text("Leave Group"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ), // Show loading animation
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name ?? "Unnamed Group"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isUserLeader)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                _showGroupSettings(context, group);
              },
            ),
          if (!isUserLeader)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                _showLeaveGroupDialog();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header with Image and Info
            _buildGroupHeader(context, group),

            // Group Stats
            _buildGroupStats(context, group),

            // Members Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members (${members.length})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isUserLeader)
                    ElevatedButton.icon(
                      onPressed: () {
                        _showInviteMembersDialog(context);
                      },
                      icon: Icon(Icons.person_add, size: 20),
                      label: Text('Invite'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Members List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildMemberItem(context, member, isUserLeader);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleImageUpload(BuildContext context) {
    // Placeholder for image upload functionality
    // In a real app, this would open an image picker and handle the upload
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image upload functionality to be implemented')),
    );
  }

  Widget _buildGroupHeader(BuildContext context, Group group) {
    final bool isUserLeader = true; // Moved from parent scope for this example

    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          // Group Cover Image
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.blue[100],
            child: Center(
              child: Icon(Icons.group, size: 80, color: Colors.blue[800]),
            ),
          ),

          // Upload Button (visible only to group leader)
          if (isUserLeader)
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.upload, color: Colors.blue[800], size: 24),
                ),
                onPressed: () {
                  // Image upload functionality to be implemented
                  _handleImageUpload(context);
                },
                tooltip: 'Upload Group Image',
              ),
            ),

          // Group Info Overlay
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name ?? "Unnamed Group",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStats(BuildContext context, Group group) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildMemberItem(
    BuildContext context,
    User member,
    bool isUserLeader,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.white),
        // In a real app, you would use a network image:
        // backgroundImage: NetworkImage(member.avatarUrl),
      ),
      title: Row(
        children: [
          Text(member.name),
          SizedBox(width: 8),
          if (member.id == group.leaderId)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                'Leader',
                style: TextStyle(fontSize: 12, color: Colors.amber[800]),
              ),
            ),
        ],
      ),
      trailing:
          isUserLeader && member.id != group.leaderId
              ? PopupMenuButton(
                icon: Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'remove') {
                    _showRemoveMemberDialog(context, member);
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
              )
              : null,
    );
  }

  void _showGroupSettings(BuildContext context, Group group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),

                // Rename Group Option
                TextFormField(
                  initialValue: group.name,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.edit),
                  ),
                ),
                SizedBox(height: 16),

                SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('Save Changes'),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Leave Group Option
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLeaveGroupDialog();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Leave Group',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInviteMembersDialog(BuildContext context) {
    InviteMembersDialog.show(context);
  }

  void _showRemoveMemberDialog(BuildContext context, User member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Member'),
          content: Text(
            'Are you sure you want to remove ${member.name} from this group?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Remove', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }
}
