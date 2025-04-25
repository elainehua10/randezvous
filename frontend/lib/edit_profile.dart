import 'package:flutter/material.dart';
import 'package:frontend/util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/auth.dart';
import 'dart:io';
import 'package:frontend/password_reset_screen.dart'; // This will be your new page

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  String firstName = "First";
  String lastName = "Last";
  String username = "username";
  String new_user = "";
  String? errorMessage;
  String email = "";
  final emailController = TextEditingController();

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
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Username section
            Form(
              key: _usernameFormKey,
              child: TextFormField(
                initialValue: new_user,
                decoration: InputDecoration(
                  labelText: 'New Username',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.amber[800]!),
                  ),
                  prefixIcon: Icon(Icons.edit, color: Colors.grey[700]),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
                onSaved: (value) => new_user = value!,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.white,
              ),
              child: Text('Update Profile'),
            ),

            SizedBox(height: 20),

            // Email section
            Form(
              key: _emailFormKey,
              child: TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email (for verification)',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.amber[800]!),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.grey[700]),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => email = value!,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handlePasswordResetRedirect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              child: Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  // Handle only the password reset email form
  void _handlePasswordResetRedirect() {
    if (_emailFormKey.currentState!.validate()) {
      _emailFormKey.currentState!.save();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordResetScreen(email: email),
        ),
      );
    }
  }

  // Handle only the username update form
  Future<void> _updateUsername() async {
    if (_usernameFormKey.currentState!.validate()) {
      _usernameFormKey.currentState!.save();
      try {
        String? accessToken = await Auth.getAccessToken();

        final url = Uri.parse('${Util.BACKEND_URL}/api/v1/change-username');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
          body: jsonEncode({'userId': username, 'newUsername': new_user}),
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Success!'),
              content: Text('Username changed to $new_user'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          ).then((_) => Navigator.pop(context, true));
        } else {
          final responseData = jsonDecode(response.body);
          final errorText = responseData['error'] ??
              'Username is unavailable. Please try again.';

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Update Failed'),
              content: Text(errorText),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (error) {
        print('Error: $error');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while updating the username.'),
          ),
        );
      }
    }
  }
}