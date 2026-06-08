import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../controllers/team_notifier.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinTeam() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    final success =
        await ref.read(teamNotifierProvider.notifier).joinTeamByCode(code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined team!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid invite code. Please try again.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'JOIN TEAM',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                letterSpacing: 2.5,
                color: AppColors.primaryYellow,
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // Illustration
            const Icon(
              Icons.group_add,
              size: 80,
              color: AppColors.primaryYellow,
            ),
            const SizedBox(height: 24),
            Text(
              'ENTER INVITE CODE',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your team captain for\nthe 6-character invite code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontFamily: 'DM Sans',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Code input
            Container(
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border.all(color: AppColors.primaryYellow, width: 2),
              ),
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                  color: AppColors.primaryYellow,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rajdhani',
                    letterSpacing: 8,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryYellow),
              )
            else
              ElevatedButton(
                onPressed: _joinTeam,
                child: const Text('JOIN TEAM  →'),
              ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
