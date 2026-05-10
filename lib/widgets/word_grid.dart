import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordle/core/theme/app_theme.dart';
import 'package:wordle/controllers/theme_controller.dart';

class WordGrid extends StatelessWidget {
  final List<String> guesses;
  final String currentGuess;
  final String targetWord;

  const WordGrid({
    super.key,
    required this.guesses,
    required this.currentGuess,
    required this.targetWord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (row) {
        String rowGuess = "";
        bool isCurrentRow = row == guesses.length;
        bool isFinalAttempt = row == 5 && isCurrentRow;

        if (row < guesses.length) {
          rowGuess = guesses[row];
        } else if (isCurrentRow) {
          rowGuess = currentGuess;
        }

        List<String> rowStatuses = [];
        if (row < guesses.length) {
          rowStatuses = _getRowStatuses(rowGuess, targetWord);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (col) {
              String letter = "";
              if (col < rowGuess.length) {
                letter = rowGuess[col];
              }

              Color bgColor = Colors.transparent;
              Color borderColor = Colors.grey.withOpacity(0.3);
              Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

              if (row < guesses.length) {
                final status = rowStatuses[col];
                textColor = Colors.white;
                if (status == 'CORRECT') {
                  bgColor = AppColors.primaryGreen;
                  borderColor = AppColors.primaryGreen;
                } else if (status == 'MISPLACED') {
                  bgColor = AppColors.primaryYellow;
                  borderColor = AppColors.primaryYellow;
                } else {
                  bgColor = AppColors.absentGrey;
                  borderColor = AppColors.absentGrey;
                }
              } else if (isCurrentRow) {
                if (isFinalAttempt && letter.isNotEmpty) {
                  borderColor = Colors.orangeAccent;
                } else if (col < currentGuess.length) {
                  borderColor = Colors.grey;
                }
              }

              return _AnimatedTile(
                key: ValueKey('$row-$col-$letter-${guesses.length}'),
                letter: letter,
                bgColor: bgColor,
                borderColor: borderColor,
                textColor: textColor,
                isFinalAttempt: isFinalAttempt && letter.isNotEmpty,
              );
            }),
          ),
        );
      }),
    );
  }
  List<String> _getRowStatuses(String guess, String target) {
    if (guess.isEmpty || target.isEmpty) return List.filled(5, 'EMPTY');
    
    List<String> statuses = List.filled(5, 'ABSENT');
    Map<String, int> targetCounts = {};

    // Pass 1: Mark Greens and build frequency map
    for (int i = 0; i < 5; i++) {
      String t = target[i];
      targetCounts[t] = (targetCounts[t] ?? 0) + 1;
    }

    for (int i = 0; i < 5; i++) {
      if (guess[i] == target[i]) {
        statuses[i] = 'CORRECT';
        targetCounts[guess[i]] = targetCounts[guess[i]]! - 1;
      }
    }

    // Pass 2: Mark Yellows only if counts remain
    for (int i = 0; i < 5; i++) {
      if (statuses[i] != 'CORRECT') {
        String g = guess[i];
        if (targetCounts.containsKey(g) && targetCounts[g]! > 0) {
          statuses[i] = 'MISPLACED';
          targetCounts[g] = targetCounts[g]! - 1;
        }
      }
    }

    return statuses;
  }
}

class _AnimatedTile extends StatefulWidget {
  final String letter;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool isFinalAttempt;

  const _AnimatedTile({
    super.key,
    required this.letter,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.isFinalAttempt,
  });

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.letter.isNotEmpty) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void didUpdateWidget(_AnimatedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.letter.isNotEmpty && oldWidget.letter.isEmpty) {
      _controller.reset();
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 60, height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.borderColor, width: 2),
          boxShadow: [
            if (widget.bgColor != Colors.transparent)
              BoxShadow(color: widget.bgColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            if (widget.isFinalAttempt)
              BoxShadow(color: Colors.orangeAccent.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.letter,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: widget.textColor),
        ),
      ),
    );
  }
}
