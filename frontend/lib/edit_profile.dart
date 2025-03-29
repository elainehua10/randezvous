import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/auth.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String firstName = "First";
  String lastName = "Last";
  String username = "username";
  String new_user = "";
  String? errorMessage;

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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
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
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Please enter a username.",
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 14,
                              )
                            )
                          )
                        ]
                      )
                    );
                    return 'Please enter a username';
                  }
                  return null;
                },
                onSaved: (value) => new_user = value!,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest(
        "get-user-profile-info",
        {},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          firstName = data['first_name'] ?? 'First';
          lastName = data['last_name'] ?? 'Last';
          username = data['username'] ?? 'username';
        });
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  Future<void> _updateUsername() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        String? accessToken = await Auth.getAccessToken();

        final url = Uri.parse('http://localhost:5001/api/v1/change-username');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
          body: jsonEncode({'userId': username, 'newUsername': new_user}),
        );
        if (response.statusCode == 200) {
          print('Username updated successfully');
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Success!'),
                  content: Text('Username changed to $new_user'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
          ).then((_) {
            Navigator.pop(context, true);
          });
        } else {
          print('Failed to update username: ${response.body}');
          final responseData = jsonDecode(response.body);
          int error = 0;
          if (responseData['error'] ==
              "The new username must be different from the current one") {
            error = 1;
          }
          if (error == 1) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Update Failed'),
                    content: Text(
                      'The new username must be different from the current one. Please try again.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
            );
          } else {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Update Failed'),
                    content: Text('Username is unavailable. Please try again.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
            );
          }
        }
      } catch (error) {
        print('Error: $error');
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Error'),
                content: Text('An error occurred while updating the username.'),
              ),
        );
      }
    }
  }
}

