class BallRecord {
  final String id;
  final int runs; // Runs scored from the bat
  final int extras; // Extra runs
  final String extraType; // 'wide', 'no_ball', 'bye', 'leg_bye', 'none'
  final bool isWicket;
  final String wicketType; // 'bowled', 'caught', 'run_out', 'lbw', 'stumped', 'hit_wicket', 'none'
  final String batterId;
  final String bowlerId;
  final int overIndex;
  final int ballIndex;
  final String preBallStrikerId;
  final String preBallNonStrikerId;

  BallRecord({
    required this.id,
    required this.runs,
    required this.extras,
    required this.extraType,
    required this.isWicket,
    required this.wicketType,
    required this.batterId,
    required this.bowlerId,
    required this.overIndex,
    required this.ballIndex,
    required this.preBallStrikerId,
    required this.preBallNonStrikerId,
  });

  int get totalRuns => runs + extras;

  bool get isLegalBall => extraType != 'wide' && extraType != 'no_ball';

  String get displayString {
    if (isWicket) return 'W';
    if (extraType == 'wide') return '${extras > 1 ? extras : ""}Wd';
    if (extraType == 'no_ball') return '${extras > 1 ? extras : ""}Nb';
    if (extraType == 'bye') return '${runs > 0 ? runs : ""}B';
    if (extraType == 'leg_bye') return '${runs > 0 ? runs : ""}Lb';
    return runs.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'runs': runs,
      'extras': extras,
      'extraType': extraType,
      'isWicket': isWicket,
      'wicketType': wicketType,
      'batterId': batterId,
      'bowlerId': bowlerId,
      'overIndex': overIndex,
      'ballIndex': ballIndex,
      'preBallStrikerId': preBallStrikerId,
      'preBallNonStrikerId': preBallNonStrikerId,
    };
  }

  factory BallRecord.fromMap(Map<dynamic, dynamic> map) {
    return BallRecord(
      id: map['id'] ?? '',
      runs: map['runs'] ?? 0,
      extras: map['extras'] ?? 0,
      extraType: map['extraType'] ?? 'none',
      isWicket: map['isWicket'] ?? false,
      wicketType: map['wicketType'] ?? 'none',
      batterId: map['batterId'] ?? '',
      bowlerId: map['bowlerId'] ?? '',
      overIndex: map['overIndex'] ?? 0,
      ballIndex: map['ballIndex'] ?? 0,
      preBallStrikerId: map['preBallStrikerId'] ?? '',
      preBallNonStrikerId: map['preBallNonStrikerId'] ?? '',
    );
  }
}
