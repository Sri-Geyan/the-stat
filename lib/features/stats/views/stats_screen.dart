import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/storage/hive_registry.dart';
import '../../scoring/models/match_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = HiveRegistry.getAllMatches();
    final batting = _computeBattingStats(matches);
    final bowling = _computeBowlingStats(matches);

    return Scaffold(
      appBar: AppBar(
        title: Text('PLAYER STATS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'BATTING'),
            Tab(text: 'BOWLING'),
          ],
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: AppColors.white,
          indicatorColor: AppColors.primaryYellow,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: matches.isEmpty
          ? _buildEmptyState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBattingTab(batting),
                _buildBowlingTab(bowling),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_cricket, color: AppColors.primaryYellow, size: 64),
          const SizedBox(height: 16),
          Text(
            'NO MATCHES YET',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Score your first match to see\nplayer stats here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingTab(List<_PlayerBatting> stats) {
    if (stats.isEmpty) return _buildEmptyState();
    // Sort by runs desc
    stats.sort((a, b) => b.runs.compareTo(a.runs));

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.black,
          child: const Row(
            children: [
              SizedBox(width: 28, child: Text('#', style: _hStyle)),
              SizedBox(width: 8),
              Expanded(child: Text('PLAYER', style: _hStyle)),
              SizedBox(width: 40, child: Text('M', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 40, child: Text('R', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 44, child: Text('AVG', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 44, child: Text('SR', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 36, child: Text('HS', textAlign: TextAlign.center, style: _hStyle)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stats.length,
            itemBuilder: (ctx, i) {
              final s = stats[i];
              final avg = s.innings > 0 ? (s.runs / s.innings).toStringAsFixed(1) : '-';
              final sr = s.balls > 0 ? ((s.runs / s.balls) * 100).toStringAsFixed(1) : '-';
              return Container(
                decoration: BoxDecoration(
                  color: i % 2 == 0 ? AppColors.primaryGreen : const Color(0xFF155200),
                  border: const Border(bottom: BorderSide(color: Color(0xFF1A6B00), width: 1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i < 3 ? AppColors.primaryYellow : AppColors.white,
                          fontFamily: 'Rajdhani',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          if (s.fifties > 0 || s.hundreds > 0)
                            Row(
                              children: [
                                if (s.hundreds > 0) _badgeWidget('100x${s.hundreds}', AppColors.primaryYellow),
                                if (s.fifties > 0) _badgeWidget('50x${s.fifties}', const Color(0xFF888800)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _numCell('${s.matches}'),
                    _numCell('${s.runs}', highlight: true),
                    _numCell(avg),
                    _numCell(sr),
                    _numCell('${s.highScore}'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBowlingTab(List<_PlayerBowling> stats) {
    if (stats.isEmpty) return _buildEmptyState();
    stats.sort((a, b) => b.wickets.compareTo(a.wickets));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.black,
          child: const Row(
            children: [
              SizedBox(width: 28, child: Text('#', style: _hStyle)),
              SizedBox(width: 8),
              Expanded(child: Text('PLAYER', style: _hStyle)),
              SizedBox(width: 36, child: Text('M', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 36, child: Text('O', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 36, child: Text('R', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 36, child: Text('W', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 44, child: Text('AVG', textAlign: TextAlign.center, style: _hStyle)),
              SizedBox(width: 44, child: Text('ER', textAlign: TextAlign.center, style: _hStyle)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stats.length,
            itemBuilder: (ctx, i) {
              final s = stats[i];
              final avg = s.wickets > 0 ? (s.runs / s.wickets).toStringAsFixed(1) : '-';
              final er = s.balls > 0 ? ((s.runs / s.balls) * 6).toStringAsFixed(2) : '-';
              final overs = '${s.balls ~/ 6}.${s.balls % 6}';
              return Container(
                decoration: BoxDecoration(
                  color: i % 2 == 0 ? AppColors.primaryGreen : const Color(0xFF155200),
                  border: const Border(bottom: BorderSide(color: Color(0xFF1A6B00), width: 1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}', style: TextStyle(color: i < 3 ? AppColors.primaryYellow : AppColors.white, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.name, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    _numCell('${s.matches}'),
                    _numCell(overs),
                    _numCell('${s.runs}'),
                    _numCell('${s.wickets}', highlight: true),
                    _numCell(avg),
                    _numCell(er),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _numCell(String val, {bool highlight = false}) {
    return SizedBox(
      width: highlight ? 36 : 36,
      child: Text(
        val,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? AppColors.primaryYellow : AppColors.white,
          fontFamily: 'Rajdhani',
          fontSize: 15,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _badgeWidget(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      color: color,
      child: Text(label, style: const TextStyle(color: AppColors.black, fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  static const TextStyle _hStyle = TextStyle(
    color: AppColors.primaryYellow,
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  List<_PlayerBatting> _computeBattingStats(List<MatchState> matches) {
    final Map<String, _PlayerBatting> stats = {};

    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      for (final ball in allBalls) {
        stats.putIfAbsent(ball.batterId, () => _PlayerBatting(ball.batterId));
        if (ball.extraType != 'wide') {
          stats[ball.batterId]!.balls++;
          stats[ball.batterId]!.totalRuns += ball.runs;
          if (ball.runs == 4) stats[ball.batterId]!.fours++;
          if (ball.runs == 6) stats[ball.batterId]!.sixes++;
        }
      }

      // Track innings and high scores per match
      final uniqueBatters = allBalls.map((b) => b.batterId).toSet();
      for (final batter in uniqueBatters) {
        stats[batter]!.matches++;
        final inningRuns = allBalls.where((b) => b.batterId == batter && b.extraType != 'wide').fold(0, (s, b) => s + b.runs);
        final isDismissed = allBalls.any((b) => b.batterId == batter && b.isWicket && b.wicketType != 'run_out');
        if (isDismissed) stats[batter]!.innings++;
        if (inningRuns > stats[batter]!.highScore) stats[batter]!.highScore = inningRuns;
        if (inningRuns >= 100) {
          stats[batter]!.hundreds++;
        } else if (inningRuns >= 50) {
          stats[batter]!.fifties++;
        }
      }
    }

    return stats.values.toList();
  }

  List<_PlayerBowling> _computeBowlingStats(List<MatchState> matches) {
    final Map<String, _PlayerBowling> stats = {};

    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      for (final ball in allBalls) {
        stats.putIfAbsent(ball.bowlerId, () => _PlayerBowling(ball.bowlerId));
        if (ball.isLegalBall) stats[ball.bowlerId]!.balls++;
        if (ball.extraType != 'bye' && ball.extraType != 'leg_bye') {
          stats[ball.bowlerId]!.runs += ball.totalRuns;
        }
        if (ball.isWicket && ball.wicketType != 'run_out') {
          stats[ball.bowlerId]!.wickets++;
        }
      }

      final uniqueBowlers = allBalls.map((b) => b.bowlerId).toSet();
      for (final bowler in uniqueBowlers) {
        stats[bowler]!.matches++;
      }
    }

    return stats.values.toList();
  }
}

class _PlayerBatting {
  final String name;
  int matches = 0;
  int innings = 0;
  int totalRuns = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  int highScore = 0;
  int fifties = 0;
  int hundreds = 0;
  _PlayerBatting(this.name);
  int get runs => totalRuns;
}

class _PlayerBowling {
  final String name;
  int matches = 0;
  int balls = 0;
  int runs = 0;
  int wickets = 0;
  _PlayerBowling(this.name);
}
