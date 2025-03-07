import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/group_item.dart';

class GroupsBottomSheet extends StatefulWidget {
  final String? selectedGroupId;
  final Function(Group) onGroupSelected;

  const GroupsBottomSheet({
    Key? key,
    this.selectedGroupId,
    required this.onGroupSelected,
  }) : super(key: key);

  @override
  _GroupsBottomSheetState createState() => _GroupsBottomSheetState();
}

class _GroupsBottomSheetState extends State<GroupsBottomSheet> {
  String? _selectedGroupId;
  List<Group> _groups = [];
  List<Group> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.selectedGroupId;
    _fetchGroupsAndInvites();
  }

  Future<void> _fetchGroupsAndInvites() async {
    setState(() => _isLoading = true);
    try {
      // Fetch user groups
      final response = await Auth.makeAuthenticatedPostRequest(
        "groups/getgroups",
        {},
      );
      final data = json.decode(response.body);
      print(data);

      if (response.statusCode == 200) {
        setState(() {
          _groups =
              (data as List).map((group) => Group.fromJson(group)).toList();
          _isLoading = false;
        });
      } else {
        print("Failed to load groups: ${response.body}");
        throw Exception('Failed to load groups');
      }

      // Fetch pending invites
      final inviteResponse = await Auth.makeAuthenticatedPostRequest(
        "groups/getinvites",
        {},
      );
      final inviteData = json.decode(inviteResponse.body);
      print(inviteData);

      if (inviteResponse.statusCode == 200) {
        setState(() {
          _pendingInvites =
              (inviteData as List)
                  .map((invite) => Group.fromJson(invite))
                  .toList();
        });
      } else {
        print("Failed to load invites: ${inviteResponse.body}");
      }
    } catch (e) {
      print("Error fetching groups/invites: $e");
      setState(() => _isLoading = false);
    }
  }

  void _handleGroupSelection(Group group, BuildContext context) {
    setState(() {
      _selectedGroupId = (_selectedGroupId == group.id) ? null : group.id;
    });

    widget.onGroupSelected(group);
    Navigator.pop(context);
  }

  Future<void> _acceptInvite(String groupId) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "groups/accept",
        {"groupId": groupId},
      );

      if (response.statusCode == 200) {
        _fetchGroupsAndInvites(); // Refresh groups and invites after accepting
      } else {
        print("Error accepting invite: ${response.body}");
      }
    } catch (e) {
      print("Error accepting invite: $e");
    }
  }

  Future<void> _createGroup(String groupName, bool isPublic) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "groups/create",
        {
          "groupName": groupName,
          "isPublic": isPublic, // `true` for public, `false` for private
        },
      );

      if (response.statusCode == 200) {
        print("Group created successfully!");
        _fetchGroupsAndInvites(); // Refresh group list
      } else {
        print("Error creating group: ${response.body}");
      }
    } catch (e) {
      print("Error creating group: $e");
    }
  }

  void _createNewGroup() {
  TextEditingController groupNameController = TextEditingController();
  bool isPublic = false; // Default to private
  String? errorMessage; // Store error message

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Create Group"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groupNameController,
                  decoration: InputDecoration(labelText: "Group Name"),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Public"),
                    Switch(
                      value: isPublic,
                      onChanged: (value) {
                        setState(() {
                          isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (errorMessage != null) // Display error if it exists
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String groupName = groupNameController.text.trim();
                  if (groupName.isEmpty) {
                    setState(() => errorMessage = "Enter a group name.");
                    return;
                  }

                  try {
                    final response = await Auth.makeAuthenticatedPostRequest(
                      "groups/create",
                      {"groupName": groupName, "isPublic": isPublic},
                    );

                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      _fetchGroupsAndInvites(); // Refresh group list
                    } else {
                      final errorData = json.decode(response.body);
                      setState(() {
                        errorMessage = errorData['error'];
                      });
                    }
                  } catch (e) {
                    setState(() => errorMessage = "Error creating group.");
                  }
                },
                child: Text("Create"),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.3,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row with "Create Group" button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Groups',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _createNewGroup,
                    icon: Icon(Icons.add, size: 20),
                    label: Text("Create"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Pending Invites Section
              _buildPendingInvitesSection(),
              SizedBox(height: 20),

              // Your Groups Section
              Text(
                'Your Groups',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return GroupItem(
                      group: group,
                      isSelected: _selectedGroupId == group.id,
                      onTap: () => _handleGroupSelection(group, context),
                    );
                  },
                ),
              ),
              if (_selectedGroupId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Selected Group ID: $_selectedGroupId',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitesSection() {
    if (_pendingInvites.isEmpty) {
      return _buildNoPendingInvites();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Invites',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10),
        Column(
          children:
              _pendingInvites.map((group) {
                return ListTile(
                  leading: Icon(Icons.mail, color: Colors.orange),
                  title: Text(group.name),
                  trailing: ElevatedButton(
                    onPressed: () => _acceptInvite(group.id),
                    child: Text("Accept"),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoPendingInvites() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.mail, color: Colors.orange),
          SizedBox(width: 10),
          Text('No pending invites', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
