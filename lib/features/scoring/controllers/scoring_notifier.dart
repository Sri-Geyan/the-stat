import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/hive_registry.dart';
import '../models/ball_record.dart';
import '../models/match_state.dart';

class ScoringNotifier extends StateNotifier<MatchState?> {
  ScoringNotifier() : super(null) {
    _loadActiveMatchIfAny();
  }

  void _loadActiveMatchIfAny() {
    final matches = HiveRegistry.getAllMatches();
    final liveMatches = matches.where((m) => m.status == 'live');
    if (liveMatches.isNotEmpty) {
      state = liveMatches.first;
    }
  }

  void startNewMatch({
    required String teamA,
    required String teamB,
    required String format,
    required int overs,
    required String tossWinner,
    required String tossChoice,
  }) {
    startNewMatchWithPlayers(
      teamA: teamA, teamB: teamB, format: format, overs: overs,
      tossWinner: tossWinner, tossChoice: tossChoice,
      striker: '$teamA Batter 1',
      nonStriker: '$teamA Batter 2',
      bowler: '$teamB Bowler 1',
    );
  }

  void startNewMatchWithPlayers({
    required String teamA,
    required String teamB,
    required String format,
    required int overs,
    required String tossWinner,
    required String tossChoice,
    required String striker,
    required String nonStriker,
    required String bowler,
  }) {
    final id = const Uuid().v4();

    final newMatch = MatchState(
      id: id,
      teamAName: teamA,
      teamBName: teamB,
      format: format,
      oversLimit: overs,
      tossWinner: tossWinner,
      tossChoice: tossChoice,
      currentInnings: 1,
      status: 'live',
      innings1Runs: 0,
      innings1Wickets: 0,
      innings1Balls: 0,
      innings1BallHistory: [],
      strikerId: striker,
      nonStrikerId: nonStriker,
      bowlerId: bowler,
      balls: [],
      winner: '',
      margin: '',
    );

    state = newMatch;
    HiveRegistry.saveMatch(newMatch);
  }

  void loadMatch(String id) {
    final match = HiveRegistry.getMatch(id);
    if (match != null) {
      state = match;
    }
  }

  void recordBall({
    required int runs,
    String extraType = 'none',
    int extras = 0,
    bool isWicket = false,
    String wicketType = 'none',
  }) {
    final current = state;
    if (current == null || current.status == 'completed') return;

    final preBallStriker = current.strikerId;
    final preBallNonStriker = current.nonStrikerId;

    final legalBallsSoFar = current.currentLegalBalls;
    final overIndex = legalBallsSoFar ~/ 6;
    final ballIndex = (legalBallsSoFar % 6) + 1;

    final ball = BallRecord(
      id: const Uuid().v4(),
      runs: runs,
      extras: extras,
      extraType: extraType,
      isWicket: isWicket,
      wicketType: wicketType,
      batterId: current.strikerId,
      bowlerId: current.bowlerId,
      overIndex: overIndex,
      ballIndex: ballIndex,
      preBallStrikerId: preBallStriker,
      preBallNonStrikerId: preBallNonStriker,
    );

    final updatedBalls = [...current.balls, ball];

    // Determine state variables
    String nextStriker = preBallStriker;
    String nextNonStriker = preBallNonStriker;
    int nextInnings = current.currentInnings;
    String nextStatus = current.status;
    int nextInnings1Runs = current.innings1Runs;
    int nextInnings1Wickets = current.innings1Wickets;
    int nextInnings1Balls = current.innings1Balls;
    List<BallRecord> nextInnings1BallHistory = current.innings1BallHistory;
    String nextWinner = current.winner;
    String nextMargin = current.margin;

    // 1. Wicket handling
    int wicketsCount = updatedBalls.where((b) => b.isWicket).length;
    if (isWicket) {
      if (wicketsCount < 10) {
        // Replace the striker with a new batsman (mock ID/name)
        nextStriker = 'Batter ${wicketsCount + 2}';
      }
    }

    // 2. Runs rotation
    // Batters swap ends on odd runs run (runs off bat or byes/leg-byes)
    final runsToRotate = runs + (extraType == 'bye' || extraType == 'leg_bye' ? extras : 0);
    if (!isWicket && runsToRotate % 2 == 1) {
      final temp = nextStriker;
      nextStriker = nextNonStriker;
      nextNonStriker = temp;
    }

    // 3. Over ended? (Legal balls check)
    final totalLegalBalls = updatedBalls.where((b) => b.isLegalBall).length;
    final isOverFinished = (totalLegalBalls > 0) && (totalLegalBalls % 6 == 0);
    if (isOverFinished && wicketsCount < 10 && totalLegalBalls < (current.oversLimit * 6)) {
      // Swapping striker at the end of the over
      final temp = nextStriker;
      nextStriker = nextNonStriker;
      nextNonStriker = temp;
    }

    // Better logic for chase completion:
    bool isChaseCompleted = false;
    if (current.currentInnings == 2) {
      final totalInnings2Runs = updatedBalls.fold(0, (sum, b) => sum + b.totalRuns);
      if (totalInnings2Runs > current.innings1Runs) {
        isChaseCompleted = true;
      }
    }

    final isLimitReached = wicketsCount >= 10 || totalLegalBalls >= (current.oversLimit * 6) || isChaseCompleted;

    if (isLimitReached) {
      if (current.currentInnings == 1) {
        // Transition to Innings 2
        nextInnings = 2;
        nextInnings1Runs = updatedBalls.fold(0, (sum, b) => sum + b.totalRuns);
        nextInnings1Wickets = wicketsCount;
        nextInnings1Balls = totalLegalBalls;
        nextInnings1BallHistory = updatedBalls;
        
        // Reset for Innings 2
        final battingTeamInnings2 = current.tossWinner == 'teamA' 
            ? (current.tossChoice == 'bat' ? current.teamBName : current.teamAName)
            : (current.tossChoice == 'bat' ? current.teamAName : current.teamBName);

        final bowlingTeamInnings2 = battingTeamInnings2 == current.teamAName ? current.teamBName : current.teamAName;

        nextStriker = '$battingTeamInnings2 Batter 1';
        nextNonStriker = '$battingTeamInnings2 Batter 2';
        state = current.copyWith(
          currentInnings: nextInnings,
          innings1Runs: nextInnings1Runs,
          innings1Wickets: nextInnings1Wickets,
          innings1Balls: nextInnings1Balls,
          innings1BallHistory: nextInnings1BallHistory,
          balls: [],
          strikerId: nextStriker,
          nonStrikerId: nextNonStriker,
          bowlerId: '$bowlingTeamInnings2 Bowler 1',
        );
        HiveRegistry.saveMatch(state!);
        return;
      } else {
        // Innings 2 completed -> Match completed!
        nextStatus = 'completed';
        final totalInnings2Runs = updatedBalls.fold(0, (sum, b) => sum + b.totalRuns);
        final battingTeamInnings2 = current.tossWinner == 'teamA' 
            ? (current.tossChoice == 'bat' ? current.teamBName : current.teamAName)
            : (current.tossChoice == 'bat' ? current.teamAName : current.teamBName);
        final bowlingTeamInnings2 = battingTeamInnings2 == current.teamAName ? current.teamBName : current.teamAName;

        if (totalInnings2Runs > current.innings1Runs) {
          nextWinner = battingTeamInnings2;
          nextMargin = '${10 - wicketsCount} wickets';
        } else if (totalInnings2Runs < current.innings1Runs) {
          nextWinner = bowlingTeamInnings2;
          nextMargin = '${current.innings1Runs - totalInnings2Runs} runs';
        } else {
          nextWinner = 'Tie';
          nextMargin = 'Scores level';
        }
      }
    }

    final updatedState = current.copyWith(
      balls: updatedBalls,
      strikerId: nextStriker,
      nonStrikerId: nextNonStriker,
      status: nextStatus,
      winner: nextWinner,
      margin: nextMargin,
    );

    state = updatedState;
    HiveRegistry.saveMatch(updatedState);
  }

  void undoLastBall() {
    final current = state;
    if (current == null) return;

    if (current.balls.isEmpty) {
      // If innings 2 and empty, restore innings 1!
      if (current.currentInnings == 2 && current.innings1BallHistory.isNotEmpty) {
        final restoredState = current.copyWith(
          currentInnings: 1,
          balls: [...current.innings1BallHistory],
          innings1Runs: 0,
          innings1Wickets: 0,
          innings1Balls: 0,
          innings1BallHistory: [],
          status: 'live',
        );
        // Now pop the last ball of the restored innings 1
        state = restoredState;
        undoLastBall();
        return;
      }
      return;
    }

    final updatedBalls = [...current.balls];
    final popped = updatedBalls.removeLast();

    final updatedState = current.copyWith(
      balls: updatedBalls,
      strikerId: popped.preBallStrikerId,
      nonStrikerId: popped.preBallNonStrikerId,
      status: 'live', // In case it was completed
      winner: '',
      margin: '',
    );

    state = updatedState;
    HiveRegistry.saveMatch(updatedState);
  }

  void switchStriker() {
    final current = state;
    if (current == null) return;

    final updatedState = current.copyWith(
      strikerId: current.nonStrikerId,
      nonStrikerId: current.strikerId,
    );

    state = updatedState;
    HiveRegistry.saveMatch(updatedState);
  }

  void changeBowler(String newBowler) {
    final current = state;
    if (current == null) return;

    final updatedState = current.copyWith(bowlerId: newBowler);
    state = updatedState;
    HiveRegistry.saveMatch(updatedState);
  }

  void clearMatch() {
    state = null;
  }
}

final scoringProvider = StateNotifierProvider<ScoringNotifier, MatchState?>((ref) {
  return ScoringNotifier();
});
