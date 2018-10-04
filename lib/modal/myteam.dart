import 'package:playfantasy/modal/l1.dart';

class MyTeam {
  final int id;
  final int userId;
  final int captain;
  final double prize;
  final int rank;
  final int score;
  final int innings;
  final int matchId;
  final String name;
  final int seriesId;
  final int leagueId;
  final int inningsId;
  final int contestId;
  final int viceCaptain;
  final List<Player> players;

  MyTeam({
    this.captain,
    this.id,
    this.inningsId,
    this.prize,
    this.rank,
    this.score,
    this.leagueId,
    this.matchId,
    this.contestId,
    this.name,
    this.players,
    this.seriesId,
    this.userId,
    this.innings,
    this.viceCaptain,
  });

  factory MyTeam.fromJson(Map<String, dynamic> json) {
    return MyTeam(
      captain: json["captain"],
      id: json["id"],
      inningsId: json["inningsId"],
      leagueId: json["leagueId"],
      matchId: json["matchId"],
      contestId: json["contestId"],
      name: json["name"],
      players: json["players"] == null
          ? []
          : (json["players"] as List).map((i) => Player.fromJson(i)).toList(),
      seriesId: json["seriesId"],
      userId: json["userId"],
      viceCaptain: json["viceCaptain"],
      prize: json["prize"] == null ? 0.0 : (json["prize"]).toDouble(),
      rank: json["rank"] == null ? 0 : json["rank"],
      score: json["score"] == null ? 0 : json["score"],
      innings: json["innings"] == null ? 0 : json["innings"],
    );
  }
}
