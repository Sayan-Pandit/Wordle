import 'dart:math';
import 'package:wordle/models/world_model.dart';

// Re-exporting for easy access across the app
export 'package:wordle/models/world_model.dart';

/// Helper to maintain legacy compatibility while using the new engine.
/// It flattens all worlds, chapters, and boss words into a single list.
List<String> get wordList {
  List<String> all = [];
  for (var world in WorldRegistry.worlds) {
    for (var chapter in world.chapters) {
      all.addAll(chapter.words);
      all.add(chapter.bossWord);
    }
  }
  return all;
}

/// Traditional random word selector used for Daily Challenges.
String getRandomWord() {
  return wordList[Random().nextInt(wordList.length)];
}

/// RESOLVER: Resolves an absolute level index (e.g., Level 5) 
/// into a specific word from the World -> Chapter system.
String getWordForLevel(int level) {
  final result = WorldRegistry.resolveLevel(level);
  return result['word'] ?? 'START';
}

/// STATUS CHECKER: Checks if a specific level is a Chapter Boss.
bool isBossLevel(int level) {
  final result = WorldRegistry.resolveLevel(level);
  return result['isBoss'] ?? false;
}
