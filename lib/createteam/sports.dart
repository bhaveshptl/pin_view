class Sports {
  Sports._internal();
  static final Sports sport = Sports._internal();
  factory Sports() => sport;

  static Map<int, String> styles = {
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
