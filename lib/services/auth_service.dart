import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Google Sign-In authentication
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // iOS Client ID from Google Cloud Console
  static const String _iosClientId = 
      '366050694634-1cc1s5tt375mmguslj6l2r33kn1e0if1.apps.googleusercontent.com';
  
  late final GoogleSignIn _googleSignIn;
  
  AuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      // For iOS, use the iOS OAuth client ID
      clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,
    );
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web platform
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // Mobile platforms (Android/iOS)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // User cancelled the sign-in
          debugPrint('Google Sign-In: User cancelled');
          return null;
        }

        debugPrint('Google Sign-In: Got user ${googleUser.email}');
        
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        debugPrint('Google Sign-In: Got auth tokens');
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _firebaseAuth.signInWithCredential(credential);
      }
    } catch (e, stackTrace) {
      debugPrint('Error signing in with Google: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
