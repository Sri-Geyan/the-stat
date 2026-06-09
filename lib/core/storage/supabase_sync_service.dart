import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/scoring/models/match_state.dart';
import 'package:flutter/foundation.dart';

class SupabaseSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> syncMatch(MatchState match) async {
    try {
      final matchMap = match.toMap();
      
      // Remove nested lists to keep the matches table purely relational
      matchMap.remove('balls');
      matchMap.remove('innings1BallHistory');
      matchMap.remove('teamAPlayers');
      matchMap.remove('teamBPlayers');
      
      // 1. Upsert the Match
      await _supabase.from('matches').upsert(matchMap);
      
      // 2. Prepare all ball records (both innings) with the match_id foreign key
      final List<Map<String, dynamic>> allBalls = [];
      
      allBalls.addAll(match.innings1BallHistory.map((ball) {
        final bMap = ball.toMap();
        bMap['match_id'] = match.id;
        return bMap;
      }));
      
      allBalls.addAll(match.balls.map((ball) {
        final bMap = ball.toMap();
        bMap['match_id'] = match.id;
        return bMap;
      }));

      // 3. Upsert Ball Records in bulk
      if (allBalls.isNotEmpty) {
        await _supabase.from('ball_records').upsert(allBalls);
      }

      debugPrint('Successfully synced match ${match.id} to Supabase');
    } catch (e) {
      debugPrint('Failed to sync match ${match.id} to Supabase: $e');
    }
  }

  static Future<void> deleteMatch(String matchId) async {
    try {
      await _supabase.from('matches').delete().eq('id', matchId);
      debugPrint('Successfully deleted match $matchId from Supabase');
    } catch (e) {
      debugPrint('Failed to delete match $matchId from Supabase: $e');
    }
  }
}
