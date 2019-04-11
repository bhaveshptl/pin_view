class Sports {
  Sports._internal();
  static final Sports sport = Sports._internal();
  factory Sports() => sport;

  static Map<int, String> styles = {
    1: "WK",
    2: "BAT",
    3: "BOWL",
    4: "AR",
    5: "",
    6: "",
    7: "",
    8: "",
  };
}
