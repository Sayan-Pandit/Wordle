import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard, elite }

typedef WorldModel = WordWorld;

class WordWorld {
  // Static access for legacy UI compatibility
  static List<WordWorld> get worlds => WorldRegistry.worlds;
  
  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final Color primaryColor;
  final IconData icon;
  final List<WordChapter> chapters;

  const WordWorld({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.primaryColor,
    required this.icon,
    required this.chapters,
  });

  int get totalLevels => chapters.fold(0, (sum, chapter) => sum + chapter.words.length + 1); // +1 for boss
}

class WordChapter {
  final String id;
  final String name;
  final List<String> words;
  final String bossWord;

  const WordChapter({
    required this.id,
    required this.name,
    required this.words,
    required this.bossWord,
  });

  int get levelCount => words.length + 1;
}

// Global Registry for the Progression Engine
class WorldRegistry {
  static final List<WordWorld> worlds = [
    _verbalMeadows,
    _syllableCanyon,
    _lexiconPeak,
    _cosmicCipher,
  ];

  static WordWorld? getWorldById(String id) => worlds.where((w) => w.id == id).firstOrNull;

  // Resolve absolute level index (e.g. Level 45) to a specific World/Chapter/Word
  static Map<String, dynamic> resolveLevel(int globalLevel) {
    int current = 0;
    for (var world in worlds) {
      for (var chapter in world.chapters) {
        // Normal Levels
        for (int i = 0; i < chapter.words.length; i++) {
          current++;
          if (current == globalLevel) {
            return {
              'world': world,
              'chapter': chapter,
              'word': chapter.words[i],
              'isBoss': false,
            };
          }
        }
        // Boss Level
        current++;
        if (current == globalLevel) {
          return {
            'world': world,
            'chapter': chapter,
            'word': chapter.bossWord,
            'isBoss': true,
          };
        }
      }
    }
    return {};
  }

  // --- PRIVATE WORLD DEFINITIONS ---

  static const _verbalMeadows = WordWorld(
    id: 'world_1',
    name: 'Verbal Meadows',
    description: 'A calm, sunny path through common everyday words.',
    difficulty: Difficulty.easy,
    primaryColor: Color(0xFF58CC02),
    icon: Icons.eco_rounded,
    chapters: [
      WordChapter(
        id: 'w1_c1',
        name: 'The First Steps',
        words: ['APPLE', 'HOUSE', 'WATER', 'PLANT', 'LIGHT', 'TABLE', 'BREAD', 'MUSIC', 'ENTRY'],
        bossWord: 'HEART',
      ),
      WordChapter(
        id: 'w1_c2',
        name: 'Nature Paths',
        words: ['GRASS', 'TREES', 'RIVER', 'OCEAN', 'FRUIT', 'FLOWER', 'STORM', 'CLOUD', 'EARTH'],
        bossWord: 'BRAVE',
      ),
    ],
  );

  static const _syllableCanyon = WordWorld(
    id: 'world_2',
    name: 'Syllable Canyon',
    description: 'Adventure deep into trickier spelling and strategic patterns.',
    difficulty: Difficulty.medium,
    primaryColor: Color(0xFFF39C12),
    icon: Icons.terrain_rounded,
    chapters: [
      WordChapter(
        id: 'w2_c1',
        name: 'The Descent',
        words: ['SHARP', 'BRISK', 'STEEP', 'ROUGH', 'SMOOTH', 'BRIDGE', 'CANDLE', 'FROZEN'],
        bossWord: 'STRIKE',
      ),
      WordChapter(
        id: 'w2_c2',
        name: 'Echo Chambers',
        words: ['BOTTLE', 'CANNY', 'GEESE', 'SWEET', 'SLEEP', 'SHADOW', 'WINTER', 'SUMMIT'],
        bossWord: 'MASTER',
      ),
    ],
  );

  static const _lexiconPeak = WordWorld(
    id: 'world_3',
    name: 'Lexicon Peak',
    description: 'Master rare letter combinations and precision solves.',
    difficulty: Difficulty.hard,
    primaryColor: Color(0xFFE74C3C),
    icon: Icons.landscape_rounded,
    chapters: [
      WordChapter(
        id: 'w3_c1',
        name: 'Thin Air',
        words: ['CRYPT', 'GLYPH', 'FJORD', 'WRYLY', 'ABYSS', 'LYRIC', 'KHAKI', 'MYRRH'],
        bossWord: 'PHLOX',
      ),
      WordChapter(
        id: 'w3_c2',
        name: 'The Ascent',
        words: ['BLITZ', 'SCYTHE', 'VORTX', 'WHARF', 'CHASM', 'CHAOS', 'HYENA', 'KNACK'],
        bossWord: 'ZENITH',
      ),
    ],
  );

  static const _cosmicCipher = WordWorld(
    id: 'world_4',
    name: 'Cosmic Cipher',
    description: 'The ultimate prestige challenge for the elite.',
    difficulty: Difficulty.elite,
    primaryColor: Color(0xFF9B59B6),
    icon: Icons.auto_awesome_rounded,
    chapters: [
      WordChapter(
        id: 'w4_c1',
        name: 'The Singularity',
        words: ['ZEPHYR', 'QUARTZ', 'NYMPH', 'SPHINX', 'QUAKE', 'QUIRK', 'QUEUE', 'VIVID'],
        bossWord: 'PROXY',
      ),
      WordChapter(
        id: 'w4_c2',
        name: 'The Void',
        words: ['VIXEN', 'VOILA', 'KUDZU', 'QOPHS', 'XYLEM', 'XYLYL', 'SYLPH', 'TRYST'],
        bossWord: 'CIPHER',
      ),
    ],
  );
}
