import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:frontend/edit_profile.dart';
import 'package:frontend/settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String firstName = "First";
  String lastName = "Last";
  String username = "username";
  bool isLoading = true;
  String icon = "pfp";
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

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
          icon = data['profile_picture'] ?? 'pfp';
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
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              "Account Settings",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          _buildListTile(
                            title: "Edit Profile",
                            subtitle: "Change your personal information",
                            icon: Icons.edit_rounded,
                            onTap: () => _navigateAndRefresh(context),
                          ),
                          _buildDivider(),
                          _buildListTile(
                            title: "Achievements",
                            subtitle: "View your badges and accomplishments",
                            icon: Icons.emoji_events_rounded,
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildListTile(
                            title: "Settings",
                            subtitle: "Notification and privacy preferences",
                            icon: Icons.settings_rounded,
                            onTap:
                                () => Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              "Account Actions",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          _buildListTile(
                            title: "Log out",
                            subtitle: "Sign out of your account",
                            icon: Icons.logout_rounded,
                            onTap: () => _handleLogout(context),
                            iconColor: Colors.amber[800]!,
                          ),
                          _buildDivider(),
                          _buildListTile(
                            title: "Delete Account",
                            subtitle:
                                "Permanently remove your account and data",
                            icon: Icons.delete_forever_rounded,
                            iconColor: Colors.red,
                            textColor: Colors.red,
                            onTap: () => _handleDelete(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
    );
  }

  void _navigateAndRefresh(BuildContext context) {
    Navigator.pushNamed(context, '/edit-profile').then((value) {
      if (value == true) {
        _fetchUserDetails();
      }
    });
  }

  void _handleDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
            'Are you sure you want to delete your account permanently? This action cannot be undone.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // close the dialog
                _deleteAccount(); // call delete function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "delete-account",
        {"refreshToken": await Auth.getRefreshToken()},
      );

      if (response.statusCode == 200) {
        print('Account deleted successfully');
        Auth.removeTokens();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Handle different status codes or server errors
        final responseData = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Failed to Delete Account'),
              content: Text(responseData['error'] ?? 'Unknown error occurred.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        print('Failed to delete account: ${response.body}');
      }
    } catch (e) {
      print("Error deleting account: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while deleting the account.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest("logout", {});
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

  ImageProvider<Object>? getBackgroundImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }
    if (icon != "pfp") {
      return NetworkImage(icon);
    } else {
      return null;
    }
  }

  Widget _buildProfileHeader() {
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
                  backgroundImage: getBackgroundImage(),
                  child:
                      getBackgroundImage() == null
                          ? Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: Colors.amber[800],
                          )
                          : null,
                ),
              ),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.amber[800],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _showEditPhotoOptions(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "$firstName $lastName",
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
              "@$username",
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

  void _showEditPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Profile Photo",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text('Choose from library'),
                  onTap: () {
                    _pickImage(ImageSource.gallery, context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.green,
                    ),
                  ),
                  title: Text('Take photo'),
                  onTap: () {
                    _pickImage(ImageSource.camera, context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  title: Text(
                    'Delete photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    _deletePhoto(context);
                    Navigator.pop(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    Navigator.pop(context); // Close bottom sheet first
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      print("Image picked: ${pickedFile.path}");

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber[800]!,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text("Uploading..."),
                ],
              ),
            ),
          );
        },
      );

      try {
        final response = await Auth.uploadFileWithAuth(
          '/set-profile-picture',
          File(pickedFile.path),
          {},
        );
        Navigator.pop(context); // Close loading dialog
        final responseData = jsonDecode(response.body);
        print(responseData);
        _fetchUserDetails();
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        print(e);
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Upload Error'),
                content: Text(
                  'An error occurred while uploading the image. Please try again.',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'OK',
                      style: TextStyle(color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _deletePhoto(BuildContext context) async {
    setState(() {
      _profileImage = null;
      icon = "pfp";
    });
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        '/set-profile-picture',
        {'deletePhoto': true},
      );
      final responseData = jsonDecode(response.body);
      print(responseData);
    } catch (e) {
      print(e);
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Delete Error'),
              content: Text(
                'An error occurred while deleting the photo. Please try again.',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      );
    }
  }

  Widget _buildListTile({
    required String title,
    required VoidCallback onTap,
    required IconData icon,
    String? subtitle,
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(indent: 56, endIndent: 16, height: 1);
  }
}
