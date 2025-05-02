import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:frontend/auth.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/global_leaderboard_screen.dart';
import 'package:frontend/widgets/groups_bottom_sheet.dart';
import 'package:frontend/models/group.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? groupId;

  const LeaderboardScreen({super.key, this.groupId});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;
  String currentUserId = '';
  int _selectedIndex = 2; // Set to 2 for Leaderboard tab
  String? groupName;

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _fetchLeaderboard();
      _fetchGroupName();
    } else {
      setState(() {
        isLoading = false;
      });
    }
    _fetchCurrentUserId();
    _verifyAuthentication();
  }

  void _verifyAuthentication() {
    Auth.getAccessToken().then(
      (value) => {
        if (value == null) {Navigator.pushReplacementNamed(context, "/login")},
      },
    );
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "get-user-profile-info",
        {},
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data != null) {
        setState(() {
          currentUserId = data['id'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching user ID: $e");
    }
  }

  Future<void> _fetchGroupName() async {
    if (widget.groupId == null) return;

    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "groups/details",
        {"groupId": widget.groupId},
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data != null) {
        setState(() {
          groupName = data['name'] ?? 'Group';
        });
      }
    } catch (e) {
      print("Error fetching group name: $e");
    }
  }

  Future<void> _fetchLeaderboard() async {
    if (widget.groupId == null) return;

    try {
      final response = await Auth.makeAuthenticatedGetRequest(
        "groups/member-leaderboard?groupId=${widget.groupId}",
      );
      print('RAW RESPONSE: ${response.body}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final leaderboardData = data['leaderboard'];
        if (leaderboardData is List) {
          setState(() {
            leaderboard = leaderboardData;
            isLoading = false;
          });
        } else {
          setState(() {
            leaderboard = [];
            isLoading = false;
          });
          print('Warning: leaderboard is not a list');
        }
      } else {
        print('Failed to load leaderboard: $data');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index != 2) {
      // If not leaderboard tab
      Navigator.pop(context); // Go back to previous screen

      // If needed, you can add logic to navigate to specific screens
      if (index == 0) {
        // Explore tab logic if needed
      } else if (index == 1) {
        // Map tab logic if needed
      }
    }
  }

  // void _showGroupSelection() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true, // Makes the bottom sheet full height
  //     backgroundColor: Colors.transparent, // Important for rounded corners
  //     builder:
  //         (_) => GroupsBottomSheet(
  //           selectedGroupId: widget.groupId,
  //           onGroupSelected: (Group group) {
  //             Navigator.pop(context);
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => LeaderboardScreen(groupId: group.id),
  //               ),
  //             );
  //           },
  //         ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.groupId == null
                  ? 'Leaderboard'
                  : (groupName ?? 'Leaderboard'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.public),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GlobalLeaderboardScreen(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          widget.groupId == null
              ? _buildNoGroupSelectedView()
              : isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
                ),
              )
              : leaderboard.isEmpty
              ? Center(child: Text('No leaderboard data available.'))
              : _buildLeaderboardContent(),
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
                label: 'Leaderboard',
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

  Widget _buildNoGroupSelectedView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
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
              child: Icon(Icons.group, size: 48, color: Colors.amber[800]),
            ),
            SizedBox(height: 24),
            Text(
              'Select an active group',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You need to join or select a group to view the leaderboard rankings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    leaderboard.sort((a, b) => (b['points'] ?? 0).compareTo(a['points'] ?? 0));

    int userPosition = leaderboard.indexWhere(
      (member) => member['id'] == currentUserId,
    );

    if (leaderboard.isEmpty) {
      return Center(child: Text('No leaderboard data available.'));
    }

    return Column(
      children: [
        SizedBox(height: 20), // Space below app bar

        if (leaderboard.isNotEmpty) _buildTopPlayerWidget(leaderboard[0]),

        SizedBox(height: 20),

        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                if (index == 0) return SizedBox.shrink();

                final member = leaderboard[index];
                final name =
                    member['username'] ?? (member['name'] ?? 'Unnamed');
                final points = member['points'] ?? 0;
                final profilePicture = member['profilePicture'];
                final isCurrentUser = member['id'] == currentUserId;

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.amber[300] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rank number to left of profile picture
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isCurrentUser ? Colors.white : Colors.grey[200],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Profile picture
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isCurrentUser ? Colors.white : Colors.grey[200],
                          ),
                          child: ClipOval(
                            child:
                                profilePicture != null
                                    ? Image.network(
                                      profilePicture,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          Icons.person,
                                          size: 24,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    )
                                    : Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.grey[400],
                                    ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      isCurrentUser ? 'You' : name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${points} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPlayerWidget(dynamic topPlayer) {
    final name = topPlayer['username'] ?? (topPlayer['name'] ?? 'Unnamed');
    final points = topPlayer['points'] ?? 0;
    final profilePicture = topPlayer['profilePicture'];
    final isCurrentUser = topPlayer['id'] == currentUserId;

    return Column(
      children: [
        SizedBox(
          height: 130, // give enough space for overflow above and below
          width: 110,
          child: Stack(
            clipBehavior: Clip.none,
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
                      profilePicture != null
                          ? Image.network(
                            profilePicture,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              );
                            },
                          )
                          : Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                ),
              ),
              Positioned(
                top: -10,
                child: Icon(Icons.star, size: 40, color: Colors.amber[600]),
              ),
              Positioned(
                bottom: -15,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.amber[500],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      "1",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          isCurrentUser ? 'You' : name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber[500], size: 20),
            SizedBox(width: 4),
            Text(
              '$points pts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
