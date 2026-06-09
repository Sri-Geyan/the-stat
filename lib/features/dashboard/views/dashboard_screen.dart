import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../scoring/controllers/scoring_notifier.dart';
import '../../scoring/models/match_state.dart';
import '../../../core/storage/hive_registry.dart';
import '../../scoring/views/scoring_screen.dart';
import '../../scorecard/views/scorecard_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../teams/models/team_model.dart';
import '../../teams/controllers/team_notifier.dart';
import '../../scoring/views/select_squads_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TeamModel? _selectedTeamA;
  TeamModel? _selectedTeamB;
  String _format = 'T20';
  int _overs = 20;
  String _tossWinner = 'teamA';
  String _tossChoice = 'bat';

  @override
  void dispose() {
    super.dispose();
  }

  void _showNewMatchWizard(BuildContext context) {
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
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 28,
                          color: AppColors.primaryYellow,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'START NEW MATCH',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('TEAMS'),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final teamsAsync = ref.watch(allTeamsProvider);
                        return teamsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(color: AppColors.primaryYellow),
                            ),
                          ),
                          error: (err, _) => Text(
                            'Error loading teams: $err',
                            style: const TextStyle(color: AppColors.red, fontSize: 12),
                          ),
                          data: (teams) {
                            if (teams.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'NO REGISTERED TEAMS. PLEASE CREATE TEAMS FIRST.',
                                  style: TextStyle(color: AppColors.primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTeamDropdown(
                                  label: 'TEAM A (HOME)',
                                  value: _selectedTeamA,
                                  items: teams,
                                  onChanged: (val) {
                                    setModalState(() {
                                      _selectedTeamA = val;
                                      if (_selectedTeamB?.id == val?.id) {
                                        _selectedTeamB = null;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildTeamDropdown(
                                  label: 'TEAM B (AWAY / OPPONENT)',
                                  value: _selectedTeamB,
                                  items: teams.where((t) => t.id != _selectedTeamA?.id).toList(),
                                  onChanged: (val) {
                                    setModalState(() {
                                      _selectedTeamB = val;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionLabel('FORMAT'),
                              const SizedBox(height: 8),
                              _buildDropdown<String>(
                                value: _format,
                                items: const ['Gully T5', 'Gully T8', 'Box Cricket T6', 'Corporate T10', 'T15', 'T20', 'ODI'],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      _format = val;
                                      if (val == 'Gully T5') {
                                        _overs = 5;
                                      } else if (val == 'Gully T8') {
                                        _overs = 8;
                                      } else if (val == 'Box Cricket T6') {
                                        _overs = 6;
                                      } else if (val == 'Corporate T10') {
                                        _overs = 10;
                                      } else if (val == 'T15') {
                                        _overs = 15;
                                      } else if (val == 'T20') {
                                        _overs = 20;
                                      } else {
                                        _overs = 50;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionLabel('OVERS'),
                              const SizedBox(height: 8),
                              _buildDropdown<int>(
                                value: _overs,
                                items: const [5, 6, 8, 10, 15, 20, 50],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => _overs = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('TOSS'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceButton(
                            label: 'TEAM A WINS',
                            selected: _tossWinner == 'teamA',
                            onTap: () => setModalState(() => _tossWinner = 'teamA'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildChoiceButton(
                            label: 'TEAM B WINS',
                            selected: _tossWinner == 'teamB',
                            onTap: () => setModalState(() => _tossWinner = 'teamB'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceButton(
                            label: '🏏 BAT FIRST',
                            selected: _tossChoice == 'bat',
                            onTap: () => setModalState(() => _tossChoice = 'bat'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildChoiceButton(
                            label: '⚾ BOWL FIRST',
                            selected: _tossChoice == 'bowl',
                            onTap: () => setModalState(() => _tossChoice = 'bowl'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedTeamA == null || _selectedTeamB == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select both Home and Away teams.'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectSquadsScreen(
                              teamA: _selectedTeamA!,
                              teamB: _selectedTeamB!,
                              format: _format,
                              overs: _overs,
                              tossWinner: _tossWinner,
                              tossChoice: _tossChoice,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: const Text("CHOOSE SQUADS  →"),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryYellow,
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTeamDropdown({
    required String label,
    required TeamModel? value,
    required List<TeamModel> items,
    required ValueChanged<TeamModel?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: AppColors.black,
            border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TeamModel>(
              value: value,
              dropdownColor: AppColors.black,
              iconEnabledColor: AppColors.primaryYellow,
              isExpanded: true,
              hint: const Text(
                'Select Registered Team',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontFamily: 'DM Sans'),
              ),
              style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
              items: items.map((team) {
                return DropdownMenuItem<TeamModel>(
                  value: team,
                  child: Text(team.name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF888888), fontFamily: 'DM Sans', fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.black,
          iconEnabledColor: AppColors.primaryYellow,
          isExpanded: true,
          style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryYellow : AppColors.black,
          border: Border.all(
            color: selected ? AppColors.primaryYellow : AppColors.white,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.black : AppColors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    final photoUrl = user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture'];
    final name = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        'P';

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryYellow, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.black,
                  alignment: Alignment.center,
                  child: Text(
                    name.toString()[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryYellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ),
              )
            : Container(
                color: AppColors.black,
                alignment: Alignment.center,
                child: Text(
                  name.toString()[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ),
      ),
    );
  }

  void _confirmDeleteMatch(MatchState match) {
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
                'DELETE MATCH',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.red),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the match between ${match.teamAName} and ${match.teamBName}? This will permanently delete all records of this match.',
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
                await HiveRegistry.deleteMatch(match.id);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Match deleted successfully.'),
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
    final matches = HiveRegistry.getAllMatches();
    final liveMatches = matches.where((m) => m.status == 'live').toList();
    final completedMatches = matches.where((m) => m.status == 'completed').toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'THE STAT',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    letterSpacing: 2.5,
                    color: AppColors.primaryYellow,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                border: Border.all(color: AppColors.black, width: 1),
              ),
              child: const Text(
                'β',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: _buildProfileAvatar(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero stat banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border.all(color: AppColors.primaryYellow, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'TAMIL NADU LOCAL SCORING',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatPill('${matches.length}', 'MATCHES', AppColors.white),
                      Container(width: 1, height: 40, color: AppColors.primaryYellow),
                      _buildStatPill('${liveMatches.length}', 'LIVE', AppColors.red),
                      Container(width: 1, height: 40, color: AppColors.primaryYellow),
                      _buildStatPill('${completedMatches.length}', 'COMPLETED', AppColors.primaryYellow),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live matches
            _buildSectionHeader('🔴 LIVE MATCHES', liveMatches.length),
            const SizedBox(height: 10),
            if (liveMatches.isEmpty)
              _buildEmptyCard('No live matches.\nTap + to start scoring now!')
            else
              ...liveMatches.map((m) => _buildMatchCard(m, isLive: true)),

            const SizedBox(height: 24),

            // Completed matches
            _buildSectionHeader('✅ COMPLETED MATCHES', completedMatches.length),
            const SizedBox(height: 10),
            if (completedMatches.isEmpty)
              _buildEmptyCard('No completed matches recorded yet.')
            else
              ...completedMatches.map((m) => _buildMatchCard(m, isLive: false)),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'dashboard_fab',
          shape: const CircleBorder(side: BorderSide(color: AppColors.primaryYellow, width: 2.5)),
          backgroundColor: AppColors.black,
          onPressed: () => _showNewMatchWizard(context),
          child: const Icon(Icons.add, color: AppColors.primaryYellow, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: AppColors.primaryYellow),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: AppColors.primaryYellow,
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            fontFamily: 'Rajdhani',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2A8A00), width: 1),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontFamily: 'DM Sans',
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchState match, {required bool isLive}) {
    final runs1 = match.innings1Runs;
    final wickets1 = match.innings1Wickets;
    final balls1 = match.innings1Balls;
    final overs1 = '${balls1 ~/ 6}.${balls1 % 6}';
    final runs2 = match.currentRuns;
    final wickets2 = match.currentWickets;
    final overs2 = match.currentOvers;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (isLive) {
            ref.read(scoringProvider.notifier).loadMatch(match.id);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScoringScreen()),
            ).then((_) => setState(() {}));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ScorecardScreen(match: match)),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            border: Border.all(
              color: isLive ? AppColors.red : AppColors.black,
              width: isLive ? 2 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Match header strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isLive ? AppColors.red : AppColors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          match.format.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _confirmDeleteMatch(match),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.delete, color: AppColors.red, size: 16),
                          ),
                        ),
                      ],
                    ),
                    if (isLive)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                  ],
                ),
              ),
              // Match body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${match.teamAName}  vs  ${match.teamBName}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    if (match.currentInnings == 1)
                      _buildInningsRow('1st INN', '$runs2/$wickets2', overs2, highlight: true)
                    else ...[
                      _buildInningsRow('1st INN', '$runs1/$wickets1', overs1, highlight: false),
                      const SizedBox(height: 6),
                      _buildInningsRow('2nd INN', '$runs2/$wickets2', overs2, highlight: true),
                    ],
                    if (match.status == 'completed') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: AppColors.primaryYellow,
                        child: Text(
                          '${match.winner.toUpperCase()} WON BY ${match.margin.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Tap hint footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: const Color(0xFF0D4A00),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isLive ? 'TAP TO CONTINUE SCORING →' : 'TAP TO VIEW SCORECARD →',
                      style: const TextStyle(
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

  Widget _buildInningsRow(String label, String score, String overs, {required bool highlight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? AppColors.primaryYellow : const Color(0xFFAAAAAA),
            fontSize: 12,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '$score  ($overs ov)',
          style: TextStyle(
            color: highlight ? AppColors.primaryYellow : AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Rajdhani',
          ),
        ),
      ],
    );
  }
}
