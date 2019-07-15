Sports sports = Sports();

class Sports {
  Sports._internal();
  static final Sports sport = Sports._internal();
  factory Sports() => sport;

  Map<String, int> mapSports = {
    "CRICKET": 1,
    "FOOTBALL": 2,
    "KABADDI": 3,
  };

  Map<int, String> playingStyles = {
    1: "WK",
    2: "BAT",
    3: "BOWL",
    4: "AR",
    5: "GK",
    6: "DEF",
    7: "MID",
    8: "FRWD",
    9: "RD",
    10: "AR",
    11: "DEF",
  };
}
