import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:the_stat/core/storage/hive_registry.dart';
import 'package:the_stat/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_stat/features/auth/controllers/auth_notifier.dart';
import 'package:the_stat/features/profile/controllers/profile_notifier.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockProfileNotifier extends StateNotifier<ProfileState> implements ProfileNotifier {
  MockProfileNotifier() : super(ProfileState(
    isFetched: true,
    isLoading: false,
    profile: const {'username': 'testuser', 'role': 'batter'},
  ));

  @override
  SupabaseClient get _supabase => throw UnimplementedError();

  @override
  Future<void> loadProfile() async {}

  @override
  Future<bool> createProfile({
    required String username,
    required String role,
    required String position,
    String? battingHand,
    String? bowlingHand,
    String? bowlingType,
  }) async => true;

  @override
  void clearProfile() {}
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    final tempDir = await Directory.systemTemp.createTemp('the_stat_widget_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveRegistry.matchesBoxName);

    try {
      await Supabase.initialize(
        url: 'https://atutqoiqvcojambboakw.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dXRxb2lxdmNvamFtYmJvYWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4ODg5ODAsImV4cCI6MjA5NjQ2NDk4MH0.VPKxrbqOTF6yVe2ep5vXtKGjzPEYB1C4Nappl8pU7lo',
      );
    } catch (_) {}
  });

  testWidgets('App mounts and shows dashboard text', (WidgetTester tester) async {
    final mockUser = User(
      id: 'test-id',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(mockUser)),
          profileNotifierProvider.overrideWith((ref) => MockProfileNotifier()),
        ],
        child: const TheStatApp(),
      ),
    );

    // Wait for the stream to emit the user and the page to rebuild
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Dashboard screen title matches brand text
    expect(find.text('THE STAT'), findsOneWidget);
    expect(find.text('TAMIL NADU LOCAL SCORING'), findsOneWidget);
  });
}

