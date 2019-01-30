class MySheet {
  int rank;
  double score;
  double prize;
  final int id;
  final int userId;
  final int status;
  final String name;
  final int leagueId;
  final int contestId;
  final int inningsId;
  final int boosterOne;
  final int boosterTwo;
  final dynamic channelId;
  final List<int> answers;
  final List<dynamic> boosterThree;

  MySheet({
    this.id,
    this.name,
    this.rank,
    this.prize,
    this.score,
    this.status,
    this.userId,
    this.answers,
    this.leagueId,
    this.inningsId,
    this.contestId,
    this.channelId,
    this.boosterOne,
    this.boosterTwo,
    this.boosterThree,
  });

  factory MySheet.fromJson(Map<String, dynamic> json) {
    return MySheet(
      id: json["id"] == null || json["id"] == 0
          ? (json["answerSheetId"] == null ? json["id"] : json["answerSheetId"])
          : json["id"],
      name: json["name"] == null ? "" : json["name"],
      score: json["score"] == null ? 0.0 : json["score"].toDouble(),
      status: json["status"],
      userId: json["userId"],
      contestId: json["contestId"],
      rank: json["rank"] == null ? 0 : json["rank"],
      prize: json["prize"] == null ? 0.0 : json["prize"].toDouble(),
      answers: json["answers"] == null
          ? null
          : (json["answers"] as List<dynamic>).map((f) {
              return (f as int).toInt();
            }).toList(),
      leagueId: json["leagueId"],
      inningsId: json["inningsId"],
      channelId: json["channelId"],
      boosterOne: json["boosterOne"],
      boosterTwo: json["boosterTwo"],
      boosterThree: json["boosterThree"] == null
          ? null
          : (json["boosterThree"] as List<dynamic>).map((f) {
              return f;
            }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "name": this.name,
        "score": this.score,
        "status": this.status,
        "userId": this.userId,
        "answers": this.answers,
        "leagueId": this.leagueId,
        "contestId": this.contestId,
        "inningsId": this.inningsId,
        "channelId": this.channelId,
        "boosterOne": this.boosterOne,
        "boosterTwo": this.boosterTwo,
        "boosterThree": this.boosterThree,
      };
}
