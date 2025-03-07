import 'package:flutter/material.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/invite.dart';

class GroupScreen extends StatelessWidget {
  final String groupId;

  const GroupScreen({Key? key, required this.groupId}) : super(key: key);
  final String leaderUserId = "user3";

  @override
  Widget build(BuildContext context) {
    // Static group data - in a real app, this would be fetched based on groupId
    final group = Group(id: groupId, name: 'Friends Group', imageUrl: null, leaderId: 'user3', isPublic: false);

    // Static member data - in a real app, this would be fetched based on groupId
    final members = [
      User(
        id: 'user1',
        name: 'Jane Smith',
        avatarUrl: 'https://example.com/avatar1.jpg',
      ),
      User(
        id: 'user2',
        name: 'John Doe',
        avatarUrl: 'https://example.com/avatar2.jpg',
      ),
      User(
        id: 'user3',
        name: 'Alex Johnson',
        avatarUrl: 'https://example.com/avatar3.jpg',
      ),
      User(
        id: 'user4',
        name: 'Sarah Williams',
        avatarUrl: 'https://example.com/avatar4.jpg',
      ),
      User(
        id: 'user5',
        name: 'Michael Brown',
        avatarUrl: 'https://example.com/avatar5.jpg',
      ),
    ];

    // Static data to determine if current user is the leader
    // In a real app, this would be determined by comparing the current user's ID with the leader's ID
    final bool isCurrentUserLeader = true;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isCurrentUserLeader)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                _showGroupSettings(context, group);
              },
            ),
          if (!isCurrentUserLeader)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                _showLeaveGroupDialog(context, group);
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
                  if (isCurrentUserLeader)
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
                return _buildMemberItem(context, member, isCurrentUserLeader);
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
    final bool isCurrentUserLeader =
        true; // Moved from parent scope for this example

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
          if (isCurrentUserLeader)
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
                      group.name,
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
    bool isCurrentUserLeader,
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
          if (member.id == leaderUserId)
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
          isCurrentUserLeader && member.id != leaderUserId
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
                      _showLeaveGroupDialog(context, group);
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

  void _showLeaveGroupDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Leave Group'),
          content: Text(
            'Are you sure you want to leave "${group.name}"? You\'ll need to be invited again to rejoin.',
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
                Navigator.pop(context); // Also return to previous screen
              },
              child: Text('Leave Group', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
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
