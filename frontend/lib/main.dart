import 'package:flutter/material.dart';
import 'package:frontend/group_screen.dart';
import 'package:frontend/login.dart';
import 'package:frontend/register.dart';
import 'package:frontend/map_screen.dart';
import 'package:frontend/profile.dart';
import 'package:frontend/edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Ensure widgets are initialized before using Supabase
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
        '/edit-profile': (context) => EditProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/group') {
          final args = settings.arguments as Map<String, dynamic>?;
          final groupId = args?['groupId'] ?? ''; // Default to empty if null

          return MaterialPageRoute(
            builder: (context) => GroupScreen(groupId: groupId),
          );
        }
        return null; // Fallback if the route is not found
      },
      //home: LoginScreen(),
      //home: MapScreen(),
    );
  }
}
