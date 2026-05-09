import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordle/models/game_state.dart';
import 'package:wordle/models/game_mode.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static const String _levelKey = 'wordle_level_progress';
  static const String _dailyKey = 'wordle_daily_progress';
  static const String _statsKey = 'wordle_user_stats';
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveGame(GameState state) async {
    final user = _auth.currentUser;
    final key = state.mode == 'daily' ? _dailyKey : _levelKey;
    final jsonStr = jsonEncode(state.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonStr);

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('games').add({
        ...state.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<GameState?> loadGame(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(mode == 'daily' ? _dailyKey : _levelKey);
    if (jsonStr != null) {
      try {
        final state = GameState.fromJson(jsonDecode(jsonStr));
        if (mode == 'daily' && state.isExpired()) return null;
        return state;
      } catch (e) {}
    }
    return null;
  }

  static Future<Map<String, dynamic>> getLocalStats() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    final statsStr = prefs.getString(_statsKey);
    
    Map<String, dynamic> localStats = {
      'xp': 0,
      'monthlyXP': 0,
      'lastUpdateMonth': '',
      'updatedAt': 0,
      'daily': {'currentStreak': 0, 'maxStreak': 0, 'wins': 0, 'totalGames': 0},
      'level': {'currentLevel': 1, 'wins': 0, 'totalGames': 0, 'guessDistribution': '{}'}
    };

    if (statsStr != null) {
      try {
        localStats = Map<String, dynamic>.from(jsonDecode(statsStr));
      } catch (e) {}
    }

    // Smart Sync: Fetch from Cloud in background if user is logged in
    if (user != null) {
      _backgroundSync(user.uid, localStats);
    }

    return localStats;
  }

  static Future<void> _backgroundSync(String uid, Map<String, dynamic> localStats) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final cloudData = doc.data() as Map<String, dynamic>;
        final cloudStats = cloudData['stats'] as Map<String, dynamic>?;
        
        if (cloudStats != null) {
          final int localTs = localStats['updatedAt'] ?? 0;
          final int cloudTs = cloudStats['updatedAt'] ?? 0;

          // If Cloud is newer, update Local
          if (cloudTs > localTs) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_statsKey, jsonEncode(cloudStats));
          } 
          // If Local is newer (and not synced), push to cloud
          else if (localTs > cloudTs) {
            await _firestore.collection('users').doc(uid).update({
              'stats': localStats,
              'xp': localStats['xp'],
              'monthlyXP': localStats['monthlyXP'],
              'updatedAt': localTs,
            });
          }
        }
      }
    } catch (e) {}
  }

  static Future<void> updateUserStats({
    required bool isWin, 
    required int points, 
    required GameMode mode,
    required int attempts,
    int? playedLevel,
  }) async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> stats = await getLocalStats();
    
    // Monthly Reset Logic
    final now = DateTime.now();
    final monthKey = "${now.year}_${now.month}";
    final lastMonthKey = stats['lastUpdateMonth'] ?? "";
    
    int earnedXP = 0;
    bool isNewProgress = true;

    if (mode == GameMode.level && playedLevel != null) {
      final int currentHighest = stats['level']['currentLevel'] ?? 1;
      if (playedLevel < currentHighest) isNewProgress = false;
    }

    if (isWin && isNewProgress) {
      earnedXP = (7 - attempts) * 20;
      if (attempts == 1) earnedXP += 50;
    }
    
    // Update Lifetime and Monthly XP
    stats['xp'] = (stats['xp'] ?? 0) + earnedXP;
    stats['updatedAt'] = now.millisecondsSinceEpoch; // Cache Timestamp
    
    if (monthKey != lastMonthKey) {
      stats['monthlyXP'] = earnedXP;
      stats['lastUpdateMonth'] = monthKey;
    } else {
      stats['monthlyXP'] = (stats['monthlyXP'] ?? 0) + earnedXP;
    }

    if (mode == GameMode.daily) {
      final daily = Map<String, dynamic>.from(stats['daily'] ?? {});
      daily['totalGames'] = (daily['totalGames'] ?? 0) + 1;
      if (isWin) {
        daily['wins'] = (daily['wins'] ?? 0) + 1;
        final today = DateTime(now.year, now.month, now.day);
        final lastWinStr = daily['lastWinDate'];
        if (lastWinStr != null) {
          final lastWin = DateTime.parse(lastWinStr);
          if (today.difference(lastWin).inDays == 1) {
            daily['currentStreak'] = (daily['currentStreak'] ?? 0) + 1;
          } else if (today.difference(lastWin).inDays > 1) {
            daily['currentStreak'] = 1;
          }
        } else {
          daily['currentStreak'] = 1;
        }
        if (daily['currentStreak'] > (daily['maxStreak'] ?? 0)) daily['maxStreak'] = daily['currentStreak'];
        daily['lastWinDate'] = today.toIso8601String();
      } else {
        daily['currentStreak'] = 0;
      }
      stats['daily'] = daily;
    } else {
      final level = Map<String, dynamic>.from(stats['level'] ?? {});
      level['totalGames'] = (level['totalGames'] ?? 0) + 1;
      if (isWin) {
        level['wins'] = (level['wins'] ?? 0) + 1;
        if (isNewProgress) {
          level['currentLevel'] = (level['currentLevel'] ?? 1) + 1;
        }
        Map<String, dynamic> dist = jsonDecode(level['guessDistribution'] ?? '{}');
        dist[attempts.toString()] = (dist[attempts.toString()] ?? 0) + 1;
        level['guessDistribution'] = jsonEncode(dist);
      }
      stats['level'] = level;
    }
    
    await prefs.setString(_statsKey, jsonEncode(stats));

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'stats': stats,
        'xp': stats['xp'],
        'monthlyXP': stats['monthlyXP'],
        'lastUpdateMonth': stats['lastUpdateMonth'],
        'updatedAt': stats['updatedAt'], // Use Local TS for sync
      });
    }
  }

  static Future<int> getCurrentLevel() async {
    final stats = await getLocalStats();
    return stats['level']['currentLevel'] ?? 1;
  }

  static Future<void> clearGame(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(mode == 'daily' ? _dailyKey : _levelKey);
  }
}
