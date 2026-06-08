class TeamModel {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String inviteCode;
  final String createdAt;
  final List<TeamMember> members;

  TeamModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.inviteCode,
    required this.createdAt,
    this.members = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'invite_code': inviteCode,
      'created_at': createdAt,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map, {List<TeamMember>? members}) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['owner_id'] ?? '',
      ownerName: map['owner_name'] ?? '',
      inviteCode: map['invite_code'] ?? '',
      createdAt: map['created_at'] ?? '',
      members: members ?? [],
    );
  }
}

class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final String userName;
  final String userEmail;
  final String role; // 'owner' or 'player'
  final String joinedAt;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'role': role,
      'joined_at': joinedAt,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] ?? '',
      teamId: map['team_id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      role: map['role'] ?? 'player',
      joinedAt: map['joined_at'] ?? '',
    );
  }
}
