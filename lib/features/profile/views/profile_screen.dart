import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/storage/hive_registry.dart';
import '../../auth/controllers/auth_notifier.dart';
import '../../teams/controllers/team_notifier.dart';
import '../../scoring/models/match_state.dart';
import '../controllers/profile_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final teamsAsync = ref.watch(teamNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final allProfilesAsync = ref.watch(allProfilesProvider);

    final userProfile = profileState.profile;
    final displayName = userProfile?['username'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        'Player';
    final email = user?.email ?? '';
    final photoUrl = user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture'];

    // Map profiles for unregistered player lookups (case-insensitive)
    final Map<String, Map<String, dynamic>> profilesCache = {};
    allProfilesAsync.whenData((list) {
      for (final p in list) {
        final username = p['username'] as String?;
        if (username != null) {
          profilesCache[username.toLowerCase()] = p;
        }
        final id = p['id'] as String?;
        if (id != null) {
          profilesCache[id.toLowerCase()] = p;
        }
      }
    });

    // Compute player stats from all matches
    final matches = HiveRegistry.getAllMatches();
    final playerName = displayName.toString();
    final batting = _computePlayerBatting(matches, playerName);
    final bowling = _computePlayerBowling(matches, playerName);

    // Compute player analysis for strengths & weaknesses
    final analysis = _analyzePlayerPerformance(matches, playerName, profilesCache);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFILE',
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
            // Profile card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border.all(color: AppColors.primaryYellow, width: 2),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryYellow, width: 3),
                    ),
                    child: ClipOval(
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFallbackAvatar(playerName),
                            )
                          : _buildFallbackAvatar(playerName),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    playerName.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryYellow,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (userProfile != null) ...[
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFF333333)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildProfileInfoTag('ROLE', userProfile['role'].toString().toUpperCase()),
                        _buildProfileInfoTag('POSITION', userProfile['position'].toString().toUpperCase()),
                        if (userProfile['batting_hand'] != null)
                          _buildProfileInfoTag('BAT HAND', userProfile['batting_hand'].toString().toUpperCase()),
                        if (userProfile['bowling_hand'] != null || userProfile['bowling_type'] != null)
                          _buildProfileInfoTag(
                            'BOWL TYPE',
                            '${userProfile['bowling_hand'] ?? ""} ${userProfile['bowling_type'] ?? ""}'.trim().toUpperCase(),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── AI PERFORMANCE ANALYSIS ──
            _buildSectionHeader(context, '📊 PERFORMANCE ANALYSIS'),
            const SizedBox(height: 12),
            _buildAnalysisSection(context, analysis, userProfile?['role']),
            const SizedBox(height: 24),

            // ── BATTING STATS ──
            _buildSectionHeader(context, '🏏 BATTING STATS'),
            const SizedBox(height: 12),
            if (batting != null) ...[
              // Primary stats row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  border: Border.all(color: AppColors.primaryYellow, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildBigStat(context, '${batting.runs}', 'RUNS'),
                        _verticalDivider(),
                        _buildBigStat(context, '${batting.matches}', 'MATCHES'),
                        _verticalDivider(),
                        _buildBigStat(context, '${batting.highScore}', 'HIGH'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFF333333)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSmallStat(
                          batting.innings > 0
                              ? (batting.runs / batting.innings).toStringAsFixed(1)
                              : '-',
                          'AVERAGE',
                        ),
                        _buildSmallStat(
                          batting.balls > 0
                              ? ((batting.runs / batting.balls) * 100).toStringAsFixed(1)
                              : '-',
                          'STRIKE RATE',
                        ),
                        _buildSmallStat('${batting.fours}', '4s'),
                        _buildSmallStat('${batting.sixes}', '6s'),
                      ],
                    ),
                    if (batting.fifties > 0 || batting.hundreds > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (batting.hundreds > 0)
                            _milestoneChip('💯 x${batting.hundreds}', AppColors.primaryYellow),
                          if (batting.fifties > 0) ...[
                            if (batting.hundreds > 0) const SizedBox(width: 8),
                            _milestoneChip('50 x${batting.fifties}', const Color(0xFF888800)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              _buildNoDataCard('No batting data yet.\nScore a match with your name to see stats.'),

            const SizedBox(height: 24),

            // ── BOWLING STATS ──
            _buildSectionHeader(context, '⚾ BOWLING STATS'),
            const SizedBox(height: 12),
            if (bowling != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  border: Border.all(color: AppColors.primaryYellow, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildBigStat(context, '${bowling.wickets}', 'WICKETS'),
                        _verticalDivider(),
                        _buildBigStat(context, '${bowling.matches}', 'MATCHES'),
                        _verticalDivider(),
                        _buildBigStat(
                          context,
                          '${bowling.balls ~/ 6}.${bowling.balls % 6}',
                          'OVERS',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFF333333)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSmallStat(
                          bowling.wickets > 0
                              ? (bowling.runs / bowling.wickets).toStringAsFixed(1)
                              : '-',
                          'AVERAGE',
                        ),
                        _buildSmallStat(
                          bowling.balls > 0
                              ? ((bowling.runs / bowling.balls) * 6).toStringAsFixed(2)
                              : '-',
                          'ECONOMY',
                        ),
                        _buildSmallStat('${bowling.runs}', 'RUNS'),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              _buildNoDataCard('No bowling data yet.'),

            const SizedBox(height: 24),

            // ── MY TEAMS ──
            _buildSectionHeader(context, '🛡️ MY TEAMS'),
            const SizedBox(height: 12),
            teamsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppColors.primaryYellow),
                ),
              ),
              error: (e, _) => const Text(
                'Error loading teams',
                style: TextStyle(
                    color: AppColors.white, fontFamily: 'DM Sans'),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return _buildNoDataCard('No teams yet.\nGo to Teams tab to create or join one.');
                }
                return Column(
                  children: teams
                      .map((team) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                border: Border.all(
                                    color: AppColors.black, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield,
                                      color: AppColors.primaryYellow,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      team.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${team.members.length} members',
                                    style: const TextStyle(
                                      color: Color(0xFFAAAAAA),
                                      fontSize: 12,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 32),

            // Sign out button
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider).signOut();
                ref.read(profileNotifierProvider.notifier).clearProfile();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.red),
              label: const Text(
                'SIGN OUT',
                style: TextStyle(color: AppColors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.red, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ──

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: AppColors.primaryYellow),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildProfileInfoTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryYellow, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryYellow,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryYellow,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontFamily: 'Rajdhani',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: AppColors.primaryYellow);
  }

  Widget _buildSmallStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Rajdhani',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: color,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'DM Sans',
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2A8A00), width: 1.5),
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

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: AppColors.primaryGreen,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primaryYellow,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          fontFamily: 'Rajdhani',
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(BuildContext context, _AnalysisResult? analysis, String? role) {
    if (analysis == null) {
      return _buildNoDataCard('No match records found.\nScore matches to start performance analysis.');
    }

    final roleStr = (role ?? 'batter').toLowerCase();
    final isAllRounder = roleStr.contains('all rounder');
    final isBowler = roleStr == 'bowler' || roleStr.contains('bowling');
    final isBatter = roleStr == 'batter' || roleStr == 'wicketkeeper' || roleStr.contains('batting');

    // If matches count is less than 10, show locked state
    if (analysis.totalMatches < 10) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.black,
          border: Border.all(color: AppColors.red, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock, color: AppColors.red, size: 32),
            const SizedBox(height: 12),
            Text(
              'ANALYSIS LOCKED',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.red),
            ),
            const SizedBox(height: 8),
            Text(
              'Play at least 10 matches to unlock strengths and weaknesses.\nProgress: ${analysis.totalMatches} / 10 matches.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontFamily: 'DM Sans',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Unlocked analysis cards
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.primaryYellow, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, color: AppColors.primaryYellow, size: 24),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHTS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryYellow,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Batting insights (if role is batter, all-rounder, or has batting stats)
          if (isAllRounder || isBatter || analysis.battingStrength != 'N/A') ...[
            const Text(
              '🏏 BATTING ANALYSIS',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'DM Sans',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    title: 'STRENGTH',
                    value: analysis.battingStrength.toUpperCase(),
                    isStrength: true,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    title: 'WEAKNESS',
                    value: analysis.battingWeakness.toUpperCase(),
                    isStrength: false,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            if (isAllRounder || isBowler) const SizedBox(height: 16),
          ],

          // Bowling insights (if role is bowler, all-rounder, or has bowling stats)
          if (isAllRounder || isBowler || analysis.bowlingStrength != 'N/A') ...[
            const Text(
              '⚾ BOWLING & ALL-ROUND ANALYSIS',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'DM Sans',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    title: 'STRENGTH',
                    value: analysis.bowlingStrength.toUpperCase(),
                    isStrength: true,
                    icon: Icons.shield,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    title: 'WEAKNESS',
                    value: analysis.bowlingWeakness.toUpperCase(),
                    isStrength: false,
                    icon: Icons.dangerous,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required bool isStrength,
    required IconData icon,
  }) {
    final borderColor = isStrength ? AppColors.primaryGreen : AppColors.red;
    const textColor = AppColors.white;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: borderColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DM Sans',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Rajdhani',
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats computation ──

  _BattingStats? _computePlayerBatting(List<MatchState> matches, String playerName) {
    if (matches.isEmpty) return null;

    final stats = _BattingStats();
    bool found = false;

    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      final playerBalls = allBalls.where((b) => b.batterId == playerName);

      if (playerBalls.isEmpty) continue;
      found = true;
      stats.matches++;

      int inningRuns = 0;
      for (final ball in playerBalls) {
        if (ball.extraType != 'wide') {
          stats.balls++;
          stats.runs += ball.runs;
          inningRuns += ball.runs;
          if (ball.runs == 4) stats.fours++;
          if (ball.runs == 6) stats.sixes++;
        }
      }

      final isDismissed = allBalls.any(
          (b) => b.batterId == playerName && b.isWicket && b.wicketType != 'run_out');
      if (isDismissed) stats.innings++;

      if (inningRuns > stats.highScore) stats.highScore = inningRuns;
      if (inningRuns >= 100) {
        stats.hundreds++;
      } else if (inningRuns >= 50) {
        stats.fifties++;
      }
    }

    return found ? stats : null;
  }

  _BowlingStats? _computePlayerBowling(List<MatchState> matches, String playerName) {
    if (matches.isEmpty) return null;

    final stats = _BowlingStats();
    bool found = false;

    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      final playerBalls = allBalls.where((b) => b.bowlerId == playerName);

      if (playerBalls.isEmpty) continue;
      found = true;
      stats.matches++;

      for (final ball in playerBalls) {
        if (ball.isLegalBall) stats.balls++;
        if (ball.extraType != 'bye' && ball.extraType != 'leg_bye') {
          stats.runs += ball.totalRuns;
        }
        if (ball.isWicket && ball.wicketType != 'run_out') {
          stats.wickets++;
        }
      }
    }

    return found ? stats : null;
  }

  // ── AI Insights performance prediction ──

  _AnalysisResult? _analyzePlayerPerformance(
      List<MatchState> matches,
      String playerName,
      Map<String, Map<String, dynamic>> profilesCache) {
    if (matches.isEmpty) return null;

    int matchCount = 0;
    
    // Batting calculations against bowler type
    // Map of bowlerType -> { runs, balls, dismissals }
    final Map<String, _BowlerTypeStats> battingAgainstBowlerType = {};
    
    // Bowling metrics
    int bowlingMatches = 0;
    int bowlingBalls = 0;
    int bowlingRunsConceded = 0;
    int bowlingWickets = 0;

    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      
      final playedBatting = allBalls.any((b) => b.batterId == playerName);
      final playedBowling = allBalls.any((b) => b.bowlerId == playerName);
      
      if (playedBatting || playedBowling) {
        matchCount++;
      }

      if (playedBatting) {
        final playerBattingBalls = allBalls.where((b) => b.batterId == playerName);
        for (final ball in playerBattingBalls) {
          final bowlerName = ball.bowlerId;
          final bowlerType = _getBowlerType(bowlerName, profilesCache);
          
          final stats = battingAgainstBowlerType.putIfAbsent(
              bowlerType, () => _BowlerTypeStats());
              
          if (ball.extraType != 'wide') {
            stats.balls++;
            stats.runs += ball.runs;
          }
        }
        
        // Dismissals by bowler type
        final dismissals = allBalls.where((b) =>
            b.batterId == playerName &&
            b.isWicket &&
            b.wicketType != 'run_out');
        for (final d in dismissals) {
          final bowlerName = d.bowlerId;
          final bowlerType = _getBowlerType(bowlerName, profilesCache);
          final stats = battingAgainstBowlerType.putIfAbsent(
              bowlerType, () => _BowlerTypeStats());
          stats.dismissals++;
        }
      }

      if (playedBowling) {
        final playerBowlingBalls = allBalls.where((b) => b.bowlerId == playerName);
        if (playerBowlingBalls.isNotEmpty) {
          bowlingMatches++;
          for (final ball in playerBowlingBalls) {
            if (ball.isLegalBall) {
              bowlingBalls++;
            }
            if (ball.extraType != 'bye' && ball.extraType != 'leg_bye') {
              bowlingRunsConceded += ball.totalRuns;
            }
            if (ball.isWicket && ball.wicketType != 'run_out') {
              bowlingWickets++;
            }
          }
        }
      }
    }

    // Predict Batting Strength & Weakness
    String battingStrength = "N/A";
    String battingWeakness = "N/A";

    if (battingAgainstBowlerType.isNotEmpty) {
      String bestType = "N/A";
      double bestScore = -1.0;
      
      String worstType = "N/A";
      double worstScore = 99999.0;
      int maxDismissals = 0;

      for (final entry in battingAgainstBowlerType.entries) {
        final type = entry.key;
        final stats = entry.value;
        final strikeRate = stats.balls > 0 ? (stats.runs / stats.balls) * 100 : 0.0;
        final average = stats.dismissals > 0 ? stats.runs / stats.dismissals : stats.runs.toDouble();
        
        // Strength scoring (minimum 5 balls faced)
        if (stats.balls >= 5) {
          final score = average * 0.6 + (strikeRate * 0.4);
          if (score > bestScore) {
            bestScore = score;
            bestType = type;
          }
        }
        
        // Weakness scoring (maximum dismissals, or lowest average)
        if (stats.dismissals > maxDismissals) {
          maxDismissals = stats.dismissals;
          worstType = type;
        } else if (stats.dismissals == maxDismissals && maxDismissals > 0) {
          if (average < worstScore) {
            worstScore = average;
            worstType = type;
          }
        } else if (maxDismissals == 0 && stats.balls >= 5) {
          if (strikeRate < worstScore) {
            worstScore = strikeRate;
            worstType = type;
          }
        }
      }

      if (bestType != "N/A") {
        battingStrength = bestType;
      }
      if (worstType != "N/A") {
        battingWeakness = worstType;
      }
    }

    // Predict Bowling Strength & Weakness
    String bowlingStrength = "N/A";
    String bowlingWeakness = "N/A";

    if (bowlingMatches > 0) {
      final economy = bowlingBalls > 0 ? (bowlingRunsConceded / bowlingBalls) * 6 : 0.0;
      final strikeRate = bowlingWickets > 0 ? bowlingBalls / bowlingWickets : 999.0;
      final avgWicketsPerMatch = bowlingWickets / bowlingMatches;
      
      // Bowling Strength Prediction
      if (economy <= 6.5) {
        bowlingStrength = "economy";
      } else if (avgWicketsPerMatch >= 1.5 || strikeRate <= 18.0) {
        bowlingStrength = "wicket taker";
      } else {
        if (economy <= 7.8) {
          bowlingStrength = "economy";
        } else {
          bowlingStrength = "wicket taker";
        }
      }

      // Bowling Weakness Prediction
      if (economy > 8.5) {
        bowlingWeakness = "economy";
      } else if (strikeRate > 24.0 || bowlingWickets == 0) {
        bowlingWeakness = "taking wickets (strike rate)";
      } else {
        if (economy > 7.5) {
          bowlingWeakness = "economy";
        } else {
          bowlingWeakness = "taking wickets (strike rate)";
        }
      }
    }

    return _AnalysisResult(
      battingStrength: battingStrength,
      battingWeakness: battingWeakness,
      bowlingStrength: bowlingStrength,
      bowlingWeakness: bowlingWeakness,
      totalMatches: matchCount,
    );
  }

  String _getBowlerType(String bowlerName, Map<String, Map<String, dynamic>> profilesCache) {
    final nameLower = bowlerName.toLowerCase();
    if (profilesCache.containsKey(nameLower)) {
      final p = profilesCache[nameLower];
      final type = p?['bowling_type'];
      final hand = p?['bowling_hand'];
      if (type != null && hand != null) {
        return '${hand.toString().toLowerCase()} ${type.toString().toLowerCase()}';
      }
    }
    
    // Fallback: Deterministic assignment based on name hash
    final hashCode = nameLower.hashCode.abs();
    final hands = ['right-arm', 'left-arm'];
    
    // Specific pattern matching
    if (nameLower.contains('spin')) return 'right-arm wrist spin';
    if (nameLower.contains('fast')) return 'right-arm fast';
    if (nameLower.contains('left')) return 'left-arm orthodox';

    final hand = hands[hashCode % hands.length];
    if (hand == 'left-arm') {
      final leftTypes = ['orthodox', 'chinaman', 'medium', 'fast'];
      return 'left-arm ${leftTypes[hashCode % leftTypes.length]}';
    } else {
      final rightTypes = ['fast', 'medium fast', 'medium', 'orthodox', 'wrist spin'];
      return 'right-arm ${rightTypes[hashCode % rightTypes.length]}';
    }
  }
}

class _BattingStats {
  int matches = 0;
  int innings = 0;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  int highScore = 0;
  int fifties = 0;
  int hundreds = 0;
}

class _BowlingStats {
  int matches = 0;
  int balls = 0;
  int runs = 0;
  int wickets = 0;
}

class _AnalysisResult {
  final String battingStrength;
  final String battingWeakness;
  final String bowlingStrength;
  final String bowlingWeakness;
  final int totalMatches;

  _AnalysisResult({
    required this.battingStrength,
    required this.battingWeakness,
    required this.bowlingStrength,
    required this.bowlingWeakness,
    required this.totalMatches,
  });
}

class _BowlerTypeStats {
  int runs = 0;
  int balls = 0;
  int dismissals = 0;
}
