import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:frontend/auth.dart';
import 'package:frontend/services/notification_service.dart';

class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  _GlobalLeaderboardScreenState createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen> {
  List<dynamic> globalLeaderboard = [];
  bool isLoading = true;
  String currentUserId = '';
  int _selectedIndex = 2; // Set to 2 for Leaderboard tab

  @override
  void initState() {
    super.initState();
    _fetchGlobalLeaderboard();
    _fetchCurrentUserId();
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

  Future<void> _fetchGlobalLeaderboard() async {
    try {
      final response = await Auth.makeAuthenticatedGetRequest(
        "groups/global-leaderboard",
      );
      print('RAW RESPONSE: ${response.body}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final leaderboardData = data['leaderboard'];
        if (leaderboardData is List) {
          setState(() {
            globalLeaderboard = leaderboardData;
            isLoading = false;
          });
        } else {
          setState(() {
            globalLeaderboard = [];
            isLoading = false;
          });
          print('Warning: global leaderboard is not a list');
        }
      } else {
        print('Failed to load global leaderboard: $data');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching global leaderboard: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index != 2) {
      // If not on the leaderboard tab
      if (index == 0) {
        // Navigate to Explore/Home screen
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (index == 1) {
        // Navigate to Map screen
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      // For leaderboard tab, navigate to leaderboard_screen.dart instead of leaderboard_page
      Navigator.pop(
        context,
      ); // Go back to previous screen which should be leaderboard_screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Global Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
                ),
              )
              : globalLeaderboard.isEmpty
              ? Center(child: Text('No global leaderboard data available.'))
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

  Widget _buildLeaderboardContent() {
    globalLeaderboard.sort(
      (a, b) => (b['group_score'] ?? 0).compareTo(a['group_score'] ?? 0),
    );

    return Column(
      children: [
        SizedBox(height: 20), // Space below app bar

        if (globalLeaderboard.isNotEmpty)
          _buildTopGroupWidget(globalLeaderboard[0]),

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
              itemCount: globalLeaderboard.length,
              itemBuilder: (context, index) {
                if (index == 0) return SizedBox.shrink();

                final group = globalLeaderboard[index];
                final groupName = group['name'] ?? 'Unnamed Group';
                final groupScore = group['group_score'] ?? 0;
                final groupIconUrl = group['icon_url'];

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rank number to left of group icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
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
                        // Group icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: ClipOval(
                            child:
                                groupIconUrl != null
                                    ? Image.network(
                                      groupIconUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          Icons.group,
                                          size: 24,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    )
                                    : Icon(
                                      Icons.group,
                                      size: 24,
                                      color: Colors.grey[400],
                                    ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      groupName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '$groupScore pts',
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

  Widget _buildTopGroupWidget(dynamic topGroup) {
    final groupName = topGroup['name'] ?? 'Unnamed Group';
    final groupScore = topGroup['group_score'] ?? 0;
    final groupIconUrl = topGroup['icon_url'];

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
                      groupIconUrl != null
                          ? Image.network(
                            groupIconUrl,
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
          groupName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber[500], size: 20),
            SizedBox(width: 4),
            Text(
              '$groupScore pts',
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
