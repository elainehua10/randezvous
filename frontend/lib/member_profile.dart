import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/auth.dart';

class MemberProfileScreen extends StatefulWidget {
  final String userId;

  MemberProfileScreen({Key? key, required this.userId}) : super(key: key);

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
      final response = await Auth.makeAuthenticatedPostRequest(
        "user/view-profile",
        {"userId": widget.userId},
      );
      final data = json.decode(response.body);
      print(data);
      if (response.statusCode == 200) {
        setState(() {
          userProfile = data['profile'];
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
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.amber[50],
            backgroundImage: userProfile != null && userProfile!['profile_picture'] != null
                ? NetworkImage(userProfile!['profile_picture'])
                : null,
            child: userProfile == null || userProfile!['profile_picture'] == null
                ? Icon(Icons.person, size: 60, color: Colors.amber[800])
                : null,
          ),
          SizedBox(height: 16),
          Text(
            '${userProfile?['first_name'] ?? 'First'} ${userProfile?['last_name'] ?? 'Last'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '@${userProfile?['username'] ?? 'username'}',
            style: TextStyle(
              color: Colors.amber[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

  //@override
  /*Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Text(userProfile!['username'] ?? 'N/A'),
                  Text('${userProfile!['first_name'] ?? 'First'} ${userProfile!['last_name'] ?? 'Last'}'),
                  userProfile?['profile_picture'] != null
                      ? Image.network(userProfile?['profile_picture'])
                      : SizedBox(height: 200, child: Icon(Icons.account_circle, size: 200)),
                ],
              ),
            ),
    );
  }*/
//}