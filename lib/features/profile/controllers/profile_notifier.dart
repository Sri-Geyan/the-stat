import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileState {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final String? error;
  final bool isFetched;

  ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
    this.isFetched = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    Map<String, dynamic>? profile,
    String? error,
    bool? isFetched,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error ?? this.error,
      isFetched: isFetched ?? this.isFetched,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  ProfileNotifier() : super(ProfileState()) {
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        loadProfile();
      } else {
        state = ProfileState();
      }
    });
    // Load profile initially if user is already logged in
    if (_supabase.auth.currentUser != null) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = ProfileState(isFetched: true);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      state = ProfileState(profile: res, isFetched: true);
    } catch (e) {
      state = ProfileState(error: e.toString(), isFetched: true);
    }
  }

  Future<bool> createProfile({
    required String username,
    required String role,
    required String position,
    String? battingHand,
    String? bowlingHand,
    String? bowlingType,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final data = {
        'id': user.id,
        'username': username,
        'role': role,
        'position': position,
        'batting_hand': battingHand,
        'bowling_hand': bowlingHand,
        'bowling_type': bowlingType,
      };

      await _supabase.from('profiles').upsert(data);
      await loadProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearProfile() {
    state = ProfileState(isFetched: true);
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

final allProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await Supabase.instance.client.from('profiles').select();
    return List<Map<String, dynamic>>.from(res);
  } catch (e) {
    debugPrint('Error loading profiles: $e');
    return [];
  }
});
