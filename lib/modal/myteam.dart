import 'package:playfantasy/modal/l1.dart';

class MyTeam {
  final int captain;
  final int id;
  final int inningsId;
  final int leagueId;
  final int matchId;
  final String name;
  final List<Player> players;
  final int seriesId;
  final int userId;
  final int viceCaptain;

  MyTeam({
    this.captain,
    this.id,
    this.inningsId,
    this.leagueId,
    this.matchId,
    this.name,
    this.players,
    this.seriesId,
    this.userId,
    this.viceCaptain,
  });

  factory MyTeam.fromJson(Map<String, dynamic> json) {
    return MyTeam(
      captain: json["captain"],
      id: json["id"],
      inningsId: json["inningsId"],
      leagueId: json["leagueId"],
      matchId: json["matchId"],
      name: json["name"],
      players:
          (json["players"] as List).map((i) => Player.fromJson(i)).toList(),
      seriesId: json["seriesId"],
      userId: json["userId"],
      viceCaptain: json["viceCaptain"],
    );
  }
}
