enum GameMode { level, daily }

extension GameModeX on GameMode {
  String get storageKey => name;
}
