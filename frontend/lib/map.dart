import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 1; // Start with index 1 which corresponds to 'Location'
  String? _selectedGroupId; // Track the currently selected group's ID
  String? _selectedGroupName; // Track the currently selected group's Name

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _buildBottomSheetContent(context); // Separate builder function
      },
    );
  }

  Widget _buildBottomSheetContent(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, // Start at 75% of the screen
      minChildSize: 0.3, // Minimum size is 30% of the screen
      maxChildSize: 1.0, // Can be dragged to full screen
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
                    onPressed: () {
                      print('Create New Group Tapped');
                    },
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
              SizedBox(height: 20),

              // Your Groups Section
              Text(
                'Your Groups',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView(
                  controller: scrollController, // Enables dragging
                  children: [
                    _buildGroupItem(
                      'Friends Group',
                      'friends_group_id',
                    ), // Added ID
                    _buildGroupItem(
                      'Work Buddies',
                      'work_buddies_id',
                    ), // Added ID
                    _buildGroupItem(
                      'Gaming Squad',
                      'gaming_squad_id',
                    ), // Added ID
                  ],
                ),
              ),
              if (_selectedGroupId != null) // Added display of selected group
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Selected Group ID (in BottomSheet): $_selectedGroupId',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupItem(String groupName, String groupId) {
    final isSelected = _selectedGroupId == groupId;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300], // Placeholder for group image
        ),
        child: Icon(Icons.group, color: Colors.white),
      ),
      title: Text(groupName),
      tileColor:
          isSelected ? Colors.blue[100] : null, // Highlight selected tile
      onTap: () {
        setState(() {
          if (_selectedGroupId == groupId) {
            // Deselect if already selected
            _selectedGroupId = null;
            _selectedGroupName = null;
          } else {
            // Select new group
            _selectedGroupId = groupId;
            _selectedGroupName = groupName;
          }
          print('$groupName Selected with ID: $groupId');
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RandezVous'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.groups, color: Colors.black),
          onPressed: _openBottomSheet, // Open bottom sheet on tap
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.black),
            onPressed: () {
              print('Profile button tapped');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.blueAccent, width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Map Placeholder',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
              SizedBox(height: 20),
              if (_selectedGroupId != null)
                Column(
                  children: [
                    Text(
                      'Selected Group: $_selectedGroupName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Selected Group ID: $_selectedGroupId',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: ' '),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ' '),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: ' '),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
