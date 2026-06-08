import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../scoring/models/match_state.dart';
import '../../scoring/models/ball_record.dart';

class ScorecardScreen extends StatelessWidget {
  final MatchState match;
  const ScorecardScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'SCORECARD',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: '1st INN'),
              Tab(text: '2nd INN'),
            ],
            labelColor: AppColors.primaryYellow,
            unselectedLabelColor: AppColors.white,
            indicatorColor: AppColors.primaryYellow,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        body: TabBarView(
          children: [
            _buildInningsScorecard(context, match.innings1BallHistory, match.teamAName, match.innings1Runs, match.innings1Wickets, '${match.innings1Balls ~/ 6}.${match.innings1Balls % 6}'),
            _buildInningsScorecard(context, match.balls, match.teamBName, match.currentRuns, match.currentWickets, match.currentOvers),
          ],
        ),
        bottomNavigationBar: match.status == 'completed' 
          ? Container(
              color: AppColors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.primaryYellow,
                    child: Text(
                      '🏆 ${match.winner.toUpperCase()} WON BY ${match.margin.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildInningsScorecard(
    BuildContext context,
    List<BallRecord> balls,
    String teamName,
    int runs,
    int wickets,
    String overs,
  ) {
    // Compute batting stats
    final Map<String, _BatterStats> batters = {};
    for (final ball in balls) {
      batters.putIfAbsent(ball.batterId, () => _BatterStats(ball.batterId));
      if (ball.extraType != 'wide') {
        batters[ball.batterId]!.balls++;
        batters[ball.batterId]!.runs += ball.runs;
        if (ball.runs == 4) batters[ball.batterId]!.fours++;
        if (ball.runs == 6) batters[ball.batterId]!.sixes++;
      }
      if (ball.isWicket && ball.wicketType != 'run_out') {
        batters[ball.batterId]!.dismissed = true;
        batters[ball.batterId]!.wicketType = ball.wicketType;
        batters[ball.batterId]!.bowlerId = ball.bowlerId;
      }
    }

    // Compute bowling stats
    final Map<String, _BowlerStats> bowlers = {};
    for (final ball in balls) {
      bowlers.putIfAbsent(ball.bowlerId, () => _BowlerStats(ball.bowlerId));
      if (ball.isLegalBall) bowlers[ball.bowlerId]!.balls++;
      if (ball.extraType != 'bye' && ball.extraType != 'leg_bye') {
        bowlers[ball.bowlerId]!.runs += ball.totalRuns;
      }
      if (ball.isWicket && ball.wicketType != 'run_out') {
        bowlers[ball.bowlerId]!.wickets++;
      }
      if (ball.extraType == 'wide') bowlers[ball.bowlerId]!.wides++;
      if (ball.extraType == 'no_ball') bowlers[ball.bowlerId]!.noBalls++;
    }

    final totalExtras = balls.fold(0, (sum, b) => sum + b.extras);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Team header
          Container(
            padding: const EdgeInsets.all(14),
            color: AppColors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  teamName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontFamily: 'Rajdhani',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$runs/$wickets  ($overs ov)',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Rajdhani',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Batting card
          _buildTableHeader(['BATTER', 'R', 'B', '4s', '6s', 'SR']),
          ...batters.values.map((b) => _buildBatterRow(b)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF0A4000),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EXTRAS', style: TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.bold)),
                Text('$totalExtras', style: const TextStyle(color: AppColors.white, fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bowling card
          _buildTableHeader(['BOWLER', 'O', 'R', 'W', 'Wd', 'Nb']),
          ...bowlers.values.map((b) => _buildBowlerRow(b)),
          const SizedBox(height: 24),

          // Over-by-over
          Row(
            children: [
              Container(width: 4, height: 20, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              const Text(
                'BALL BY BALL',
                style: TextStyle(
                  color: AppColors.primaryYellow,
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildOverByOver(balls),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.black,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(cols[0], style: _headerStyle),
          ),
          ...cols.skip(1).map(
            (c) => SizedBox(
              width: 36,
              child: Text(c, textAlign: TextAlign.center, style: _headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatterRow(_BatterStats b) {
    final sr = b.balls > 0 ? ((b.runs / b.balls) * 100).toStringAsFixed(1) : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A4A00), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
                if (b.dismissed)
                  Text('${b.wicketType} b ${b.bowlerId}', style: const TextStyle(color: Color(0xFF999999), fontFamily: 'DM Sans', fontSize: 11))
                else
                  const Text('not out', style: TextStyle(color: Color(0xFF4CAF50), fontFamily: 'DM Sans', fontSize: 11)),
              ],
            ),
          ),
          _statCell('${b.runs}', highlight: true),
          _statCell('${b.balls}'),
          _statCell('${b.fours}'),
          _statCell('${b.sixes}'),
          _statCell(sr),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(_BowlerStats b) {
    final overs = '${b.balls ~/ 6}.${b.balls % 6}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A4A00), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(b.name, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          _statCell(overs),
          _statCell('${b.runs}'),
          _statCell('${b.wickets}', highlight: b.wickets > 0),
          _statCell('${b.wides}'),
          _statCell('${b.noBalls}'),
        ],
      ),
    );
  }

  Widget _statCell(String val, {bool highlight = false}) {
    return SizedBox(
      width: 36,
      child: Text(
        val,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? AppColors.primaryYellow : AppColors.white,
          fontFamily: 'Rajdhani',
          fontSize: 16,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildOverByOver(List<BallRecord> balls) {
    if (balls.isEmpty) {
      return const Text('No balls recorded.', style: TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'DM Sans'));
    }

    // Group by overIndex
    final Map<int, List<BallRecord>> overs = {};
    for (final b in balls) {
      overs.putIfAbsent(b.overIndex, () => []);
      overs[b.overIndex]!.add(b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: overs.entries.map((entry) {
        final overNum = entry.key + 1;
        final overBalls = entry.value;
        final overRuns = overBalls.fold(0, (sum, b) => sum + b.totalRuns);
        final overWickets = overBalls.where((b) => b.isWicket).length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'O$overNum',
                  style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: overBalls.map((b) => _buildBallChip(b)).toList(),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$overRuns${overWickets > 0 ? '/$overWickets' : ''}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBallChip(BallRecord b) {
    Color bg = AppColors.black;
    Color fg = AppColors.white;
    if (b.isWicket) { bg = AppColors.red; fg = AppColors.white; }
    else if (b.runs == 4) { bg = const Color(0xFF0055FF); fg = AppColors.white; }
    else if (b.runs == 6) { bg = AppColors.primaryYellow; fg = AppColors.black; }
    else if (b.extraType != 'none') { bg = const Color(0xFF555500); fg = AppColors.primaryYellow; }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3), width: 1),
      ),
      child: Text(
        b.displayString,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani'),
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    color: AppColors.primaryYellow,
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

class _BatterStats {
  final String name;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  bool dismissed = false;
  String wicketType = '';
  String bowlerId = '';
  _BatterStats(this.name);
}

class _BowlerStats {
  final String name;
  int runs = 0;
  int balls = 0;
  int wickets = 0;
  int wides = 0;
  int noBalls = 0;
  _BowlerStats(this.name);
}
