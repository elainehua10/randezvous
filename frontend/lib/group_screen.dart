import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/invite.dart';
import 'package:frontend/auth.dart';
import 'package:image_picker/image_picker.dart';

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
          name: data['name'],
          leaderId: data['leader_id'],
          isPublic: data['isPublic'] == true, // Ensure it’s a boolean
          iconUrl: data['iconUrl'] as String?, // Allow it to be null
        );

        print(group.iconUrl);
        members =
            (data['members'] as List)
                .map(
                  (m) => User(
                    id: m['id'],
                    name: "${m['first_name']} ${m['last_name']}",
                    avatarUrl: m['profile_picture'],
                    username: '',
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
      "groupId": widget.groupId,
    });

    if (response.statusCode == 200) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, "/home");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("You have left the group.")));
    } else {
      print("Error leaving group: ${response.body}");
    }
  }

  // Show confirmation dialog before leaving the group
  void _showLeaveGroupDialog() {
    if (isUserLeader) {
      if (members.length <= 1) {
        // Case when leader is the only member
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Cannot Leave Group"),
              content: Text(
                "You are the only member of this group. As the leader, you cannot leave unless there are other members. Please invite someone before trying to leave.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        // Case when leader needs to assign new leader
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Assign New Leader"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "As the group leader, you must assign a new leader before leaving. Please select a member to become the new leader:",
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<User>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select New Leader",
                    ),
                    items:
                        members
                            .where((member) => member.id != group.leaderId)
                            .map(
                              (member) => DropdownMenuItem(
                                value: member,
                                child: Text(member.name),
                              ),
                            )
                            .toList(),
                    onChanged: (selectedMember) async {
                      if (selectedMember != null) {
                        // API call to assign new leader
                        final response =
                            await Auth.makeAuthenticatedPostRequest(
                              "groups/assign-leader",
                              {
                                "groupId": widget.groupId,
                                "newLeaderId": selectedMember.id,
                              },
                            );

                        if (response.statusCode == 200) {
                          // After successful assignment, proceed with leaving
                          _leaveGroup();
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to assign new leader: ${response.body}",
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
              ],
            );
          },
        );
      }
    } else {
      // Original dialog for non-leaders
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
            _buildGroupHeader(context, group, isUserLeader),

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

  Future<void> _handleImageUpload(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // Show a dialog to let the user choose between camera and gallery
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    _uploadImage(File(image.path));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1000,
                    maxHeight: 1000,
                    imageQuality: 85,
                  );
                  if (photo != null) {
                    _uploadImage(File(photo.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this function to handle the image upload process
  Future<void> _uploadImage(File imageFile) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      print(widget.groupId);
      final response = await Auth.uploadFileWithAuth("groups/icon", imageFile, {
        "groupId": widget.groupId,
      });
      final responseData = jsonDecode(response.body);
      print(responseData);
      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        // Refresh group details to show the new image
        fetchGroupDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group image updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildGroupHeader(
    BuildContext context,
    Group group,
    bool isUserLeader,
  ) {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.blue[100],
            child: Center(
              child:
                  group.iconUrl == null
                      ? Icon(Icons.group, size: 80, color: Colors.blue[800])
                      : Image.network(
                        group.iconUrl!,
                        height:
                            80, // Optional: adding height to match icon size
                        width: 80, // Optional: adding width to match icon size
                      ),
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
    print(member.avatarUrl);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child:
            member.avatarUrl == null
                ? Icon(Icons.person, color: Colors.blue[800])
                : Image.network(
                  member.avatarUrl!,
                  height: 80, // Optional: adding height to match icon size
                  width: 80, // Optional: adding width to match icon size
                ),
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
    // Create a TextEditingController to manage the input
    final TextEditingController nameController = TextEditingController(
      text: group.name,
    );

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
                  controller: nameController,
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
                    onPressed: () async {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) =>
                                Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // Make API call to rename group
                        final response =
                            await Auth.makeAuthenticatedPostRequest(
                              "groups/rename",
                              {
                                "groupId": widget.groupId,
                                "newName": nameController.text.trim(),
                              },
                            );

                        // Close loading dialog
                        Navigator.pop(context);

                        if (response.statusCode == 200) {
                          // Update local group data
                          fetchGroupDetails();

                          // Close settings dialog
                          Navigator.pop(context);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Group name updated successfully'),
                            ),
                          );
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update group name: ${response.body}',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        // Close loading dialog
                        Navigator.pop(context);

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
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
    InviteMembersDialog.show(context, widget.groupId);
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
              onPressed: () async {
                await Auth.makeAuthenticatedPostRequest("groups/remove", {
                  "groupId": widget.groupId, // Pass the groupId here
                  "removingUserId": member.id, // Pass the user ID to invite
                });
                await fetchGroupDetails();
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
