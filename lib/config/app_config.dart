class AppConfig {
  // Game settings
  static const String gameName = '神獣リーグ';
  static const String version = '1.0.0';

  // Battle settings
  static const int battleDurationSeconds = 300; // 5 minutes
  static const int maxPlayersPerTeam = 5;
  static const int teamsCount = 2;

  // ELO settings
  static const double baseElo = 1000.0;
  static const double eloKFactor = 32.0;

  // Evolution settings
  static const List<String> evolutionTypes = ['attack', 'defense', 'mobility'];
  static const Map<String, double> evolutionStatBoosts = {
    'attack': 1.3,
    'defense': 1.3,
    'mobility': 1.3,
  };

  // Pricing (in JPY)
  static const double battlePassPrice = 500.0;
  static const double skinPrice = 300.0;

  // KPI Targets
  static const double day7RetentionTarget = 0.40;
  static const double day30RetentionTarget = 0.20;
  static const double rankedEntryTarget = 0.60;
  static const double monetizationTarget = 0.05;

  // Matchmaking settings
  static const int matchmakingTimeoutSeconds = 30;
  static const int eloRangeDifference = 200; // Max ELO difference for matching

  // Asset paths
  static const String animationsPath = 'assets/animations/';
  static const String imagesPath = 'assets/images/';
  static const String soundsPath = 'assets/sounds/';

  // Firebase settings
  static const bool useFirebaseEmulator = false; // Set to true for local testing
}

// Game constants
enum GameDifficulty {
  tutorial,
  casual,
  normal,
  ranked,
}

enum GameRegion {
  asia,
  japan,
  asiaPacific,
}
