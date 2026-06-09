import 'ball_record.dart';

class MatchState {
  final String id;
  final String teamAName;
  final String teamBName;
  final String format; // 'Gully T5', 'T20', 'ODI', etc.
  final int oversLimit;
  
  final String tossWinner; // 'teamA' or 'teamB'
  final String tossChoice; // 'bat' or 'bowl'
  
  final int currentInnings; // 1 or 2
  final String status; // 'live', 'completed'
  
  // Innings 1 live state (saved once Innings 1 ends)
  final int innings1Runs;
  final int innings1Wickets;
  final int innings1Balls;
  final List<BallRecord> innings1BallHistory;
  
  // Current Innings details
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  
  // Ball-by-ball history of the current active innings
  final List<BallRecord> balls;
  
  final String winner;
  final String margin;

  final List<String> teamAPlayers;
  final List<String> teamBPlayers;

  MatchState({
    required this.id,
    required this.teamAName,
    required this.teamBName,
    required this.format,
    required this.oversLimit,
    required this.tossWinner,
    required this.tossChoice,
    required this.currentInnings,
    required this.status,
    required this.innings1Runs,
    required this.innings1Wickets,
    required this.innings1Balls,
    required this.innings1BallHistory,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    required this.balls,
    required this.winner,
    required this.margin,
    required this.teamAPlayers,
    required this.teamBPlayers,
  });

  // Derived getters for current active innings
  int get currentRuns {
    return balls.fold(0, (sum, ball) => sum + ball.totalRuns);
  }

  int get currentWickets {
    return balls.where((ball) => ball.isWicket).length;
  }

  int get currentLegalBalls {
    return balls.where((ball) => ball.isLegalBall).length;
  }

  String get currentOvers {
    int legal = currentLegalBalls;
    int overs = legal ~/ 6;
    int ballsInOver = legal % 6;
    return '$overs.$ballsInOver';
  }

  bool get isInningsOver {
    return currentWickets >= 10 || currentLegalBalls >= (oversLimit * 6);
  }

  MatchState copyWith({
    String? id,
    String? teamAName,
    String? teamBName,
    String? format,
    int? oversLimit,
    String? tossWinner,
    String? tossChoice,
    int? currentInnings,
    String? status,
    int? innings1Runs,
    int? innings1Wickets,
    int? innings1Balls,
    List<BallRecord>? innings1BallHistory,
    String? strikerId,
    String? nonStrikerId,
    String? bowlerId,
    List<BallRecord>? balls,
    String? winner,
    String? margin,
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
  }) {
    return MatchState(
      id: id ?? this.id,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      format: format ?? this.format,
      oversLimit: oversLimit ?? this.oversLimit,
      tossWinner: tossWinner ?? this.tossWinner,
      tossChoice: tossChoice ?? this.tossChoice,
      currentInnings: currentInnings ?? this.currentInnings,
      status: status ?? this.status,
      innings1Runs: innings1Runs ?? this.innings1Runs,
      innings1Wickets: innings1Wickets ?? this.innings1Wickets,
      innings1Balls: innings1Balls ?? this.innings1Balls,
      innings1BallHistory: innings1BallHistory ?? this.innings1BallHistory,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      bowlerId: bowlerId ?? this.bowlerId,
      balls: balls ?? this.balls,
      winner: winner ?? this.winner,
      margin: margin ?? this.margin,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamAName': teamAName,
      'teamBName': teamBName,
      'format': format,
      'oversLimit': oversLimit,
      'tossWinner': tossWinner,
      'tossChoice': tossChoice,
      'currentInnings': currentInnings,
      'status': status,
      'innings1Runs': innings1Runs,
      'innings1Wickets': innings1Wickets,
      'innings1Balls': innings1Balls,
      'innings1BallHistory': innings1BallHistory.map((b) => b.toMap()).toList(),
      'strikerId': strikerId,
      'nonStrikerId': nonStrikerId,
      'bowlerId': bowlerId,
      'balls': balls.map((b) => b.toMap()).toList(),
      'winner': winner,
      'margin': margin,
      'teamAPlayers': teamAPlayers,
      'teamBPlayers': teamBPlayers,
    };
  }

  factory MatchState.fromMap(Map<dynamic, dynamic> map) {
    return MatchState(
      id: map['id'] ?? '',
      teamAName: map['teamAName'] ?? 'Team A',
      teamBName: map['teamBName'] ?? 'Team B',
      format: map['format'] ?? 'T20',
      oversLimit: map['oversLimit'] ?? 20,
      tossWinner: map['tossWinner'] ?? 'teamA',
      tossChoice: map['tossChoice'] ?? 'bat',
      currentInnings: map['currentInnings'] ?? 1,
      status: map['status'] ?? 'live',
      innings1Runs: map['innings1Runs'] ?? 0,
      innings1Wickets: map['innings1Wickets'] ?? 0,
      innings1Balls: map['innings1Balls'] ?? 0,
      innings1BallHistory: (map['innings1BallHistory'] as List? ?? [])
          .map((b) => BallRecord.fromMap(Map<dynamic, dynamic>.from(b)))
          .toList(),
      strikerId: map['strikerId'] ?? 'Striker',
      nonStrikerId: map['nonStrikerId'] ?? 'Non-Striker',
      bowlerId: map['bowlerId'] ?? 'Bowler',
      balls: (map['balls'] as List? ?? [])
          .map((b) => BallRecord.fromMap(Map<dynamic, dynamic>.from(b)))
          .toList(),
      winner: map['winner'] ?? '',
      margin: map['margin'] ?? '',
      teamAPlayers: (map['teamAPlayers'] as List? ?? []).map((e) => e.toString()).toList(),
      teamBPlayers: (map['teamBPlayers'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
