import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(),
          const Divider(),
          _buildListTile(title: "Account Details", onTap: () {
            // Handle navigation or functionality
          }),
          _buildListTile(title: "Achievements", onTap: () {
            // Handle navigation or functionality
          }),
          _buildListTile(title: "Settings", onTap: () {
            // Handle navigation or functionality
          }),
          _buildListTile(title: "Log out", onTap: () {
            // Handle logout
          }),
          _buildListTile(title: "Delete Account", onTap: () {
            // Handle account deletion
          }),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
  return Column(
    children: [
      CircleAvatar(
        radius: 50,  // Increased size for visibility
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      ),
      SizedBox(height: 8),
      Text("First Last", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      Text("@username", style: TextStyle(color: Colors.grey)),
    ],
  );
}

  Widget _buildListTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      //leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(color: title == "Delete Account" ? Colors.red : Colors.black),
      ),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
