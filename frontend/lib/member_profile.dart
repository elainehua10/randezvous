import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/auth.dart';

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
          )),
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
