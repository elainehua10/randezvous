import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:frontend/auth.dart';
import 'package:frontend/models/user.dart';

class MemberProfileScreen extends StatefulWidget {
  final String userId;

  const MemberProfileScreen({super.key, required this.userId});

  @override
  _MemberProfileScreenState createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      print("Sending userId: ${widget.userId}");
      final response = await Auth.makeAuthenticatedPostRequest(
        "user/view-profile",
        {"userId": widget.userId},
      );
      final data = json.decode(response.body);
      print(data);
      if (response.statusCode == 200) {
        setState(() {
          userProfile = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title:
              Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.amber[800],
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                final profile = userProfile?['profile'];
                final user = User(
                  id: widget.userId,
                  name: '${profile['first_name']} ${profile['last_name']}',
                  username: profile['username'],
                  avatarUrl: profile['profile_picture']      
                );
                if (value == 'block') {
                  _showBlockConfirmation(user);
                } else if (value == 'report') {
                  //_showReportConfirmation();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Block'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Report'),
                    ],
                  ),
                ),
              ],
            )
          ],
          ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                  _buildGroupsList(),
                ],
              ),
            ),
    );
  }

  void _showBlockConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${user.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser(user.id ?? '');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser(String blockedUserId) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest("user/block", {
        "blockedId": blockedUserId,
      });

      if (response.statusCode == 200) {
        _showSuccessSnackBar('User blocked successfully!');
      } else {
        _showErrorSnackBar('Failed to block user: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error blocking user: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildProfileHeader() {
    final profile = userProfile?['profile'];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber[100]!, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.amber[50],
                  backgroundImage: profile != null &&
                          profile!['profile_picture'] != null
                      ? NetworkImage(profile!['profile_picture'])
                      : null,
                  child: profile == null ||
                          profile!['profile_picture'] == null
                      ? Icon(Icons.person,
                          size: 60, color: Colors.amber[800])
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '${profile?['first_name'] ?? 'First'} ${profile?['last_name'] ?? 'Last'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@${profile?['username'] ?? 'username'}',
              style: TextStyle(
                color: Colors.amber[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    if (userProfile == null ||
        userProfile!['groups'] == null ||
        (userProfile!['groups'] as List).isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("No groups found.",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    List<dynamic> groups = userProfile!['groups'];

    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Groups",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final points = group['points'];
              final rank = group['rank'];


              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: group['icon_url'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(group['icon_url']),
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.amber[800],
                        child: Icon(Icons.group, color: Colors.white),
                      ),
                title: Text(group['name']),
                subtitle: Text('Points: $points | Rank: $rank'),
                onTap: () {
                  // handle group tap if needed
                },
              );

            },
          ),
        ],
      ),
    );
  }
}
