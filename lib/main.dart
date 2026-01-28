import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/login_screen.dart';

void main() async {
  // 1. Ensure bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("--- Init Started ---");

  // 2. Load .env (non-blocking, can fail silently)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("--- Dotenv Loaded ---");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load: $e");
  }

  // 3. Initialize Firebase BEFORE running app (required for auth)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("--- Firebase Initialized ---");
    }
  } catch (e) {
    debugPrint("Firebase initialization failure: $e");
  }

  // 4. Start the app after Firebase is ready
  runApp(const ProviderScope(child: MyApp()));
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
      home: const AuthWrapper(),
    );
  }
}

/// Widget that handles authentication state and navigation
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, show main app
          return const ChatScreen();
        } else {
          // User is not authenticated, show login
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(authStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
