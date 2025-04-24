import 'package:flutter/material.dart';
import 'package:frontend/util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/auth.dart';
import 'dart:io';

class PasswordResetScreen extends StatefulWidget {
  final String email;
  const PasswordResetScreen({super.key, required this.email});

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  String newPassword = "";
  String confirmPassword = "";
  String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Reset password for ${widget.email}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => newPassword = val,
                validator: (val) => val == null 
                    ? 'Enter a new password'
                    : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => confirmPassword = val,
                validator: (val) => val != newPassword ? 'Passwords do not match' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                ),
                child: Text("Reset Password"),
              ),
              if (message != null) ...[
                SizedBox(height: 10),
                Text(message!, style: TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReset() async {
    if (_formKey.currentState!.validate()) {
      try {
        final url = Uri.parse('${Util.BACKEND_URL}/api/v1/reset-password');
        String? accessToken = await Auth.getAccessToken();

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
          body: jsonEncode({
            'email': widget.email,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          }),
        );

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200) {
          setState(() => message = "Password reset successful!");
          await Future.delayed(Duration(seconds: 2));
        
          // Redirect to login screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,  // removes all previous routes
          );
        } else {
          setState(() => message = responseData['error'] ?? "Something went wrong");
        }
      } catch (err) {
        setState(() => message = "Error: $err");
      }
    }
  }
}