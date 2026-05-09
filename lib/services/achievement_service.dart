import 'dart:convert';
import 'package:wordle/models/achievement.dart';

class AchievementService {
  static List<BadgeModel> getUnlockedBadges(Map<String, dynamic> stats) {
    final daily = stats['daily'] ?? {};
    final level = stats['level'] ?? {};
    final int xp = stats['xp'] ?? 0;
    
    final int totalWins = (daily['wins'] ?? 0) + (level['wins'] ?? 0);
    final int maxStreak = daily['maxStreak'] ?? 0;
    
    // Check for Genius (1-guess win)
    bool hasOneGuessWin = false;
    try {
      final dist = jsonDecode(level['guessDistribution'] ?? '{}');
      if (dist['1'] != null && dist['1'] > 0) hasOneGuessWin = true;
    } catch (e) {}

    return [
      BadgeModel(
        id: '1', 
        name: 'First Win', 
        description: 'Solved your first Wordle', 
        icon: '🏆', 
        rarity: BadgeRarity.common, 
        isUnlocked: totalWins > 0,
        currentProgress: totalWins.toDouble(),
        targetValue: 1,
      ),
      BadgeModel(
        id: '2', 
        name: 'Streak 7', 
        description: '7 day daily streak', 
        icon: '🔥', 
        rarity: BadgeRarity.rare, 
        isUnlocked: maxStreak >= 7,
        currentProgress: maxStreak.toDouble(),
        targetValue: 7,
      ),
      BadgeModel(
        id: '3', 
        name: 'Genius', 
        description: 'Solved on first attempt', 
        icon: '🧠', 
        rarity: BadgeRarity.epic, 
        isUnlocked: hasOneGuessWin,
        currentProgress: hasOneGuessWin ? 1 : 0,
        targetValue: 1,
      ),
      BadgeModel(
        id: '4', 
        name: 'Grandmaster', 
        description: 'Reached 5000 XP', 
        icon: '👑', 
        rarity: BadgeRarity.legendary, 
        isUnlocked: xp >= 5000,
        currentProgress: xp.toDouble(),
        targetValue: 5000,
      ),
    ];
  }

  static Map<String, String> calculateLiveMetrics(Map<String, dynamic> stats) {
    final daily = stats['daily'] ?? {};
    final level = stats['level'] ?? {};
    final int xp = stats['xp'] ?? 0;

    final int wins = (daily['wins'] ?? 0) + (level['wins'] ?? 0);
    // Efficiency Calculation (Average Attempts)
    Map<String, dynamic> levelDist = {};
    try {
      final rawDist = level['guessDistribution'];
      levelDist = jsonDecode(rawDist is String ? rawDist : '{}');
    } catch (e) {}
    
    double totalAttempts = 0;
    int winCount = 0;
    levelDist.forEach((key, value) {
      final count = value as int;
      totalAttempts += (int.parse(key) * count);
      winCount += count;
    });

    double avgAttempts = winCount > 0 ? totalAttempts / winCount : 4.0;
    
    // IQ Calculation (Refined 'Believable' formula + Efficiency Bonus)
    // Base 100 + (0.5 per win) + (10% of win rate) + (streak bonus) - (Efficiency Penalty)
    final dailyStats = stats['daily'] ?? {};
    final int streak = dailyStats['currentStreak'] ?? 0;
    
    final int total = (daily['totalGames'] ?? 0) + (level['totalGames'] ?? 0);
    double winRate = total > 0 ? (wins / total) * 100 : 0;
    
    // Efficiency: 4.0 is the "Neutral" average. Lower is better.
    double efficiencyBonus = (4.0 - avgAttempts) * 10; 
    
    // Retry Penalty: Penalize more if total games >> wins
    double retryPenalty = (total - wins) * 5.0; 
    
    double iq = 100 + (wins * 0.5) + (winRate * 0.1) + (streak * 1.5) + efficiencyBonus - retryPenalty;
    
    // Cap it realistically (80 - 160 range)
    if (iq < 80) iq = 80;
    if (iq > 160) iq = 160 + (iq - 160) * 0.1; 

    return {
      'winRate': '${winRate.toStringAsFixed(0)}%',
      'accuracy': '${(winRate * 0.9).toStringAsFixed(0)}%', // Weighted accuracy
      'iq': iq.toStringAsFixed(0),
    };
  }
}
