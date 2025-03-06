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
          }),
          _buildListTile(title: "Achievements", onTap: () {
          }),
          _buildListTile(title: "Settings", onTap: () {
          }),
          _buildListTile(title: "Log out", onTap: () {
          }),
          _buildListTile(title: "Delete Account", onTap: () {
          }),
        ],
      ),
    );
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
          Text("First Last", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text("@username", style: TextStyle(color: Colors.grey)),
        ],
      ),
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
