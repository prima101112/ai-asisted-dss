import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'ui/screens/chat_screen.dart';

void main() async {
  // 1. Ensure bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("--- Init Started ---");

  // 2. Start the app IMMEDIATELY to avoid iOS startup watchdog timeouts
  runApp(const ProviderScope(child: MyApp()));

  // 3. Initialize services asynchronously in the background
  _initializeServices();
}

Future<void> _initializeServices() async {
  // 1. Load .env
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("--- Dotenv Loaded ---");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load: $e");
  }

  // 2. Initialize Firebase (Safely)
  // Re-enabled for all platforms as GoogleService-Info.plist is now provided
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      debugPrint("--- Firebase Initialized ---");
    }
  } catch (e) {
    debugPrint("Firebase initialization failure: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Assisted DSS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF03A9F4), // Light Blue
          secondary: const Color(0xFFFFB74D), // Light Orange
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF03A9F4),
          secondary: const Color(0xFFFFB74D),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}
