import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/storage/hive_registry.dart';
import '../../scoring/models/match_state.dart';

class RankingsScreen extends StatelessWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = HiveRegistry.getAllMatches();
    final batters = _computeBatting(matches);
    final bowlers = _computeBowling(matches);

    // Sort
    batters.sort((a, b) => b.runs.compareTo(a.runs));
    bowlers.sort((a, b) => b.wickets.compareTo(a.wickets));

    return Scaffold(
      appBar: AppBar(
        title: Text('COMMUNITY RANKINGS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow)),
      ),
      body: matches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.leaderboard, color: AppColors.primaryYellow, size: 64),
                  const SizedBox(height: 16),
                  Text('NO DATA YET', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Score matches to see who tops\nthe Tamil Nadu charts!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top 3 Batsmen Podium
                  if (batters.isNotEmpty) ...[
                    _buildSectionHeader(context, '🏏 TOP RUN SCORERS'),
                    const SizedBox(height: 12),
                    if (batters.length >= 3) _buildPodium(context, batters.take(3).toList()),
                    const SizedBox(height: 16),
                    _buildRankingList(
                      context,
                      batters.skip(3).take(7).toList(),
                      startRank: 4,
                      valueLabel: 'RUNS',
                      getValue: (p) => '${p.runs}',
                      getSubValue: (p) {
                        final sr = p.balls > 0 ? ((p.runs / p.balls) * 100).toStringAsFixed(0) : '-';
                        return 'SR: $sr';
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Top Wicket Takers
                  if (bowlers.isNotEmpty) ...[
                    _buildSectionHeader(context, '🎯 TOP WICKET TAKERS'),
                    const SizedBox(height: 12),
                    if (bowlers.length >= 3) _buildPodium(context, bowlers.take(3).toList()),
                    const SizedBox(height: 16),
                    _buildRankingList(
                      context,
                      bowlers.skip(3).take(7).toList(),
                      startRank: 4,
                      valueLabel: 'WICKETS',
                      getValue: (p) => '${p.wickets}',
                      getSubValue: (p) {
                        final er = p.balls > 0 ? ((p.runs / p.balls) * 6).toStringAsFixed(2) : '-';
                        return 'ER: $er';
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Boundary King
                  if (batters.isNotEmpty) ...[
                    _buildSectionHeader(context, '⚡ BOUNDARY KINGS'),
                    const SizedBox(height: 12),
                    ...(() {
                      final boundary = batters.where((p) => p.sixes > 0 || p.fours > 0).toList()
                        ..sort((a, b) => (b.sixes * 2 + b.fours).compareTo(a.sixes * 2 + a.fours));
                      return boundary.take(5).toList().asMap().entries
                          .map((e) => _buildBoundaryRow(context, e.key + 1, e.value));
                    })(),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: AppColors.primaryYellow),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.white)),
      ],
    );
  }

  Widget _buildPodium(BuildContext context, List<dynamic> top3) {
    final names = top3.map((p) => p.name as String).toList();
    final values = top3.map((p) {
      if (p is _RankBatter) return '${p.runs} runs';
      if (p is _RankBowler) return '${p.wickets} wkts';
      return '';
    }).toList();

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _buildPodiumBar(context, 2, names[1], values[1], 110, const Color(0xFFC0C0C0))),
          const SizedBox(width: 4),
          // 1st place
          Expanded(child: _buildPodiumBar(context, 1, names[0], values[0], 140, AppColors.primaryYellow)),
          const SizedBox(width: 4),
          // 3rd place
          Expanded(child: _buildPodiumBar(context, 3, names[2], values[2], 85, const Color(0xFFCD7F32))),
        ],
      ),
    );
  }

  Widget _buildPodiumBar(BuildContext context, int rank, String name, String value, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _shortenName(name),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.black, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: TextStyle(
                  color: rank == 1 ? AppColors.black : AppColors.black,
                  fontFamily: 'Rajdhani',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.black,
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList<T>(
    BuildContext context,
    List<T> players, {
    required int startRank,
    required String valueLabel,
    required String Function(T) getValue,
    required String Function(T) getSubValue,
  }) {
    if (players.isEmpty) return const SizedBox();
    return Column(
      children: players.asMap().entries.map((e) {
        final rank = startRank + e.key;
        final p = e.value;
        final name = (p as dynamic).name as String;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            border: Border.all(color: AppColors.black, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$rank',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(getSubValue(p), style: const TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'DM Sans', fontSize: 11)),
                  ],
                ),
              ),
              Text(
                getValue(p),
                style: const TextStyle(color: AppColors.primaryYellow, fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBoundaryRow(BuildContext context, int rank, _RankBatter p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        border: Border.all(color: AppColors.black, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank', style: const TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(p.name, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF0055FF),
                child: Text('${p.fours}x4', style: const TextStyle(color: AppColors.white, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.primaryYellow,
                child: Text('${p.sixes}x6', style: const TextStyle(color: AppColors.black, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortenName(String name) {
    final parts = name.split(' ');
    if (parts.length > 2) return '${parts[0]}\n${parts[1]}';
    return name;
  }

  List<_RankBatter> _computeBatting(List<MatchState> matches) {
    final Map<String, _RankBatter> stats = {};
    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      for (final ball in allBalls) {
        stats.putIfAbsent(ball.batterId, () => _RankBatter(ball.batterId));
        if (ball.extraType != 'wide') {
          stats[ball.batterId]!.balls++;
          stats[ball.batterId]!.runs += ball.runs;
          if (ball.runs == 4) stats[ball.batterId]!.fours++;
          if (ball.runs == 6) stats[ball.batterId]!.sixes++;
        }
      }
    }
    return stats.values.where((p) => p.balls > 0).toList();
  }

  List<_RankBowler> _computeBowling(List<MatchState> matches) {
    final Map<String, _RankBowler> stats = {};
    for (final match in matches) {
      final allBalls = [...match.innings1BallHistory, ...match.balls];
      for (final ball in allBalls) {
        stats.putIfAbsent(ball.bowlerId, () => _RankBowler(ball.bowlerId));
        if (ball.isLegalBall) stats[ball.bowlerId]!.balls++;
        if (ball.extraType != 'bye' && ball.extraType != 'leg_bye') {
          stats[ball.bowlerId]!.runs += ball.totalRuns;
        }
        if (ball.isWicket && ball.wicketType != 'run_out') {
          stats[ball.bowlerId]!.wickets++;
        }
      }
    }
    return stats.values.where((p) => p.balls > 0).toList();
  }
}

class _RankBatter {
  final String name;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  _RankBatter(this.name);
}

class _RankBowler {
  final String name;
  int balls = 0;
  int runs = 0;
  int wickets = 0;
  _RankBowler(this.name);
}
