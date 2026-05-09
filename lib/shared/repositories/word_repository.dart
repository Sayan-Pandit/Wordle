import 'package:wordle/services/word_service.dart';

abstract class IWordRepository {
  Future<String?> getDailyWord();
  Future<String?> getLevelWord(int level);
  Future<bool> isValidWord(String word);
}

class WordRepository implements IWordRepository {
  @override
  Future<String?> getDailyWord() => WordService.fetchDailyWord();

  @override
  Future<String?> getLevelWord(int level) => WordService.fetchWordByLevel(level);

  @override
  Future<bool> isValidWord(String word) => WordService.isValidWord(word);
}
