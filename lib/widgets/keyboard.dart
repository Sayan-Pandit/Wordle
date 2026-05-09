import 'package:flutter/material.dart';
import 'package:wordle/controllers/theme_controller.dart';
import 'package:wordle/core/theme/app_theme.dart';

class Keyboard extends StatelessWidget {
  final Function(String) onKeyPress;
  final List<String> guesses;
  final String targetWord;

  const Keyboard({
    super.key,
    required this.onKeyPress,
    required this.guesses,
    required this.targetWord,
  });

  Color _getKeyColor(String letter) {
    String bestStatus = 'EMPTY';

    for (var guess in guesses) {
      final statuses = _getRowStatuses(guess, targetWord);
      for (int i = 0; i < guess.length; i++) {
        if (guess[i] == letter) {
          final status = statuses[i];
          if (status == 'CORRECT') {
            bestStatus = 'CORRECT';
          } else if (status == 'MISPLACED' && bestStatus != 'CORRECT') {
            bestStatus = 'MISPLACED';
          } else if (status == 'ABSENT' && bestStatus == 'EMPTY') {
            bestStatus = 'ABSENT';
          }
        }
      }
    }

    if (bestStatus == 'CORRECT') return AppColors.primaryGreen;
    if (bestStatus == 'MISPLACED') return AppColors.primaryYellow;
    if (bestStatus == 'ABSENT') return AppColors.absentGrey;
    return Colors.transparent;
  }

  List<String> _getRowStatuses(String guess, String target) {
    List<String> statuses = List.filled(5, 'ABSENT');
    Map<String, int> targetCounts = {};
    for (int i = 0; i < 5; i++) {
      targetCounts[target[i]] = (targetCounts[target[i]] ?? 0) + 1;
    }
    for (int i = 0; i < 5; i++) {
      if (guess[i] == target[i]) {
        statuses[i] = 'CORRECT';
        targetCounts[guess[i]] = targetCounts[guess[i]]! - 1;
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DELETE'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final color = _getKeyColor(key);
                final isSpecial = key == 'ENTER' || key == 'DELETE';
                
                return Expanded(
                  flex: isSpecial ? 2 : 1,
                  child: GestureDetector(
                    onTap: () => onKeyPress(key),
                    child: Container(
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: color == Colors.transparent 
                          ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF818384) : const Color(0xFFD3D6DA))
                          : color,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: key == 'DELETE' 
                        ? const Icon(Icons.backspace_outlined, size: 18, color: Colors.white)
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: isSpecial ? 10 : 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
