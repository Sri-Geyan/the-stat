import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/team_model.dart';

final teamNotifierProvider =
    AsyncNotifierProvider<TeamNotifier, List<TeamModel>>(TeamNotifier.new);

final allTeamsProvider = FutureProvider<List<TeamModel>>((ref) async {
  try {
    final response = await Supabase.instance.client.from('teams').select().order('name');
    return response.map((t) => TeamModel.fromMap(t)).toList();
  } catch (e) {
    debugPrint('Failed to fetch all registered teams: $e');
    return [];
  }
});

class TeamNotifier extends AsyncNotifier<List<TeamModel>> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<TeamModel>> build() async {
    return fetchMyTeams();
  }

  /// Fetch all teams the current user belongs to
  Future<List<TeamModel>> fetchMyTeams() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get team IDs the user is a member of
      final memberRows = await _supabase
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId);

      final teamIds =
          memberRows.map((r) => r['team_id'] as String).toList();

      if (teamIds.isEmpty) return [];

      // Get team details
      final teamRows =
          await _supabase.from('teams').select().inFilter('id', teamIds);

      // Get all members for these teams
      final allMembers = await _supabase
          .from('team_members')
          .select()
          .inFilter('team_id', teamIds);

      final membersByTeam = <String, List<TeamMember>>{};
      for (final m in allMembers) {
        final teamId = m['team_id'] as String;
        membersByTeam.putIfAbsent(teamId, () => []);
        membersByTeam[teamId]!.add(TeamMember.fromMap(m));
      }

      return teamRows.map((t) {
        final teamId = t['id'] as String;
        return TeamModel.fromMap(t, members: membersByTeam[teamId] ?? []);
      }).toList();
    } catch (e) {
      debugPrint('Failed to fetch teams: $e');
      return [];
    }
  }

  /// Create a new team
  Future<TeamModel?> createTeam(String name) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Not authenticated';

      final inviteCode = _generateInviteCode();
      final userName = user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email ??
          'Unknown';

      // Insert team
      final teamRow = await _supabase.from('teams').insert({
        'name': name,
        'owner_id': user.id,
        'owner_name': userName,
        'invite_code': inviteCode,
      }).select().single();

      final teamId = teamRow['id'] as String;

      // Add creator as owner member
      await _supabase.from('team_members').insert({
        'team_id': teamId,
        'user_id': user.id,
        'user_name': userName,
        'user_email': user.email ?? '',
        'role': 'owner',
      });

      // Refresh state
      state = AsyncData(await fetchMyTeams());
      return TeamModel.fromMap(teamRow);
    } catch (e) {
      debugPrint('Failed to create team: $e');
      return null;
    }
  }

  /// Join a team using an invite code
  Future<bool> joinTeamByCode(String code) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Not authenticated';

      // Look up the team by invite code
      final teamRows = await _supabase
          .from('teams')
          .select()
          .eq('invite_code', code.trim().toUpperCase());

      if (teamRows.isEmpty) return false;

      final team = teamRows.first;
      final teamId = team['id'] as String;

      // Check if already a member
      final existing = await _supabase
          .from('team_members')
          .select('id')
          .eq('team_id', teamId)
          .eq('user_id', user.id);

      if (existing.isNotEmpty) return true; // Already a member

      final userName = user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email ??
          'Unknown';

      await _supabase.from('team_members').insert({
        'team_id': teamId,
        'user_id': user.id,
        'user_name': userName,
        'user_email': user.email ?? '',
        'role': 'player',
      });

      // Refresh state
      state = AsyncData(await fetchMyTeams());
      return true;
    } catch (e) {
      debugPrint('Failed to join team: $e');
      return false;
    }
  }

  /// Remove a player from a team (owner only)
  Future<bool> removePlayer(String teamId, String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', userId);

      // Refresh state
      state = AsyncData(await fetchMyTeams());
      return true;
    } catch (e) {
      debugPrint('Failed to remove player: $e');
      return false;
    }
  }

  /// Delete a team (owner only)
  Future<bool> deleteTeam(String teamId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Delete members first
      await _supabase.from('team_members').delete().eq('team_id', teamId);
      // Delete the team
      await _supabase.from('teams').delete().eq('id', teamId).eq('owner_id', currentUserId);

      // Refresh state
      state = AsyncData(await fetchMyTeams());
      ref.invalidate(allTeamsProvider);
      return true;
    } catch (e) {
      debugPrint('Failed to delete team: $e');
      return false;
    }
  }

  /// Refresh teams
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await fetchMyTeams());
    ref.invalidate(allTeamsProvider);
  }

  /// Generate a short random invite code (6 chars, uppercase alphanumeric)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
