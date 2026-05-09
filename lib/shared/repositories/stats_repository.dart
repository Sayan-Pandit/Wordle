import 'package:wordle/services/storage_service.dart';
import 'package:wordle/models/game_mode.dart';

abstract class IStatsRepository {
  Future<Map<String, dynamic>> getUserStats();
  Future<void> saveGameResult({
    required bool isWin,
    required GameMode mode,
    required int attempts,
    int? level,
  });
}

class StatsRepository implements IStatsRepository {
  @override
  Future<Map<String, dynamic>> getUserStats() => StorageService.getLocalStats();

  @override
  Future<void> saveGameResult({
    required bool isWin,
    required GameMode mode,
    required int attempts,
    int? level,
  }) {
    return StorageService.updateUserStats(
      isWin: isWin,
      points: isWin ? (7 - attempts) * 10 : 0, // Points logic encapsulated
      mode: mode,
      attempts: attempts,
      playedLevel: level,
    );
  }
}
