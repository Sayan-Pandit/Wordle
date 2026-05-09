import 'package:wordle/data/words.dart';
import 'package:wordle/data/dictionary.dart';

class WordService {
  static Future<String?> fetchDailyWord() async {
    // Deterministic daily word based on the date
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
    final index = day % wordList.length;
    return wordList[index];
  }

  static Future<String?> fetchWordByLevel(int level) async {
    // Uses the new World Progression Architecture to find the exact word
    return getWordForLevel(level);
  }

  static Future<bool> isValidWord(String word) async {
    final normalizedWord = word.toUpperCase().trim();
    // Check against BOTH the target world words AND the master dictionary
    return wordList.contains(normalizedWord) || validWords.contains(normalizedWord);
  }
}
