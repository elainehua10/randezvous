import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/map_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Here you can add your code for checking credentials
      print('Login attempt: $email with $password');

      _formKey.currentState!.save();
      try {
        // Make a POST request to the server
        final url = Uri.parse('http://localhost:5001/api/v1/login');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );
        final responseData = jsonDecode(response.body);
        // Handle the response
        if (response.statusCode == 200) {
          print('Login successful');
          String access_token = responseData["session"]["access_token"];
          String refresh_token = responseData["session"]["refresh_token"];
          int expire_time = responseData["session"]["expires_at"];
          Auth.saveTokens(access_token, refresh_token, expire_time);

          // Save tokens to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', access_token);
          await prefs.setString('refresh_token', refresh_token);
          await prefs.setInt('expires_at', expire_time);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print('Login failed: ${response.body}');
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Login Failed'),
                  content: Text('Please check your credentials and try again.'),
                ),
          );
        }
      } catch (error) {
        print('Error: $error');
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Login Failed'),
                content: Text('Failed to connect to server'),
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) => email = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: Icon(Icons.visibility_off),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) => password = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // background color
                  foregroundColor: Colors.white, // text color
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
