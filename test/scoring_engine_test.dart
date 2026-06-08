import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:the_stat/core/storage/hive_registry.dart';
import 'package:the_stat/features/scoring/controllers/scoring_notifier.dart';

void main() {
  late ScoringNotifier notifier;

  setUpAll(() async {
    // Initialize Hive in a temporary directory for unit testing
    final tempDir = await Directory.systemTemp.createTemp('the_stat_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveRegistry.matchesBoxName);
  });

  setUp(() {
    notifier = ScoringNotifier();
    HiveRegistry.clearAll();
  });

  test('Start Match initializes state correctly', () {
    notifier.startNewMatch(
      teamA: 'Chennai Super Kings',
      teamB: 'Mumbai Indians',
      format: 'T20',
      overs: 20,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    final state = notifier.state;
    expect(state, isNotNull);
    expect(state!.teamAName, 'Chennai Super Kings');
    expect(state.teamBName, 'Mumbai Indians');
    expect(state.currentInnings, 1);
    expect(state.currentRuns, 0);
    expect(state.currentWickets, 0);
    expect(state.currentLegalBalls, 0);
    expect(state.strikerId, 'Chennai Super Kings Batter 1');
  });

  test('Record runs off bat increases score and rotates strike on odd runs', () {
    notifier.startNewMatch(
      teamA: 'CSK',
      teamB: 'MI',
      format: 'T20',
      overs: 20,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    // Ball 1: dot ball
    notifier.recordBall(runs: 0);
    expect(notifier.state!.currentRuns, 0);
    expect(notifier.state!.currentLegalBalls, 1);
    expect(notifier.state!.strikerId, 'CSK Batter 1');

    // Ball 2: 1 run (rotates strike)
    notifier.recordBall(runs: 1);
    expect(notifier.state!.currentRuns, 1);
    expect(notifier.state!.currentLegalBalls, 2);
    expect(notifier.state!.strikerId, 'CSK Batter 2');

    // Ball 3: 4 runs (boundary, does not rotate)
    notifier.recordBall(runs: 4);
    expect(notifier.state!.currentRuns, 5);
    expect(notifier.state!.currentLegalBalls, 3);
    expect(notifier.state!.strikerId, 'CSK Batter 2');
  });

  test('Extras handling (Wides & No Balls do not increment legal balls)', () {
    notifier.startNewMatch(
      teamA: 'CSK',
      teamB: 'MI',
      format: 'T20',
      overs: 20,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    // Ball 1: Wide (1 run extra, legal balls remain 0)
    notifier.recordBall(runs: 0, extraType: 'wide', extras: 1);
    expect(notifier.state!.currentRuns, 1);
    expect(notifier.state!.currentLegalBalls, 0);

    // Ball 2: No Ball (1 run penalty + 2 runs off bat = 3 runs total)
    notifier.recordBall(runs: 2, extraType: 'no_ball', extras: 1);
    expect(notifier.state!.currentRuns, 4); // 1 + 3
    expect(notifier.state!.currentLegalBalls, 0);
  });

  test('Wickets are incremented correctly', () {
    notifier.startNewMatch(
      teamA: 'CSK',
      teamB: 'MI',
      format: 'T20',
      overs: 20,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    notifier.recordBall(runs: 0, isWicket: true, wicketType: 'bowled');
    expect(notifier.state!.currentWickets, 1);
    expect(notifier.state!.currentLegalBalls, 1);
    // Striker gets replaced by next batsman
    expect(notifier.state!.strikerId, 'Batter 3');
  });

  test('Over completion rotates strike', () {
    notifier.startNewMatch(
      teamA: 'CSK',
      teamB: 'MI',
      format: 'T5',
      overs: 5,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    // Bowl 5 dot balls
    for (int i = 0; i < 5; i++) {
      notifier.recordBall(runs: 0);
    }
    expect(notifier.state!.strikerId, 'CSK Batter 1');
    expect(notifier.state!.currentLegalBalls, 5);

    // Bowl 6th dot ball (completing the over)
    notifier.recordBall(runs: 0);
    expect(notifier.state!.currentLegalBalls, 6);
    expect(notifier.state!.currentOvers, '1.0');
    // Over end rotates strike
    expect(notifier.state!.strikerId, 'CSK Batter 2');
  });

  test('Undo restores pre-ball state', () {
    notifier.startNewMatch(
      teamA: 'CSK',
      teamB: 'MI',
      format: 'T20',
      overs: 20,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    notifier.recordBall(runs: 1); // CSK Batter 1 scores 1, strike rotates to CSK Batter 2
    expect(notifier.state!.currentRuns, 1);
    expect(notifier.state!.strikerId, 'CSK Batter 2');

    notifier.undoLastBall();
    expect(notifier.state!.currentRuns, 0);
    expect(notifier.state!.strikerId, 'CSK Batter 1');
  });

  test('Innings transitions when wickets reach 10', () {
    notifier.startNewMatch(
      teamA: 'CSK',
      teamB: 'MI',
      format: 'T20',
      overs: 20,
      tossWinner: 'teamA',
      tossChoice: 'bat',
    );

    // Take 9 wickets
    for (int i = 0; i < 9; i++) {
      notifier.recordBall(runs: 0, isWicket: true, wicketType: 'bowled');
    }
    expect(notifier.state!.currentInnings, 1);
    expect(notifier.state!.currentWickets, 9);

    // Take 10th wicket (ends innings 1)
    notifier.recordBall(runs: 0, isWicket: true, wicketType: 'bowled');
    
    // State should now be in innings 2
    expect(notifier.state!.currentInnings, 2);
    expect(notifier.state!.innings1Runs, 0); // All dot wickets
    expect(notifier.state!.innings1Wickets, 10);
    expect(notifier.state!.currentRuns, 0);
    expect(notifier.state!.currentWickets, 0);
    expect(notifier.state!.strikerId, 'MI Batter 1');
  });
}
