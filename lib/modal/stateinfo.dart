class StateInfo {
  String value;
  String code;
  StateInfo({this.value, this.code});

  factory StateInfo.fromJson(Map<String, dynamic> json) {
    return StateInfo(
      value: json["value"],
      code: json["code"],
    );
  }
}
