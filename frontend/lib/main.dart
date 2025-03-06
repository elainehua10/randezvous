import 'package:flutter/material.dart';
import 'package:frontend/group_screen.dart';
import 'package:frontend/login.dart';
import 'package:frontend/register.dart';
import 'package:frontend/map_screen.dart';
import 'package:frontend/profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RandezVous',
      theme: ThemeData(primarySwatch: Colors.yellow),
      initialRoute: '/register',
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => MapScreen(),
        '/group': (context) => GroupScreen(groupId: ''),
        '/profile': (context) => ProfileScreen(),
      },
      //home: LoginScreen(),
      //home: MapScreen(),
    );
  }
}
