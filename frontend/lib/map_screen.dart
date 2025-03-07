import 'package:flutter/material.dart';
import 'package:frontend/widgets/map.dart';
import 'package:frontend/widgets/groups_bottom_sheet.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/group_screen.dart';
import 'package:frontend/auth.dart'; // Assuming this contains makeAuthenticatedPostRequest
import 'dart:convert'; // For JSON decoding

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 1; // Start with index 1 which corresponds to 'Location'
  String? _selectedGroupId; // Track the currently selected group's ID
  String? _selectedGroupName; // Track the currently selected group's Name

  @override
  void initState() {
    super.initState();
    _checkGroupMembership(); // Check membership on load
    print("ldlasdfkajdl");
  }

  Future<void> _checkGroupMembership() async {
    if (_selectedGroupId == null) return; // No group selected, no need to check

    print("HLELLO?");

    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "groups/check-membership",
        {"groupId": _selectedGroupId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isMember =
            data['isMember'] ?? false; // Adjust based on your API response
        print("LKjkjalsdfjsl IS MEMBER???? $isMember");

        if (!isMember) {
          setState(() {
            _selectedGroupId = null; // Clear if user is not a member
            _selectedGroupName = null;
          });
        }
      }
    } catch (e) {
      print("Error checking group membership: $e");
      setState(() {
        _selectedGroupId = null; // Clear on error
        _selectedGroupName = null;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openGroupsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return GroupsBottomSheet(
          selectedGroupId: _selectedGroupId,
          onGroupSelected: (Group group) {
            setState(() {
              if (_selectedGroupId == group.id) {
                // Deselect if already selected
                _selectedGroupId = null;
                _selectedGroupName = null;
              } else {
                // Select new group and check membership
                _selectedGroupId = group.id;
                _selectedGroupName = group.name;
                _checkGroupMembership(); // Re-check membership after selection
              }
            });
          },
        );
      },
    );
  }

  void _navigateToGroupScreen() async {
    if (_selectedGroupId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupScreen(groupId: _selectedGroupId!),
        ),
      );
      _checkGroupMembership();
    }
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
          onPressed: _openGroupsBottomSheet,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.black),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _checkGroupMembership();
              print('Profile button tapped');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map takes the full container
          Container(
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: MapWidget(),
          ),

          // Floating group indicator
          if (_selectedGroupName != null)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _navigateToGroupScreen,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 143, 0, 0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedGroupName!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: ' '),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ' '),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: ' '),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(255, 143, 0, 1),
        onTap: _onItemTapped,
      ),
    );
  }
}
