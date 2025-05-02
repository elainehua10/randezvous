// Refactored GroupScreen with cleaner visuals and consistency with LeaderboardScreen

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/invite.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/member_profile.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  const GroupScreen({super.key, required this.groupId});

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Group group;
  late List<User> members;
  bool isLoading = true;
  bool isUserLeader = false;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

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
          isPublic: data['isPublic'] == true,
          iconUrl: data['iconUrl'] as String?,
          beaconFrequency: data['beaconFrequency'],
        );

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
    }
  }

  Future<void> _handleImageUpload(BuildContext context) async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) _uploadImage(File(image.path));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) _uploadImage(File(image.path));
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _uploadImage(File imageFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await Auth.uploadFileWithAuth("groups/icon", imageFile, {
        "groupId": widget.groupId,
      });
      Navigator.pop(context);

      if (response.statusCode == 200) {
        fetchGroupDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group image updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image')));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showGroupSettings(BuildContext context, Group group) {
    final TextEditingController nameController = TextEditingController(
      text: group.name,
    );

    bool isPublic = group.isPublic; // Local copy of group's publicity status
    int beaconFrequency = (group.beaconFrequency ?? 86400).round();
    print("Dropdown value: $beaconFrequency");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

                    // Toggle for Group Publicity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPublic ? Icons.public : Icons.lock,
                              color: isPublic ? Colors.green : Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              isPublic ? "Public Group" : "Private Group",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isPublic,
                          onChanged: (value) async {
                            setState(() {
                              isPublic = value; // Update UI immediately
                            });
                          },
                          activeColor: Colors.amber[800],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Beacon Frequency Option
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Beacon Frequency",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: beaconFrequency,
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text("0 times per day"),
                            ),
                            DropdownMenuItem(
                              value: 86400,
                              child: Text("Once a day"),
                            ),
                            DropdownMenuItem(
                              value: 604800,
                              child: Text("Once a week"),
                            ),
                            DropdownMenuItem(
                              value: 1209600,
                              child: Text("Once every two weeks"),
                            ),
                            DropdownMenuItem(
                              value: 2592000,
                              child: Text("Once a month"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              beaconFrequency = value!;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) =>
                                    Center(child: CircularProgressIndicator()),
                          );

                          try {
                            // Update name
                            final nameResponse =
                                await Auth.makeAuthenticatedPostRequest(
                                  "/groups/rename",
                                  {
                                    "groupId": widget.groupId,
                                    "newName": newName,
                                  },
                                );

                            // Update beacon frequency
                            final freqResponse =
                                await Auth.makeAuthenticatedPostRequest(
                                  "/groups/setbfreq",
                                  {
                                    "groupId": widget.groupId,
                                    "frequency": beaconFrequency,
                                  },
                                );

                            // Update public/private
                            final pubResponse =
                                await Auth.makeAuthenticatedPostRequest(
                                  "/groups/setpub",
                                  {
                                    "groupId": widget.groupId,
                                    "isPublic": isPublic,
                                  },
                                );

                            Navigator.pop(context); // Close loading dialog

                            if (freqResponse.statusCode == 200 &&
                                pubResponse.statusCode == 200) {
                              Navigator.pop(context); // Close modal
                              fetchGroupDetails(); // Refresh UI
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Group settings updated.'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update group settings.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: ${e.toString()}")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Leave Group',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Leave Group"),
              ),
            ],
          );
        },
      );
    }
  }

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

  Widget _buildGroupHeader() {
    return Column(
      children: [
        SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber[500]!, width: 4),
              ),
              child: ClipOval(
                child:
                    group.iconUrl != null
                        ? Image.network(group.iconUrl!, fit: BoxFit.cover)
                        : Icon(Icons.group, size: 60, color: Colors.grey[400]),
              ),
            ),
            if (isUserLeader)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _handleImageUpload(context),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.amber[500]!),
                    ),
                    child: Icon(
                      Icons.upload,
                      size: 20,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          group.name ?? 'Group Name',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.amber[800],
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMemberList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isLeader = member.id == group.leaderId;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.amber[100],
              child:
                  member.avatarUrl != null
                      ? ClipOval(
                        child: Image.network(
                          member.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                      : Icon(Icons.person, color: Colors.amber[800]),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (isLeader)
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
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberProfileScreen(userId: member.id),
                  ),
                ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber[800]),
        ),
        backgroundColor: Colors.white,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          group.name ?? 'Group',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.amber[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.amber[800]),
        actions: [
          if (isUserLeader)
            IconButton(
              icon: Icon(Icons.settings, color: Colors.amber[800]),
              onPressed: () => _showGroupSettings(context, group),
            ),
          if (!isUserLeader)
            IconButton(
              icon: Icon(Icons.logout, color: Colors.amber[800]),
              onPressed: () => _showLeaveGroupDialog(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildGroupHeader(),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members (${members.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  if (isUserLeader)
                    ElevatedButton.icon(
                      onPressed:
                          () =>
                              InviteMembersDialog.show(context, widget.groupId),
                      icon: Icon(
                        Icons.person_add,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text('Invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
            _buildMemberList(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
