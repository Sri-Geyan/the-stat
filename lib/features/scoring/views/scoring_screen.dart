import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../controllers/scoring_notifier.dart';
import '../models/ball_record.dart';
import '../models/match_state.dart';
import '../../scorecard/views/scorecard_screen.dart';
import '../../teams/models/team_model.dart';

class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({super.key});

  bool _isFreeHitActive(MatchState match) {
    if (match.balls.isEmpty) return false;
    return match.balls.last.extraType == 'no_ball';
  }

  void _showWicketDialog(BuildContext context, WidgetRef ref, MatchState match) {
    final freeHit = _isFreeHitActive(match);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryGreen,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.black, width: 3),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISMISSAL TYPE',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryYellow,
                    ),
              ),
              if (freeHit)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    '⚠️ FREE HIT ACTIVE - ONLY RUN OUT ALLOWED',
                    style: TextStyle(color: AppColors.primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!freeHit) ...[
                _buildWicketOption(context, ref, 'Bowled'),
                _buildWicketOption(context, ref, 'Caught'),
                _buildWicketOption(context, ref, 'LBW'),
              ],
              _buildWicketOption(context, ref, 'Run Out'),
              if (!freeHit) ...[
                _buildWicketOption(context, ref, 'Stumped'),
                _buildWicketOption(context, ref, 'Hit Wicket'),
              ],
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRadio(
                        label: 'FREE HIT',
                        selected: extraType == 'free_hit',
                        onTap: () => setDialogState(() => extraType = 'free_hit'),
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
                        runsVal = extraRuns - 1;
                        extrasVal = 1;
                      } else if (extraType == 'wide') {
                        runsVal = 0;
                        extrasVal = extraRuns;
                      } else if (extraType == 'free_hit') {
                        runsVal = extraRuns;
                        extrasVal = 0;
                      } else {
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

  void _showChooseNextBatterDialog(BuildContext context, WidgetRef ref, MatchState match) {
    final isTeamABatting = (match.currentInnings == 1 &&
                ((match.tossWinner == 'teamA' && match.tossChoice == 'bat') ||
                 (match.tossWinner == 'teamB' && match.tossChoice == 'bowl'))) ||
            (match.currentInnings == 2 &&
                !((match.tossWinner == 'teamA' && match.tossChoice == 'bat') ||
                  (match.tossWinner == 'teamB' && match.tossChoice == 'bowl')));
    final squad = isTeamABatting ? match.teamAPlayers : match.teamBPlayers;

    final dismissed = match.balls
        .where((b) => b.isWicket)
        .map((b) => b.batterId)
        .toSet();

    final remaining = squad.where((name) {
      return name != match.nonStrikerId &&
             name != match.strikerId &&
             !dismissed.contains(name);
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final textCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.primaryGreen,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.black, width: 3),
              ),
              title: Text(
                'CHOOSE NEXT BATTER',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (remaining.isNotEmpty) ...[
                      const Text(
                        'SELECT FROM PLAYING SQUAD:',
                        style: TextStyle(color: AppColors.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...remaining.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(scoringProvider.notifier).chooseNextBatter(name);
                              Navigator.pop(ctx);
                            },
                            child: Text(name.toUpperCase()),
                          ),
                        );
                      }),
                      const Divider(color: AppColors.black, height: 20),
                    ],
                    const Text(
                      'ADD GUEST / OTHER BATTER:',
                      style: TextStyle(color: AppColors.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
                      ),
                      child: TextField(
                        controller: textCtrl,
                        style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
                        decoration: const InputDecoration(
                          hintText: 'Enter batter name',
                          hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow),
                      onPressed: () {
                        final name = textCtrl.text.trim();
                        if (name.isNotEmpty) {
                          ref.read(scoringProvider.notifier).chooseNextBatter(name);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('SUBMIT GUEST'),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showChooseNextBowlerDialog(BuildContext context, WidgetRef ref, MatchState match) {
    final isTeamABatting = (match.currentInnings == 1 &&
                ((match.tossWinner == 'teamA' && match.tossChoice == 'bat') ||
                 (match.tossWinner == 'teamB' && match.tossChoice == 'bowl'))) ||
            (match.currentInnings == 2 &&
                !((match.tossWinner == 'teamA' && match.tossChoice == 'bat') ||
                  (match.tossWinner == 'teamB' && match.tossChoice == 'bowl')));
    final squad = isTeamABatting ? match.teamBPlayers : match.teamAPlayers;

    final lastBowler = match.balls.isNotEmpty ? match.balls.last.bowlerId : '';
    final remaining = squad.where((name) => name != lastBowler).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final textCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.primaryGreen,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.black, width: 3),
              ),
              title: Text(
                'CHOOSE NEXT BOWLER',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (remaining.isNotEmpty) ...[
                      const Text(
                        'SELECT FROM PLAYING SQUAD (EXCLUDING PREVIOUS):',
                        style: TextStyle(color: AppColors.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...remaining.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(scoringProvider.notifier).changeBowler(name);
                              Navigator.pop(ctx);
                            },
                            child: Text(name.toUpperCase()),
                          ),
                        );
                      }),
                      const Divider(color: AppColors.black, height: 20),
                    ],
                    const Text(
                      'ADD GUEST / OTHER BOWLER:',
                      style: TextStyle(color: AppColors.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
                      ),
                      child: TextField(
                        controller: textCtrl,
                        style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
                        decoration: const InputDecoration(
                          hintText: 'Enter bowler name',
                          hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow),
                      onPressed: () {
                        final name = textCtrl.text.trim();
                        if (name.isNotEmpty) {
                          ref.read(scoringProvider.notifier).changeBowler(name);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('SUBMIT GUEST'),
                    ),
                  ],
                ),
              ),
            );
          }
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

    ref.listen<MatchState?>(scoringProvider, (previous, next) {
      if (next == null || next.status == 'completed') return;

      if (next.strikerId == 'Select Batter' && (previous == null || previous.strikerId != 'Select Batter')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showChooseNextBatterDialog(context, ref, next);
        });
      }

      if (next.bowlerId == 'Select Bowler' && (previous == null || previous.bowlerId != 'Select Bowler')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showChooseNextBowlerDialog(context, ref, next);
        });
      }
    });

    final currentBalls = match.balls;
    final currentOversCount = match.currentLegalBalls;
    final currentOverIndex = currentOversCount ~/ 6;
    final overBalls = currentBalls.where((b) => b.overIndex == currentOverIndex).toList();

    final runs = match.currentRuns;
    final wickets = match.currentWickets;
    final oversStr = match.currentOvers;
    final crr = match.currentLegalBalls > 0 
        ? (runs / (match.currentLegalBalls / 6)).toStringAsFixed(2) 
        : '0.00';

    final isSelectionActive = match.strikerId == 'Select Batter' || match.bowlerId == 'Select Bowler';
    final isLive = match.status == 'live' && !isSelectionActive;

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
            onPressed: () => _showChooseNextBowlerDialog(context, ref, match),
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
                  Text(
                    '${match.teamAName.toUpperCase()} vs ${match.teamBName.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),

                  if (_isFreeHitActive(match)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.red,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: AppColors.primaryYellow, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '⚠️ FREE HIT ACTIVE',
                            style: TextStyle(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isSelectionActive) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.primaryYellow,
                      child: Text(
                        match.strikerId == 'Select Batter'
                            ? '🏏 DISMISSAL RECORDED. TAP ON "Select Batter" TO CHOOSE NEXT BATSMAN.'
                            : '⚾ OVER COMPLETED. TAP ON "Select Bowler" TO CHOOSE NEXT BOWLER.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ],

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

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  stats: match.strikerId == 'Select Batter'
                                      ? 'TAP TO CHOOSE'
                                      : '${_getBatterRuns(currentBalls, match.strikerId)} (${_getBatterBalls(currentBalls, match.strikerId)})',
                                  onTap: match.strikerId == 'Select Batter'
                                      ? () => _showChooseNextBatterDialog(context, ref, match)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                _buildPlayerRow(
                                  name: match.nonStrikerId,
                                  isStriker: false,
                                  stats: match.nonStrikerId == 'Select Batter'
                                      ? 'TAP TO CHOOSE'
                                      : '${_getBatterRuns(currentBalls, match.nonStrikerId)} (${_getBatterBalls(currentBalls, match.nonStrikerId)})',
                                  onTap: match.nonStrikerId == 'Select Batter'
                                      ? () => _showChooseNextBatterDialog(context, ref, match)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                  stats: match.bowlerId == 'Select Bowler'
                                      ? 'TAP TO CHOOSE'
                                      : '${_getBowlerWickets(currentBalls, match.bowlerId)}/${_getBowlerRuns(currentBalls, match.bowlerId)} (${_getBowlerOvers(currentBalls, match.bowlerId)})',
                                  onTap: () => _showChooseNextBowlerDialog(context, ref, match),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  if (match.status == 'live') ...[
                    Row(
                      children: [
                        _buildScoringKey(context, ref, '0', 0, enabled: !isSelectionActive),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '1', 1, enabled: !isSelectionActive),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '2', 2, enabled: !isSelectionActive),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '3', 3, enabled: !isSelectionActive),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildScoringKey(context, ref, '4', 4, highlight: true, enabled: !isSelectionActive),
                        const SizedBox(width: 10),
                        _buildScoringKey(context, ref, '6', 6, highlight: true, enabled: !isSelectionActive),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: isLive ? () => _showExtraDialog(context, ref) : null,
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isLive ? AppColors.black : const Color(0xFF333333),
                                border: Border.all(color: AppColors.black, width: 2),
                              ),
                              child: Text(
                                'EXTRA',
                                style: TextStyle(
                                  color: isLive ? AppColors.white : const Color(0xFF666666),
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
                            onTap: isLive ? () => _showWicketDialog(context, ref, match) : null,
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isLive ? AppColors.red : const Color(0xFF333333),
                                border: Border.all(color: AppColors.black, width: 2),
                              ),
                              child: Text(
                                'WICKET',
                                style: TextStyle(
                                  color: isLive ? AppColors.white : const Color(0xFF666666),
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
                          onPressed: isLive ? () {
                            ref.read(scoringProvider.notifier).switchStriker();
                          } : null,
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
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
      ),
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
    bool enabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: enabled
            ? () {
                ref.read(scoringProvider.notifier).recordBall(runs: runs);
              }
            : null,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? (highlight ? AppColors.primaryYellow : AppColors.black)
                : const Color(0xFF333333),
            border: Border.all(color: AppColors.black, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? (highlight ? AppColors.black : AppColors.white)
                  : const Color(0xFF666666),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
        ),
      ),
    );
  }

  int _getBatterRuns(List<BallRecord> balls, String batterId) {
    return balls
        .where((b) => b.batterId == batterId && b.extraType != 'wide')
        .fold(0, (sum, b) => sum + b.runs);
  }

  int _getBatterBalls(List<BallRecord> balls, String batterId) {
    return balls.where((b) => b.batterId == batterId && b.extraType != 'wide').length;
  }

  int _getBowlerRuns(List<BallRecord> balls, String bowlerId) {
    return balls.where((b) => b.bowlerId == bowlerId).fold(0, (sum, b) {
      if (b.extraType == 'bye' || b.extraType == 'leg_bye') {
        return sum;
      }
      return sum + b.totalRuns;
    });
  }

  int _getBowlerWickets(List<BallRecord> balls, String bowlerId) {
    return balls.where((b) => b.bowlerId == bowlerId && b.isWicket && b.wicketType != 'run_out').length;
  }

  String _getBowlerOvers(List<BallRecord> balls, String bowlerId) {
    final legalBalls = balls.where((b) => b.bowlerId == bowlerId && b.isLegalBall).length;
    return '${legalBalls ~/ 6}.${legalBalls % 6}';
  }
}
