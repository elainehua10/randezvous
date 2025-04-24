import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/member_profile.dart';
import 'dart:convert';
//import 'dart:io';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  String firstName = "First";
  String lastName = "Last";
  String username = "username";
  late TabController _tabController;
  bool isLoading = false;
  List<dynamic> friends = [];
  List<dynamic> pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "get-user-profile-info",
        {},
      );
      final data = json.decode(response.body);
      print(data);
      if (response.statusCode == 200) {
        setState(() {
          firstName = data['first_name'] ?? 'First';
          lastName = data['last_name'] ?? 'Last';
          username = data['username'] ?? 'username';
          friends = data['friends'] ?? [];
          pendingRequests = data['pending_requests'] ?? [];
          isLoading = false;
        });
      } else {
        print(data);
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleAcceptRequest(Map<String, dynamic> request) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        'user/accept-friend-request',
        {
          "senderId": request['id'],
          "receiverId": await Auth.getCurrentUserId(),
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request accepted")),
        );
        _fetchUserDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to accept friend request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _handleDeclineRequest(Map<String, dynamic> request) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        'user/decline-friend-request',
        {
          "senderId": request['id'],
          "receiverId": await Auth.getCurrentUserId(),
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Friend request declined")),
        );
        _fetchUserDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to decline friend request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Social", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.amber[800],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.amber[800],
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people),
                    SizedBox(width: 8),
                    Text("Friends (${friends.length})"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text("Requests (${pendingRequests.length})"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Friends Tab
                friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No friends yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add friends to connect with them",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return InkWell(
                            onTap: () {
                              print('Navigating to friend profile with ID: ${friend['id']}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MemberProfileScreen(userId: friend['id']),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber[100],
                                  child:
                                      friend['profile_picture'] == null
                                          ? Icon(Icons.person, color: Colors.amber[800])
                                          : Image.network(friend['profile_picture']!, height: 80, width: 80),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      "${friend['first_name']} ${friend['last_name']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          /*return Card(
                            elevation: 1,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber[100],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.amber[800],
                                ),
                              ),
                              title: Text(
                                friend['username'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('@${friend['handle'] ?? ''}'),
                            ),
                          );*/
                        },
                      ),

                // Requests Tab
                pendingRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_disabled, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No pending requests",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Friend requests will appear here",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: pendingRequests.length,
                        itemBuilder: (context, index) {
                          final request = pendingRequests[index];
                          return InkWell(
                          onTap: () {
                            print('Navigating to friend profile with ID: ${request['id']}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemberProfileScreen(userId: request['id']),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.all(8),   // Add padding around Column
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.amber[100],
                                      child: request['profile_picture'] == null
                                          ? Icon(Icons.person, color: Colors.amber[800])
                                          : Image.network(request['profile_picture']!, height: 80, width: 80),
                                    ),
                                    title: Text(
                                      "${request['first_name']} ${request['last_name']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _handleAcceptRequest(request),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber[800],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text("Accept"),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _handleDeclineRequest(request),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text("Decline"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        },
                      ),
              ],
            ),
    );
  }
}