import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String firstName = "First";
  String lastName = "Last";
  String username = "username";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
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
        title: Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const Divider(),
                  _buildListTile(title: "Account Details", onTap: () {}),
                  _buildListTile(title: "Achievements", onTap: () {}),
                  _buildListTile(title: "Settings", onTap: () {}),
                  _buildListTile(
                    title: "Log out",
                    onTap: () => _handleLogout(context),
                  ),
                  _buildListTile(title: "Delete Account", onTap: () {}),
                ],
              ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest("logout", {});
      Auth.removeTokens();

      Auth.removeTokens();
      if (response.statusCode == 200) {
        print("Logout successful");

        // Navigate to the login screen
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print("Logout failed: ${response.body}");
      }
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 92, 181, 254),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 15),
                  onPressed: () {
                    // Action to edit user info
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "$firstName $lastName",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text("@$username", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      //leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          color: title == "Delete Account" ? Colors.red : Colors.black,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
