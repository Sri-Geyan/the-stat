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
      if (kIsWeb) {
        // On Web, use Supabase OAuth redirect flow.
        // The google_sign_in package does NOT work on web.
        final success = await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.origin : null,
        );
        // signInWithOAuth returns true if the redirect was initiated
        // The actual auth state change happens after the redirect back
        return success;
      } else {
        // On native platforms (Android/iOS), use google_sign_in package
        return await _signInWithGoogleNative();
      }
    } catch (e) {
      debugPrint('Google sign in failed: $e');
      return false;
    }
  }

  Future<bool> _signInWithGoogleNative() async {
    /// Web Client ID that you registered with Google Cloud.
    const webClientId = '747993395265-aq86obflphurvvgcfdqb5cr78muu7585.apps.googleusercontent.com';

    /// iOS Client ID that you registered with Google Cloud.
    const iosClientId = '747993395265-6shh7fh6iooeu6n4qeh8fc0cf7ui6n48.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in flow
      debugPrint('Google sign in cancelled by user');
      return false;
    }
    
    final googleAuth = await googleUser.authentication;
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
  }

  Future<bool> signInAnonymously() async {
    try {
      debugPrint('Attempting anonymous sign in...');
      final response = await _supabase.auth.signInAnonymously();
      debugPrint('Anonymous sign in response - user: ${response.user?.id}');
      if (response.user == null) {
        debugPrint('Anonymous sign in returned null user. '
            'Make sure "Allow anonymous sign-ins" is enabled in '
            'Supabase Dashboard > Authentication > Providers > Anonymous.');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Anonymous sign in failed: $e');
      debugPrint('HINT: Enable anonymous sign-ins in Supabase Dashboard > '
          'Authentication > Providers > Anonymous sign-ins.');
      return false;
    }
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
