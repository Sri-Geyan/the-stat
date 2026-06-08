import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/storage/hive_registry.dart';
import 'core/theme.dart';
import 'core/navigation/app_shell.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/controllers/auth_notifier.dart';
import 'features/profile/controllers/profile_notifier.dart';
import 'features/profile/views/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveRegistry.init();

  await Supabase.initialize(
    url: 'https://atutqoiqvcojambboakw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dXRxb2lxdmNvamFtYmJvYWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4ODg5ODAsImV4cCI6MjA5NjQ2NDk4MH0.VPKxrbqOTF6yVe2ep5vXtKGjzPEYB1C4Nappl8pU7lo',
  );

  runApp(
    const ProviderScope(
      child: TheStatApp(),
    ),
  );
}

class TheStatApp extends StatelessWidget {
  const TheStatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Stat',
      theme: AppTheme.themeData,
      home: const AuthGuard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final profileState = ref.watch(profileNotifierProvider);
          if (!profileState.isFetched || profileState.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.primaryGreen,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryYellow),
              ),
            );
          }

          if (profileState.profile == null) {
            return const ProfileSetupScreen();
          }

          return const AppShell();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(
          child: Text(
            'Error loading auth state: $e',
            style: const TextStyle(color: AppColors.primaryYellow),
          ),
        ),
      ),
    );
  }
}
