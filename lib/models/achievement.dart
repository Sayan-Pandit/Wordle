import 'package:flutter/material.dart';

enum BadgeRarity { common, rare, epic, legendary }

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final bool isUnlocked;
  final double currentProgress;
  final double targetValue;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.targetValue = 1,
  });

  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common: return Colors.grey;
      case BadgeRarity.rare: return Colors.blueAccent;
      case BadgeRarity.epic: return Colors.purpleAccent;
      case BadgeRarity.legendary: return Colors.orangeAccent;
    }
  }
}

class UserRank {
  final String title;
  final int minXP;
  final Color color;

  UserRank({required this.title, required this.minXP, required this.color});

  static List<UserRank> ranks = [
    UserRank(title: "Word Rookie", minXP: 0, color: Colors.grey),
    UserRank(title: "Puzzle Master", minXP: 500, color: Colors.blue),
    UserRank(title: "Streak Legend", minXP: 1500, color: Colors.purple),
    UserRank(title: "Grand Solver", minXP: 5000, color: Colors.orange),
  ];

  static UserRank getRank(int xp) {
    return ranks.lastWhere((r) => xp >= r.minXP, orElse: () => ranks.first);
  }
}
