import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../controllers/team_notifier.dart';
import 'team_detail_screen.dart';
import 'join_team_screen.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.primaryYellow, width: 2),
      ),
      builder: (ctx) {
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = _teamNameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  final team = await ref
                      .read(teamNotifierProvider.notifier)
                      .createTeam(name);
                  if (team != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Team "${team.name}" created!'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                },
                child: const Text('CREATE TEAM  →'),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
                    Text(
                      team.name.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.white),
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
