import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

// Provides the current authenticated user (or null if not logged in)
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) => event.session?.user);
});

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier();
});

class AuthNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> signInWithGoogle() async {
    try {
      /// TODO: update the Web client ID with your own.
      ///
      /// Web Client ID that you registered with Google Cloud.
      const webClientId = '747993395265-aq86obflphurvvgcfdqb5cr78muu7585.apps.googleusercontent.com';

      /// TODO: update the iOS client ID with your own.
      ///
      /// iOS Client ID that you registered with Google Cloud.
      const iosClientId = '747993395265-6shh7fh6iooeu6n4qeh8fc0cf7ui6n48.apps.googleusercontent.com';

      // Google sign in on Android will work without providing the Android
      // Client ID registered on Google Cloud.

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      return true;
    } catch (e) {
      debugPrint('Google sign in failed: $e');
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      await _supabase.auth.signInAnonymously();
      return true;
    } catch (e) {
      debugPrint('Anonymous sign in failed: $e');
      return false;
    }
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
