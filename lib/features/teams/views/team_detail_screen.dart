import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../controllers/team_notifier.dart';
import '../models/team_model.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  TeamModel? _team;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  void _loadTeam() {
    final teams = ref.read(teamNotifierProvider).valueOrNull ?? [];
    final match = teams.where((t) => t.id == widget.teamId);
    if (match.isNotEmpty) {
      setState(() {
        _team = match.first;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _shareInvite() {
    if (_team == null) return;
    final message =
        '🏏 Join my team "${_team!.name}" on The Stat!\n\nUse invite code: ${_team!.inviteCode}\n\nDownload the app and enter the code in Teams → Join Team.';
    Share.share(message, subject: 'Join ${_team!.name} on The Stat');
  }

  void _copyCode() {
    if (_team == null) return;
    Clipboard.setData(ClipboardData(text: _team!.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied to clipboard!'),
        backgroundColor: AppColors.primaryGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _removeMember(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text(
          'REMOVE PLAYER',
          style: TextStyle(
            color: AppColors.primaryYellow,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove ${member.userName} from the team?',
          style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('REMOVE',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(teamNotifierProvider.notifier)
          .removePlayer(widget.teamId, member.userId);
      if (success && mounted) {
        // Reload team data
        final teams = ref.read(teamNotifierProvider).valueOrNull ?? [];
        final match = teams.where((t) => t.id == widget.teamId);
        if (match.isNotEmpty) {
          setState(() => _team = match.first);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for updates from the notifier
    ref.listen(teamNotifierProvider, (prev, next) {
      final teams = next.valueOrNull ?? [];
      final match = teams.where((t) => t.id == widget.teamId);
      if (match.isNotEmpty) {
        setState(() => _team = match.first);
      }
    });

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      );
    }

    if (_team == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Team not found',
              style: TextStyle(color: AppColors.white)),
        ),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = _team!.ownerId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _team!.name.toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                letterSpacing: 2.5,
                color: AppColors.primaryYellow,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Invite Code Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border.all(color: AppColors.primaryYellow, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'INVITE CODE',
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    color: AppColors.primaryYellow,
                    child: Text(
                      _team!.inviteCode,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareInvite,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('SHARE INVITE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyCode,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('COPY CODE'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Members section header
            Row(
              children: [
                Container(
                    width: 4, height: 22, color: AppColors.primaryYellow),
                const SizedBox(width: 10),
                Text(
                  'SQUAD',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: AppColors.primaryYellow,
                  child: Text(
                    '${_team!.members.length}',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Members list
            ..._team!.members.map((member) => _buildMemberTile(
                  member,
                  isOwner: isOwner,
                  isCurrentUser: member.userId == currentUserId,
                )),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(TeamMember member,
      {required bool isOwner, required bool isCurrentUser}) {
    final initials = member.userName.isNotEmpty
        ? member.userName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          border: Border.all(color: AppColors.black, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: member.role == 'owner'
                      ? AppColors.primaryYellow
                      : AppColors.black,
                  border:
                      Border.all(color: AppColors.primaryYellow, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: member.role == 'owner'
                        ? AppColors.black
                        : AppColors.primaryYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.userName.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DM Sans',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.role == 'owner') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            color: AppColors.primaryYellow,
                            child: const Text(
                              'CAPTAIN',
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.userEmail,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 11,
                        fontFamily: 'DM Sans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Remove button (owner only, not self)
              if (isOwner && !isCurrentUser && member.role != 'owner')
                IconButton(
                  icon: const Icon(Icons.person_remove,
                      color: AppColors.red, size: 20),
                  onPressed: () => _removeMember(member),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
