import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Color _getKeyColor(BuildContext context, String letter) {
    String bestStatus = 'EMPTY';

    for (var guess in guesses) {
      if (guess.length != 5) continue;
      
      final statuses = _getRowStatuses(guess, targetWord);
      for (int i = 0; i < 5; i++) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (bestStatus == 'CORRECT') return AppColors.primaryGreen;
    if (bestStatus == 'MISPLACED') return AppColors.primaryYellow;
    if (bestStatus == 'ABSENT') return isDark ? const Color(0xFF3A3A3C) : AppColors.absentGrey;
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
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          int rowIndex = entry.key;
          List<String> row = entry.value;

          List<Widget> rowChildren = [];

          // Add half-key indentation for the middle row (A-L)
          if (rowIndex == 1) {
            rowChildren.add(const Spacer(flex: 1));
          }
          // Add perfect symmetry indentation for the bottom row
          else if (rowIndex == 2) {
            rowChildren.add(const Spacer(flex: 3));
          }

          rowChildren.addAll(row.map((key) {
            final color = _getKeyColor(context, key);
            
            return Expanded(
              flex: 2, // All keys are now uniformly sized
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onKeyPress(key);
                },
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
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }));

          // Add half-key indentation for the middle row (A-L)
          if (rowIndex == 1) {
            rowChildren.add(const Spacer(flex: 1));
          }
          // Add perfect symmetry indentation for the bottom row right side
          else if (rowIndex == 2) {
            rowChildren.add(const Spacer(flex: 3));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rowChildren,
            ),
          );
        }).toList(),
      ),
    );
  }
}
