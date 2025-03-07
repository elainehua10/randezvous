import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:frontend/edit_profile.dart';

class ProfileScreen extends StatefulWidget {
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
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const Divider(),
                  _buildListTile(
                    title: "Edit Profile",
                    onTap: () => _navigateAndRefresh(context),
                  ),
                  _buildListTile(title: "Achievements", onTap: () {}),
                  _buildListTile(title: "Settings", onTap: () {}),
                  _buildListTile(
                    title: "Log out",
                    onTap: () => _handleLogout(context),
                  ),
                  _buildListTile(
                    title: "Delete Account",
                    onTap: () => _handleDelete(context),
                  ),
                ],
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
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
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
      String? accessToken = await Auth.getAccessToken();
      String userId = username;

      final url = Uri.parse('http://localhost:5001/api/v1/delete-account');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
        body: jsonEncode({'userId': userId}),
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
          );
        },
      );
    }
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

  ImageProvider<Object>? getBackgroundImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }
    if (icon != "pfp") {
      return NetworkImage(icon);
    } else
      return null;
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
                backgroundImage: getBackgroundImage(),
                child: getBackgroundImage() == null ? Icon(Icons.person, size: 50, color: Colors.white) : null,
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
                  onPressed: () => _showEditPhotoOptions(context),
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

  void _showEditPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from library'),
                onTap: () {
                  _pickImage(ImageSource.gallery, context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take photo'),
                onTap: () {
                  _pickImage(ImageSource.camera, context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    _profileImage = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      print("Image picked: ${pickedFile.path}");
      try {
        final response = await Auth.uploadFileWithAuth(
          '/set-profile-picture',
          File(pickedFile.path),
          {},
        );
        final responseData = jsonDecode(response.body);
        print(responseData);
        _fetchUserDetails();
      } catch (e) {
        print(e);
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Upload Error'),
                content: Text(
                  'An error occurred while uploading the image. Please try again.',
                ),
              ),
        );
      }
    }
    Navigator.pop(context);
  }

  Widget _buildListTile({required String title, required VoidCallback onTap}) {
    return ListTile(
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
