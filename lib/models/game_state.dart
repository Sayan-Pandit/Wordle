import 'dart:convert';

class GameState {
  final String targetWord;
  final List<String> guesses;
  final String gameStatus; // 'PLAYING', 'WON', 'LOST'
  final int level;
  final String mode; // 'level', 'daily'
  final DateTime lastUpdated;

  GameState({
    required this.targetWord,
    required this.guesses,
    required this.gameStatus,
    required this.level,
    required this.mode,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetWord': targetWord,
      'guesses': guesses,
      'gameStatus': gameStatus,
      'level': level,
      'mode': mode,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      targetWord: json['targetWord'] ?? '',
      guesses: List<String>.from(json['guesses'] ?? []),
      gameStatus: json['gameStatus'] ?? 'PLAYING',
      level: json['level'] ?? 1,
      mode: json['mode'] ?? 'level',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  /// Checks if the saved daily game is from a previous calendar day.
  bool isExpired() {
    if (mode != 'daily') return false;
    final now = DateTime.now();
    return now.day != lastUpdated.day || 
           now.month != lastUpdated.month || 
           now.year != lastUpdated.year;
  }
}
