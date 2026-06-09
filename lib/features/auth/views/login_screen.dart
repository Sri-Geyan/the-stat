import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../controllers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(authNotifierProvider).signInWithGoogle();
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign in. Please try again.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authNotifierProvider).signInAnonymously();
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign in as guest. Please try again.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // App Logo / Title
              Text(
                'THE\nSTAT',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.primaryYellow,
                  height: 0.9,
                  letterSpacing: -2,
                  shadows: [
                    const Shadow(
                      color: AppColors.black,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'YOUR MATCHES.\nYOUR STATS.\nYOUR LEGACY.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),

              // Sign in Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.black,
                  border: Border.all(color: AppColors.primaryYellow, width: 2),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'AUTHENTICATION REQUIRED',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryYellow,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryYellow),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Required by brand spec
                                  side: const BorderSide(color: AppColors.black, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Simple placeholder icon for Google
                                const Icon(Icons.g_mobiledata, size: 32, color: AppColors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'SIGN IN WITH GOOGLE',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            key: const Key('guest_bypass_btn'),
                            onPressed: _handleAnonymousSignIn,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryYellow,
                              side: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_outline, size: 20, color: AppColors.primaryYellow),
                                const SizedBox(width: 8),
                                Text(
                                  'CONTINUE AS GUEST',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.primaryYellow,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
