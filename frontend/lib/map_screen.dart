import 'package:flutter/material.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/widgets/map.dart';
import 'package:frontend/widgets/groups_bottom_sheet.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/group_screen.dart';
import 'package:frontend/auth.dart';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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
    _verifyAuthentication();
  }

  void _verifyAuthentication() {
    Auth.getAccessToken().then(
      (value) => {
        if (value == null) {Navigator.pushReplacementNamed(context, "/login")},
      },
    );

    NotificationService.instance.getToken().then(
      (token) => {
        Auth.makeAuthenticatedPostRequest("set-device-id", {"deviceId": token}),
      },
    );
  }

  Future<void> _checkGroupMembership() async {
    if (_selectedGroupId == null) return; // No group selected, no need to check

    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "groups/check-membership",
        {"groupId": _selectedGroupId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isMember = data['isMember'] ?? false;

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
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.black.withOpacity(0.2),
            //       blurRadius: 10,
            //       offset: Offset(0, -2),
            //     ),
            //   ],
            // ),
            // height: MediaQuery.of(context).size.height * 0.7,
            child: GroupsBottomSheet(
              selectedGroupId: _selectedGroupId,
              onGroupSelected: (Group group) {
                try {
                  setState(() {
                    if (_selectedGroupId == group.id) {
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                    } else {
                      _selectedGroupId = group.id;
                      _selectedGroupName = group.name;
                      _checkGroupMembership(); // Async call, handle carefully
                    }
                  });
                  // Navigator.pop(context);
                } catch (e) {
                  print("Error in group selection: $e");
                }
              },
            ),
          );
        },
      );
    } catch (e) {
      print("Error opening bottom sheet: $e");
    }
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
      body: Stack(
        children: [
          // Map takes the full screen
          Container(
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: MapWidget(activeGroupId: _selectedGroupId),
          ),

          // Custom AppBar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Groups button
                  InkWell(
                    onTap: _openGroupsBottomSheet,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.groups_rounded,
                        color: Colors.amber[800],
                        size: 28,
                      ),
                    ),
                  ),

                  // App name
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Randezvous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile button
                  InkWell(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/profile');
                      _checkGroupMembership();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.amber[800],
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating group indicator
          if (_selectedGroupName != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: _navigateToGroupScreen,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
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
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Add the leaderboard icon
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/leaderboard');
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.leaderboard_rounded,
                  color: Colors.amber[800],
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront_rounded),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_rounded),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_rounded),
                label: 'Events',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[800],
            unselectedItemColor: Colors.grey[400],
            backgroundColor: Colors.transparent,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
