import 'package:flutter/material.dart';
import 'package:frontend/models/group.dart';
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

  // Sample data - in a real app, this would come from a service
  final List<Group> _groups = [
    Group(id: 'friends_group_id', name: 'Friends Group'),
    Group(id: 'work_buddies_id', name: 'Work Buddies'),
    Group(id: 'gaming_squad_id', name: 'Gaming Squad'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.selectedGroupId;
  }

  void _handleGroupSelection(Group group, BuildContext context) {
    setState(() {
      if (_selectedGroupId == group.id) {
        _selectedGroupId = null;
      } else {
        _selectedGroupId = group.id;
      }
    });

    widget.onGroupSelected(group);
    Navigator.pop(context);
  }

  void _createNewGroup() {
    print('Create New Group Tapped');
    // Navigate to group creation screen or show dialog
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Invites',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10),
        Container(
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
        ),
      ],
    );
  }
}
