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
        print("sakldfja $data");
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
    print(groupName);
    print(isPublic);

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Create Group",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: "Group Name",
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.amber[800]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
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
                              "Public Group",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value;
                            });
                          },
                          activeColor: Colors.amber[800],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  if (errorMessage != null) // Display error if it exists
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.3,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row with "Create Group" button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Groups',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                          Row(
                            children: [
                              // Add Search button here
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, "/search");
                                },
                                icon: Icon(Icons.search, size: 20),
                                label: Text("Search"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  foregroundColor: Colors.grey[800],
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8), // Add space between buttons
                              ElevatedButton.icon(
                                onPressed: _createNewGroup,
                                icon: Icon(Icons.add, size: 20),
                                label: Text("Create"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[800],
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Pending Invites Section
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber[800]!,
                            ),
                          ),
                        )
                      else
                        _buildPendingInvitesSection(),
                      SizedBox(height: 20),

                      // Your Groups Section
                      Text(
                        'Your Groups',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child:
                            _isLoading
                                ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.amber[800]!,
                                    ),
                                  ),
                                )
                                : _groups.isEmpty
                                ? _buildNoGroupsMessage()
                                : ListView.builder(
                                  controller: scrollController,
                                  itemCount: _groups.length,
                                  itemBuilder: (context, index) {
                                    final group = _groups[index];
                                    return GroupItem(
                                      group: group,
                                      isSelected: _selectedGroupId == group.id,
                                      onTap:
                                          () => _handleGroupSelection(
                                            group,
                                            context,
                                          ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children:
                _pendingInvites.map((group) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mail,
                          color: Colors.orange[800],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        group.name ?? "Unnamed Group",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text("You've been invited to join"),
                      trailing: ElevatedButton(
                        onPressed: () => _acceptInvite(group.id ?? ""),
                        child: Text("Accept"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPendingInvites() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mail_outline, color: Colors.grey[500], size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No pending invites',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'When someone invites you to a group, it will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGroupsMessage() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add, color: Colors.amber[800], size: 40),
          ),
          SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new group or search for existing ones to join',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createNewGroup,
            icon: Icon(Icons.add, size: 20),
            label: Text("Create New Group"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
