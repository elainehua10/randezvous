import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/group_screen.dart';
import 'package:frontend/login.dart';
import 'package:frontend/register.dart';
import 'package:frontend/map_screen.dart';
import 'package:frontend/profile.dart';
import 'package:frontend/edit_profile.dart';
import 'package:frontend/settings.dart';
import 'package:frontend/search_screen.dart';
import 'package:frontend/member_profile.dart';
import 'package:frontend/faq_page.dart';
import 'package:frontend/privacy_security_page.dart';
import 'package:frontend/report_issue_page.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/util.dart';
import 'firebase_options.dart';
import '/services/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initNotifications();

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? accessToken = await Auth.getAccessToken();
  runApp(MyApp(initialRoute: accessToken != null ? '/home' : '/login'));
  initBackgroundFetch();
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RandezVous',
      theme: ThemeData(primarySwatch: Colors.yellow),
      initialRoute: initialRoute, // Set the initial route dynamically
      routes: {
        '/search': (context) => SearchScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => MapScreen(),
        '/profile': (context) => ProfileScreen(),
        '/edit-profile': (context) => EditProfileScreen(),
        '/settings': (context) => SettingsPage(),
        '/privacy-security': (context) => PrivacySecurityPage(),
        '/faq': (context) => FAQPage(),
        '/report-issue': (context) => ReportIssuePage(),
        '/member-profile': (context) => MemberProfileScreen(userId: ''),
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
    );
  }
}
