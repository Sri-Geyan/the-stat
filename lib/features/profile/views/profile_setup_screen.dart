import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../controllers/profile_notifier.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String _selectedRole = 'batter';
  String _selectedPosition = 'Top Order';
  String _selectedBattingHand = 'Right-Hand';
  String _selectedBowlingHand = 'Right-Arm';
  String _selectedBowlingType = 'Medium Fast';

  bool _isSaving = false;

  final List<String> _roles = [
    'batter',
    'bowler',
    'wicketkeeper',
    'bowling all rounder',
    'batting all rounder',
    'proper all rounder',
  ];

  final List<String> _battingHands = ['Right-Hand', 'Left-Hand'];
  final List<String> _bowlingHands = ['Right-Arm', 'Left-Arm'];
  final List<String> _bowlingTypes = [
    'Fast',
    'Medium Fast',
    'Medium',
    'Orthodox',
    'Wrist Spin',
    'Chinaman',
  ];

  // Helper getters to check conditional visibility
  bool get _needsBatting =>
      _selectedRole == 'batter' ||
      _selectedRole == 'wicketkeeper' ||
      _selectedRole == 'batting all rounder' ||
      _selectedRole == 'proper all rounder';

  bool get _needsBowling =>
      _selectedRole == 'bowler' ||
      _selectedRole == 'bowling all rounder' ||
      _selectedRole == 'proper all rounder';

  List<String> get _availablePositions {
    if (_selectedRole == 'batter' || _selectedRole == 'wicketkeeper' || _selectedRole == 'batting all rounder') {
      return ['Opener', 'Top Order', 'Middle Order', 'Finisher'];
    } else if (_selectedRole == 'bowler' || _selectedRole == 'bowling all rounder') {
      return ['Opening Bowler', 'First Change Bowler', 'Middle Overs Bowler', 'Death Bowler'];
    } else {
      // proper all rounder
      return ['Opener', 'Top Order', 'Middle Order', 'Finisher', 'Opening Bowler', 'Death Bowler', 'All Rounder'];
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedPosition = _availablePositions.first;
  }

  void _onRoleChanged(String? newRole) {
    if (newRole == null) return;
    setState(() {
      _selectedRole = newRole;
      final positions = _availablePositions;
      if (!positions.contains(_selectedPosition)) {
        _selectedPosition = positions.first;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await ref.read(profileNotifierProvider.notifier).createProfile(
          username: _usernameController.text.trim(),
          role: _selectedRole,
          position: _selectedPosition,
          battingHand: _needsBatting ? _selectedBattingHand : null,
          bowlingHand: _needsBowling ? _selectedBowlingHand : null,
          bowlingType: _needsBowling ? _selectedBowlingType : null,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (!success) {
        final error = ref.read(profileNotifierProvider).error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $error'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'SETUP YOUR PROFILE',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryYellow,
                        letterSpacing: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set your player details to begin recording your matches and stats.',
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Card wrapping the form fields
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    border: Border.all(color: AppColors.primaryYellow, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Username field
                      const Text(
                        'USERNAME / DISPLAY NAME',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'DM Sans',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontFamily: 'DM Sans',
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. virat_18',
                          hintStyle: const TextStyle(color: Color(0xFF555555)),
                          filled: true,
                          fillColor: const Color(0xFF151515),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(color: Color(0xFF333333), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Role selection dropdown
                      const Text(
                        'PLAYER ROLE',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'DM Sans',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedRole,
                        items: _roles,
                        onChanged: _onRoleChanged,
                        labelBuilder: (role) => role.replaceAll('_', ' ').toUpperCase(),
                      ),
                      const SizedBox(height: 20),

                      // Position selection dropdown
                      const Text(
                        'PREFERRED POSITION',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'DM Sans',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedPosition,
                        items: _availablePositions,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPosition = val);
                        },
                        labelBuilder: (pos) => pos.toUpperCase(),
                      ),
                      const SizedBox(height: 20),

                      // Conditional Batting Hand field
                      if (_needsBatting) ...[
                        const Text(
                          'BATTING HAND',
                          style: TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdown<String>(
                          value: _selectedBattingHand,
                          items: _battingHands,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBattingHand = val);
                          },
                          labelBuilder: (hand) => hand.toUpperCase(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Conditional Bowling Hand and Type
                      if (_needsBowling) ...[
                        const Text(
                          'BOWLING HAND',
                          style: TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdown<String>(
                          value: _selectedBowlingHand,
                          items: _bowlingHands,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBowlingHand = val);
                          },
                          labelBuilder: (hand) => hand.toUpperCase(),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'BOWLING TYPE',
                          style: TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdown<String>(
                          value: _selectedBowlingType,
                          items: _bowlingTypes,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBowlingType = val);
                          },
                          labelBuilder: (type) => type.toUpperCase(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit button
                if (_isSaving)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: AppColors.primaryYellow),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'SAVE AND CONTINUE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.black,
                          ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(color: const Color(0xFF333333), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.black,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryYellow),
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: 'DM Sans',
            fontSize: 16,
          ),
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
