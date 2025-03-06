import 'package:flutter/material.dart';
import 'package:frontend/login.dart';
import 'package:frontend/register.dart';
import 'package:frontend/mapscreen.dart';
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
      initialRoute: '/login',
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => MapScreen(),
        '/profile': (context) => ProfileScreen(),
      },
      //home: LoginScreen(),
      //home: MapScreen(),
    );
  }
}
