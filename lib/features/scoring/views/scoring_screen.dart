import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../controllers/scoring_notifier.dart';
import '../models/ball_record.dart';
import '../models/match_state.dart';
import '../../scorecard/views/scorecard_screen.dart';

class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({super.key});

  void _showWicketDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryGreen,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.black, width: 3),
          ),
          title: Text(
            'DISMISSAL TYPE',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryYellow,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWicketOption(context, ref, 'Bowled'),
              _buildWicketOption(context, ref, 'Caught'),
              _buildWicketOption(context, ref, 'LBW'),
              _buildWicketOption(context, ref, 'Run Out'),
              _buildWicketOption(context, ref, 'Stumped'),
              _buildWicketOption(context, ref, 'Hit Wicket'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWicketOption(BuildContext context, WidgetRef ref, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
        ),
        onPressed: () {
          ref.read(scoringProvider.notifier).recordBall(
                runs: 0,
                isWicket: true,
                wicketType: type.toLowerCase(),
              );
          Navigator.pop(context);
        },
        child: Text(type.toUpperCase()),
      ),
    );
  }

  void _showExtraDialog(BuildContext context, WidgetRef ref) {
    int extraRuns = 1;
    String extraType = 'wide';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.primaryGreen,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.black, width: 3),
              ),
              title: Text(
                'RECORD EXTRA',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryYellow,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRadio(
                        label: 'WIDE',
                        selected: extraType == 'wide',
                        onTap: () => setDialogState(() => extraType = 'wide'),
                      ),
                      _buildRadio(
                        label: 'NO BALL',
                        selected: extraType == 'no_ball',
                        onTap: () => setDialogState(() => extraType = 'no_ball'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRadio(
                        label: 'BYE',
                        selected: extraType == 'bye',
                        onTap: () => setDialogState(() => extraType = 'bye'),
                      ),
                      _buildRadio(
                        label: 'LEG BYE',
                        selected: extraType == 'leg_bye',
                        onTap: () => setDialogState(() => extraType = 'leg_bye'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'TOTAL RUNS FROM THIS BALL:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [1, 2, 3, 4, 5].map((val) {
                      final isSelected = extraRuns == val;
                      return InkWell(
                        onTap: () => setDialogState(() => extraRuns = val),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryYellow : AppColors.black,
                            border: Border.all(color: AppColors.black, width: 2),
                          ),
                          child: Text(
                            '$val',
                            style: TextStyle(
                              color: isSelected ? AppColors.black : AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      int runsVal = 0;
                      int extrasVal = extraRuns;
                      if (extraType == 'no_ball') {
                        // In no_ball, extraRuns is the total runs, but we subtract 1 for the penalty
                        // and assign the rest to the batsman as runs off the bat (or byes)
                        runsVal = extraRuns - 1;
                        extrasVal = 1;
                      } else if (extraType == 'wide') {
                        runsVal = 0;
                        extrasVal = extraRuns;
                      } else {
                        // Byes or Leg byes
                        runsVal = 0;
                        extrasVal = extraRuns;
                      }

                      ref.read(scoringProvider.notifier).recordBall(
                            runs: runsVal,
                            extraType: extraType,
                            extras: extrasVal,
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('SUBMIT'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadio({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryYellow : AppColors.black,
          border: Border.all(color: AppColors.black, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.black : AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showChangeBowlerDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.primaryGreen,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.black, width: 3),
          ),
          title: Text('CHANGE BOWLER', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow)),
          content: Container(
            decoration: const BoxDecoration(
              color: AppColors.black,
              border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
            ),
            child: TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
              decoration: const InputDecoration(
                hintText: 'Enter new bowler name',
                hintStyle: TextStyle(color: Color(0xFF888888), fontFamily: 'DM Sans', fontSize: 13),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref.read(scoringProvider.notifier).changeBowler(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(scoringProvider);

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SCORING ENGINE')),
        body: const Center(
          child: Text(
            'No active match found.',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }

    final currentBalls = match.balls;
    final currentOversCount = match.currentLegalBalls;
    final currentOverIndex = currentOversCount ~/ 6;
    final overBalls = currentBalls.where((b) => b.overIndex == currentOverIndex).toList();

    // Stats calculations
    final runs = match.currentRuns;
    final wickets = match.currentWickets;
    final oversStr = match.currentOvers;
    final crr = match.currentLegalBalls > 0 
        ? (runs / (match.currentLegalBalls / 6)).toStringAsFixed(2) 
        : '0.00';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${match.teamAName} vs ${match.teamBName}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryYellow,
                fontSize: 16,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(scoringProvider.notifier).clearMatch();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.primaryYellow),
            tooltip: 'Change Bowler',
            onPressed: () => _showChangeBowlerDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: AppColors.white),
            tooltip: 'Scorecard',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ScorecardScreen(match: match),
              ));
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner for match status/completed
          if (match.status == 'completed')
            Container(
              color: AppColors.primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'MATCH COMPLETED: ${match.winner.toUpperCase()} WON BY ${match.margin.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team matchup row
                  Text(
                    '${match.teamAName.toUpperCase()} vs ${match.teamBName.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Large Score Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'INNINGS ${match.currentInnings}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.primaryYellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'CRR: $crr',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$runs/$wickets',
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                              Text(
                                '$oversStr OVERS',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.white,
                                    ),
                              ),
                            ],
                          ),
                          if (match.currentInnings == 2) ...[
                            const Divider(height: 20),
                            _buildChasingTargetDetails(context, match, runs, wickets),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Batters / Bowler Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Batters Box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.black, width: 2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BATTERS',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.primaryYellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _buildPlayerRow(
                                  name: match.strikerId,
                                  isStriker: true,
                                  stats: '${_getBatterRuns(currentBalls, match.strikerId)} (${_getBatterBalls(currentBalls, match.strikerId)})',
                                ),
                                const SizedBox(height: 8),
                                _buildPlayerRow(
                                  name: match.nonStrikerId,
                                  isStriker: false,
                                  stats: '${_getBatterRuns(currentBalls, match.nonStrikerId)} (${_getBatterBalls(currentBalls, match.nonStrikerId)})',
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bowler Box
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BOWLER',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.primaryYellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _buildPlayerRow(
                                  name: match.bowlerId,
                                  isStriker: false,
                                  stats: '${_getBowlerWickets(currentBalls, match.bowlerId)}/${_getBowlerRuns(currentBalls, match.bowlerId)} (${_getBowlerOvers(currentBalls, match.bowlerId)})',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Over summary list
                  Row(
                    children: [
                      Text(
                        'THIS OVER: ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: overBalls.map((ball) {
                              return _buildOverBallChip(ball);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Scoring Engine keypad panel (only show if match is live)
                  if (match.status == 'live') ...[
                    // Row for basic scoring 0, 1, 2, 3
                    Row(
                      children: [
                        _buildScoringKey(context, ref, '0', 0),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '1', 1),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '2', 2),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '3', 3),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row for boundaries 4, 6 and buttons for Extras & Wicket
                    Row(
                      children: [
                        _buildScoringKey(context, ref, '4', 4, highlight: true),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '6', 6, highlight: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showExtraDialog(context, ref),
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                border: Border.all(color: AppColors.white, width: 2),
                              ),
                              child: const Text(
                                'EXTRA',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showWicketDialog(context, ref),
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                border: Border.all(color: AppColors.black, width: 2),
                              ),
                              child: const Text(
                                'WICKET',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons row (Undo & Rotate strike)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(scoringProvider.notifier).undoLastBall();
                          },
                          child: const Text('UNDO BALL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(scoringProvider.notifier).switchStriker();
                          },
                          child: const Text('SWAP STRIKE'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChasingTargetDetails(BuildContext context, MatchState match, int runs, int wickets) {
    final target = match.innings1Runs + 1;
    final runsNeeded = target - runs;
    final ballsLeft = (match.oversLimit * 6) - match.currentLegalBalls;
    final oversLeft = '${ballsLeft ~/ 6}.${ballsLeft % 6}';

    if (runsNeeded <= 0) {
      return Text(
        'Target reached! Match Completed.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
      );
    }

    return Text(
      'Chasing $target. Need $runsNeeded runs off $ballsLeft balls ($oversLeft ov)',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildPlayerRow({
    required String name,
    required bool isStriker,
    required String stats,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            isStriker ? '$name *' : name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isStriker ? AppColors.primaryYellow : AppColors.white,
              fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'DM Sans',
              fontSize: 14,
            ),
          ),
        ),
        Text(
          stats,
          style: TextStyle(
            color: isStriker ? AppColors.primaryYellow : AppColors.white,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOverBallChip(BallRecord ball) {
    Color bg = AppColors.white;
    Color fg = AppColors.black;

    if (ball.isWicket) {
      bg = AppColors.red;
      fg = AppColors.white;
    } else if (ball.extraType != 'none') {
      bg = AppColors.primaryYellow;
      fg = AppColors.black;
    }

    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Text(
        ball.displayString,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Rajdhani',
        ),
      ),
    );
  }

  Widget _buildScoringKey(
    BuildContext context,
    WidgetRef ref,
    String label,
    int runs, {
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(scoringProvider.notifier).recordBall(runs: runs);
        },
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? AppColors.primaryYellow : AppColors.black,
            border: Border.all(color: AppColors.black, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.black : AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
        ),
      ),
    );
  }

  // Helper stats methods
  int _getBatterRuns(List<BallRecord> balls, String batterId) {
    return balls
        .where((b) => b.batterId == batterId && b.extraType != 'wide')
        .fold(0, (sum, b) => sum + b.runs);
  }

  int _getBatterBalls(List<BallRecord> balls, String batterId) {
    return balls.where((b) => b.batterId == batterId && b.extraType != 'wide').length;
  }

  int _getBowlerRuns(List<BallRecord> balls, String bowlerId) {
    // Bowler runs includes bat runs + wides + no balls (byes/legbyes are NOT bowler runs)
    return balls.where((b) => b.bowlerId == bowlerId).fold(0, (sum, b) {
      if (b.extraType == 'bye' || b.extraType == 'leg_bye') {
        return sum; // Byes and Legbyes are not conceded by bowler
      }
      return sum + b.totalRuns;
    });
  }

  int _getBowlerWickets(List<BallRecord> balls, String bowlerId) {
    // Bowler wickets do NOT include run outs
    return balls.where((b) => b.bowlerId == bowlerId && b.isWicket && b.wicketType != 'run_out').length;
  }

  String _getBowlerOvers(List<BallRecord> balls, String bowlerId) {
    final legalBalls = balls.where((b) => b.bowlerId == bowlerId && b.isLegalBall).length;
    return '${legalBalls ~/ 6}.${legalBalls % 6}';
  }
}
