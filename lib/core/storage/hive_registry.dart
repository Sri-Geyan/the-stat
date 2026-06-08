import 'package:hive_flutter/hive_flutter.dart';
import '../../features/scoring/models/match_state.dart';
import 'supabase_sync_service.dart';

class HiveRegistry {
  static const String matchesBoxName = 'matches';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(matchesBoxName);
  }

  static Box get matchesBox => Hive.box(matchesBoxName);

  static Future<void> saveMatch(MatchState match) async {
    await matchesBox.put(match.id, match.toMap());
    // Fire-and-forget background sync to Supabase
    SupabaseSyncService.syncMatch(match);
  }

  static MatchState? getMatch(String id) {
    final data = matchesBox.get(id);
    if (data == null) return null;
    return MatchState.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static List<MatchState> getAllMatches() {
    return matchesBox.values.map((data) {
      return MatchState.fromMap(Map<dynamic, dynamic>.from(data));
    }).toList();
  }

  static Future<void> deleteMatch(String id) async {
    await matchesBox.delete(id);
  }

  static Future<void> clearAll() async {
    await matchesBox.clear();
  }
}
