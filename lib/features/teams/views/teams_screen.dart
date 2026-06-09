import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/storage/hive_registry.dart';
import '../controllers/team_notifier.dart';
import 'team_detail_screen.dart';
import 'join_team_screen.dart';

const _teamEmojis = ['🏏', '🦁', '🐯', '🦅', '⚡', '👑', '🔥', '🐺', '⚔️', '🛡️', '🦈', '🦖'];
const _tournamentEmojis = ['🏆', '🏅', '🎖️', '👑', '🏏', '🌟', '💥', '🔥', '🎯', '🚩'];

String getCleanName(String name) {
  final emojis = [..._teamEmojis, ..._tournamentEmojis];
  for (final emoji in emojis) {
    if (name.startsWith('$emoji ')) {
      return name.substring(emoji.length + 1);
    }
    if (name.startsWith(emoji)) {
      return name.substring(emoji.length);
    }
  }
  return name;
}

Widget _buildTeamLogo(String name, String teamId, {double size = 44, double fontSize = 18}) {
  final cleanName = getCleanName(name);
  final box = Hive.box(HiveRegistry.teamLogosBoxName);
  final logoBase64 = box.get(teamId) as String?;

  if (logoBase64 != null && logoBase64.isNotEmpty) {
    try {
      final bytes = base64Decode(logoBase64);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryYellow, width: 1.5),
          color: AppColors.black,
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLetterFallback(cleanName, size, fontSize),
        ),
      );
    } catch (_) {
      return _buildLetterFallback(cleanName, size, fontSize);
    }
  }
  return _buildLetterFallback(cleanName, size, fontSize);
}

Widget _buildLetterFallback(String cleanName, double size, double fontSize) {
  final letter = cleanName.trim().isNotEmpty ? cleanName.trim()[0].toUpperCase() : '?';
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.black,
      border: Border.all(color: AppColors.white, width: 1.5),
    ),
    child: Text(
      letter,
      style: TextStyle(
        color: AppColors.primaryYellow,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        fontFamily: 'Rajdhani',
      ),
    ),
  );
}

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final _teamNameController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  void _showCreateTeamSheet() {
    _teamNameController.clear();
    String? selectedLogoBase64;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.primaryYellow, width: 2),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final name = _teamNameController.text.trim();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 28, color: AppColors.primaryYellow),
                      const SizedBox(width: 10),
                      Text(
                        'CREATE TEAM',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TEAM NAME',
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.white, width: 1.5),
                      ),
                    ),
                    child: TextField(
                      controller: _teamNameController,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontFamily: 'DM Sans',
                      ),
                      onChanged: (val) => setModal(() {}),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Chennai Super Kings',
                        hintStyle: TextStyle(
                          color: Color(0xFF888888),
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LOGO PREVIEW',
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryYellow, width: 2),
                          color: AppColors.black,
                        ),
                        child: selectedLogoBase64 != null
                            ? Image.memory(
                                base64Decode(selectedLogoBase64!),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColors.primaryYellow,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Rajdhani',
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: AppColors.black,
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 400,
                                maxHeight: 400,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setModal(() {
                                  selectedLogoBase64 = base64Encode(bytes);
                                });
                              }
                            },
                            child: const Text('PICK IMAGE  📸'),
                          ),
                          if (selectedLogoBase64 != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setModal(() {
                                  selectedLogoBase64 = null;
                                });
                              },
                              child: const Text(
                                'REMOVE IMAGE',
                                style: TextStyle(color: AppColors.red),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _teamNameController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx);
                      final team = await ref
                          .read(teamNotifierProvider.notifier)
                          .createTeam(name);
                      if (team != null) {
                        if (selectedLogoBase64 != null) {
                          final box = Hive.box(HiveRegistry.teamLogosBoxName);
                          await box.put(team.id, selectedLogoBase64);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Team "${getCleanName(team.name)}" created!'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('CREATE TEAM  →'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _confirmDeleteTeam(dynamic team) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.primaryYellow, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: AppColors.red),
              const SizedBox(width: 10),
              Text(
                'DELETE TEAM',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.red),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the team "${team.name}"? This will permanently delete all records of this team.',
            style: const TextStyle(
              color: AppColors.white,
              fontFamily: 'DM Sans',
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 1.5),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.black, width: 1.5),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref
                    .read(teamNotifierProvider.notifier)
                    .deleteTeam(team.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Team deleted successfully.'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(width: 4, height: 28, color: AppColors.primaryYellow),
            const SizedBox(width: 10),
            Text(
              'MY TEAMS',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    letterSpacing: 2.5,
                    color: AppColors.primaryYellow,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login, color: AppColors.primaryYellow),
            tooltip: 'Join Team',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinTeamScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () =>
                ref.read(teamNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: teamsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading teams: $e',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_add,
                      size: 64,
                      color: AppColors.primaryYellow,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NO TEAMS YET',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a team or join one\nusing an invite code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _showCreateTeamSheet,
                          child: const Text('CREATE'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const JoinTeamScreen()),
                            );
                          },
                          child: const Text('JOIN'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildTeamCard(team);
            },
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'teams_fab',
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.primaryYellow, width: 2.5),
          ),
          backgroundColor: AppColors.black,
          onPressed: _showCreateTeamSheet,
          child: const Icon(Icons.add, color: AppColors.primaryYellow, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTeamCard(team) {
    final isOwner =
        team.ownerId == Supabase.instance.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDetailScreen(teamId: team.id),
            ),
          ).then((_) =>
              ref.read(teamNotifierProvider.notifier).refresh());
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            border: Border.all(color: AppColors.black, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header strip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield,
                            color: AppColors.primaryYellow, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isOwner ? 'CAPTAIN' : 'PLAYER',
                          style: const TextStyle(
                            color: AppColors.primaryYellow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                            letterSpacing: 1,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _confirmDeleteTeam(team),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Icon(Icons.delete, color: AppColors.red, size: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: AppColors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${team.members.length}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTeamLogo(team.name, team.id),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getCleanName(team.name).toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'INVITE CODE: ',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 11,
                            fontFamily: 'DM Sans',
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          color: AppColors.primaryYellow,
                          child: Text(
                            team.inviteCode,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: team.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invite code copied!'),
                                backgroundColor: AppColors.primaryGreen,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy,
                              color: AppColors.primaryYellow, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Footer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: const Color(0xFF0D4A00),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'TAP TO VIEW TEAM →',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
