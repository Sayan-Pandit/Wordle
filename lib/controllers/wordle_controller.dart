import 'package:flutter/material.dart';
import 'package:wordle/models/game_mode.dart';
import 'package:wordle/models/game_state.dart';
import 'package:wordle/services/storage_service.dart';
import 'package:wordle/shared/repositories/word_repository.dart';
import 'package:wordle/shared/repositories/stats_repository.dart';

class WordleController extends ChangeNotifier {
  final GameMode mode;
  final int level;
  final IWordRepository wordRepository;
  final IStatsRepository statsRepository;

  String? targetWord;
  List<String> guesses = [];
  String currentGuess = '';
  String gameStatus = 'PLAYING';
  String? feedbackMessage;

  WordleController({
    required this.mode, 
    required this.level,
    required this.wordRepository,
    required this.statsRepository,
  });

  String? get message => feedbackMessage;

  Future<void> init() async {
    gameStatus = 'LOADING';
    feedbackMessage = null;
    notifyListeners();

    try {
      final savedState = await StorageService.loadGame(mode.storageKey);
      if (_canRestore(savedState)) {
        _restore(savedState!);
        notifyListeners();
        return;
      }
      await startNewGame();
    } catch (e) {
      debugPrint('Error restoring game: $e');
      await startNewGame();
    }
  }

  Future<void> startNewGame() async {
    guesses = [];
    currentGuess = '';
    feedbackMessage = null;
    gameStatus = 'LOADING';
    notifyListeners();

    final newWord = mode == GameMode.daily
        ? await wordRepository.getDailyWord()
        : await wordRepository.getLevelWord(level);

    if (newWord == null) {
      gameStatus = 'ERROR';
      notifyListeners();
      return;
    }

    targetWord = newWord.toUpperCase();
    gameStatus = 'PLAYING';
    _saveProgress();
    notifyListeners();
  }

  Future<void> handleKeyPress(String char) async {
    if (gameStatus != 'PLAYING') return;

    if (char == 'DELETE') {
      if (currentGuess.isNotEmpty) {
        currentGuess = currentGuess.substring(0, currentGuess.length - 1);
        feedbackMessage = null;
        _saveProgress();
        notifyListeners();
      }
      return;
    }

    if (char == 'ENTER') {
      if (currentGuess.length < 5) {
        feedbackMessage = 'Too short';
        notifyListeners();
      } else {
        await _submitGuess();
      }
      return;
    }

    if (currentGuess.length < 5) {
      currentGuess += char.toUpperCase();
      feedbackMessage = null;
      _saveProgress();
      notifyListeners();
    }
  }

  Future<void> _submitGuess() async {
    final guess = currentGuess.toUpperCase().trim();
    final isValid = await wordRepository.isValidWord(guess);

    if (!isValid) {
      feedbackMessage = 'Not in word list';
      notifyListeners();
      return;
    }

    guesses.add(guess);
    currentGuess = '';
    notifyListeners();

    if (guess == targetWord) {
      gameStatus = 'WON';
      
      await statsRepository.saveGameResult(
        isWin: true, 
        mode: mode,
        attempts: guesses.length,
        level: level,
      );
      
      if (mode == GameMode.level) {
        StorageService.clearGame(mode.storageKey);
      } else {
        _saveProgress();
      }
    } else if (guesses.length >= 6) {
      gameStatus = 'LOST';
      await statsRepository.saveGameResult(
        isWin: false, 
        mode: mode,
        attempts: 6,
        level: level,
      );
      
      if (mode == GameMode.level) {
        StorageService.clearGame(mode.storageKey);
      } else {
        _saveProgress();
      }
    } else {
      gameStatus = 'PLAYING';
      _saveProgress();
    }

    notifyListeners();
  }

  bool _canRestore(GameState? savedState) {
    if (savedState == null) return false;
    if (mode == GameMode.daily) return true;
    return savedState.level == level;
  }

  void _restore(GameState savedState) {
    targetWord = savedState.targetWord;
    guesses = savedState.guesses;
    currentGuess = ''; 
    gameStatus = savedState.gameStatus;
    feedbackMessage = null;
  }

  void _saveProgress() {
    final word = targetWord;
    if (word == null) return;

    final state = GameState(
      targetWord: word,
      guesses: guesses,
      gameStatus: gameStatus,
      level: level,
      mode: mode.storageKey,
      lastUpdated: DateTime.now(),
    );
    StorageService.saveGame(state).catchError((e) => debugPrint('Save error: $e'));
  }
}
