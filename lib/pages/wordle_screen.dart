import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordle/controllers/wordle_controller.dart';
import 'package:wordle/models/game_mode.dart';
import 'package:wordle/widgets/keyboard.dart';
import 'package:wordle/widgets/word_grid.dart';
import 'package:wordle/controllers/theme_controller.dart';
import 'package:wordle/core/theme/app_theme.dart';
import 'package:wordle/shared/repositories/word_repository.dart';
import 'package:wordle/shared/repositories/stats_repository.dart';

class WordleScreen extends StatefulWidget {
  final GameMode mode;
  final int level;

  const WordleScreen({super.key, required this.mode, this.level = 1});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  late final WordleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WordleController(
      mode: widget.mode, 
      level: widget.level,
      wordRepository: WordRepository(),
      statsRepository: StatsRepository(),
    );
    _controller.addListener(_handleControllerUpdate);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    
    if (_controller.gameStatus == 'WON') {
      HapticFeedback.vibrate();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.mode == GameMode.daily ? 'DAILY QUEST' : 'JOURNEY LVL ${widget.level}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
            ),
            centerTitle: true,
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.gameStatus == 'LOADING') {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (_controller.gameStatus == 'ERROR') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Connection lost. Please retry.', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _controller.init, child: const Text('RETRY')),
          ],
        ),
      );
    }

    final targetWord = _controller.targetWord;
    if (targetWord == null) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: WordGrid(
                    guesses: _controller.guesses,
                    currentGuess: _controller.currentGuess,
                    targetWord: targetWord,
                  ),
                ),
              ),
            ),
          ),
          
          // NEW INTEGRATED SUBMIT BUTTON
          if (_controller.gameStatus == 'PLAYING') _buildSubmitButton(),
  
          if (_controller.gameStatus == 'WON' || _controller.gameStatus == 'LOST')
            _buildResultOverlay(context)
          else
            Keyboard(
              onKeyPress: _controller.handleKeyPress,
              guesses: _controller.guesses,
              targetWord: targetWord,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final message = _controller.message;
    final isError = message != null;
    final isReady = _controller.currentGuess.length == 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: isError 
                    ? Colors.redAccent 
                    : (isReady ? AppColors.primaryGreen : AppColors.absentGrey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isReady || isError)
                    BoxShadow(
                      color: (isError ? Colors.redAccent : AppColors.primaryGreen).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isReady ? () {
                    HapticFeedback.lightImpact();
                    _controller.handleKeyPress('ENTER');
                  } : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      isError ? message.toUpperCase() : "SUBMIT GUESS",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF818384) 
                  : const Color(0xFFD3D6DA),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _controller.handleKeyPress('DELETE');
                },
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Icon(Icons.backspace_outlined, size: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay(BuildContext context) {
    final isWon = _controller.gameStatus == 'WON';
    final attempts = _controller.guesses.length;
    final xp = isWon ? (7 - attempts) * 20 : 0;
    final bonus = attempts == 1 ? 50 : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWon ? AppColors.primaryGreen.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isWon ? AppColors.primaryGreen : Colors.redAccent, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isWon ? Icons.stars_rounded : Icons.heart_broken_rounded,
            color: isWon ? AppColors.primaryGreen : Colors.redAccent,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isWon ? (attempts == 1 ? 'GENIUS!' : 'SUCCESS!') : 'MAYBE NEXT TIME',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isWon ? AppColors.primaryGreen : Colors.redAccent),
          ),
          const SizedBox(height: 8),
          Text(
            isWon ? 'Word found in $attempts attempts' : 'The word was: ${_controller.targetWord}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isWon) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatLabel('XP EARNED', '+$xp'),
                if (bonus > 0) ...[
                  const SizedBox(width: 20),
                  _buildStatLabel('PERFECT BONUS', '+$bonus'),
                ],
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWon ? AppColors.primaryGreen : AppColors.absentGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (isWon && widget.mode == GameMode.level) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => WordleScreen(mode: GameMode.level, level: widget.level + 1)),
                      );
                    } else if (widget.mode == GameMode.daily) {
                      Navigator.pop(context); // Go back to Hub
                    } else {
                      _controller.startNewGame();
                    }
                  },
                  child: Text(
                    isWon 
                      ? (widget.mode == GameMode.daily ? 'BACK TO HUB' : 'NEXT LEVEL') 
                      : 'TRY AGAIN', 
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryGreen)),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }
}
