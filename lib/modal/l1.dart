class L1 {
  final LeagueDetails league;
  final List<Contest> contests;
  L1({this.league, this.contests});

  factory L1.fromJson(Map<String, dynamic> json) {
    return L1(
      league: LeagueDetails.fromJson(json['league']),
      contests:
          (json["contests"] as List).map((i) => Contest.fromJson(i)).toList(),
    );
  }
}

class LeagueDetails {
  FanTeamRule fanTeamRules;
  final int inningsId;
  final int id;
  String name;
  int startTime;
  int endTime;
  int status;
  final List<Round> rounds;
  List<dynamic> allowedContestTypes;
  LeagueDetails({
    this.fanTeamRules,
    this.inningsId,
    this.id,
    this.name,
    this.startTime,
    this.endTime,
    this.status,
    this.rounds,
    this.allowedContestTypes,
  });

  factory LeagueDetails.fromJson(Map<String, dynamic> json) {
    return LeagueDetails(
      fanTeamRules: FanTeamRule.fromJson(json["fanTeamRules"]),
      inningsId: json["inningsId"],
      id: json["id"],
      name: json["name"],
      startTime: json["startTime"],
      endTime: json["endTime"],
      status: json["status"],
      rounds: (json["rounds"] as List).map((i) => Round.fromJson(i)).toList(),
      allowedContestTypes: json["allowedContestTypes"],
    );
  }
}

class Round {
  int id;
  List<MatchInfo> matches;
  Round({this.matches, this.id});

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json["id"],
      matches:
          (json["matches"] as List).map((i) => MatchInfo.fromJson(i)).toList(),
    );
  }
}

class MatchInfo {
  String sportDesc;
  Series series;
  Team teamA;
  Team teamB;
  int id;
  String name;
  int squad;
  int startTime;
  int endTime;
  int status;
  int sportType;
  MatchInfo({
    this.sportDesc,
    this.series,
    this.teamA,
    this.teamB,
    this.id,
    this.squad,
    this.name,
    this.startTime,
    this.endTime,
    this.status,
    this.sportType,
  });

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    return MatchInfo(
      sportDesc: json["sportDesc"],
      series: Series.fromJson(json["series"]),
      teamA: Team.fromJson(json["teamA"]),
      teamB: Team.fromJson(json["teamB"]),
      id: json["id"],
      name: json["name"],
      squad: json["squad"],
      startTime: json["startTime"],
      endTime: json["endTime"],
      status: json["status"],
      sportType: json["sportType"],
    );
  }
}

class Series {
  final int seriesTypeId;
  final int id;
  final String name;
  final String info;
  final int startDate;
  final int endDate;
  final int countryId;
  Series({
    this.seriesTypeId,
    this.id,
    this.name,
    this.info,
    this.startDate,
    this.endDate,
    this.countryId,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      seriesTypeId: json["seriesTypeId"],
      id: json["id"],
      name: json["name"],
      info: json["info"],
      startDate: json["startDate"],
      endDate: json["endDate"],
      countryId: json["countryId"],
    );
  }
}

class FanTeamRule {
  final int credits;
  final double vcMult;
  final int captainMult;
  final int playersTotal;
  final int playersForeign;
  final int playersPerTeam;
  final List<PlayingStyle> styles;
  FanTeamRule({
    this.vcMult,
    this.styles,
    this.credits,
    this.captainMult,
    this.playersTotal,
    this.playersForeign,
    this.playersPerTeam,
  });

  factory FanTeamRule.fromJson(Map<String, dynamic> json) {
    return FanTeamRule(
      credits: json["credits"],
      captainMult: json["captainMult"],
      playersTotal: json["playersTotal"],
      vcMult: (json["vcMult"]).toDouble(),
      playersForeign: json["playersForeign"],
      playersPerTeam: json["playersPerTeam"],
      styles: (json["styles"] as List)
          .map((i) => PlayingStyle.fromJson(i))
          .toList(),
    );
  }
}

class Team {
  final int id;
  final String name;
  final int sportType;
  final String sportDesc;
  final String colorCode;
  final String logoUrl;
  final String jerseyUrl;
  final int inningsId;
  final List<Player> players;
  Team({
    this.id,
    this.name,
    this.sportType,
    this.sportDesc,
    this.colorCode,
    this.logoUrl,
    this.jerseyUrl,
    this.inningsId,
    this.players,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json["id"],
      name: json["name"],
      sportType: json["sportType"],
      sportDesc: json["sportDesc"],
      colorCode: json["colorCode"],
      logoUrl: json["logoUrl"],
      jerseyUrl: json["jerseyUrl"],
      inningsId: json["inningsId"],
      players:
          (json["players"] as List).map((i) => Player.fromJson(i)).toList(),
    );
  }
}

class Player {
  final int id;
  final String name;
  final int sportsId;
  final String sportName;
  final int playingStyleId;
  final String playingStyleDesc;
  final int countryId;
  final String countryName;
  final dynamic seriesScore;
  final double score;
  final double credit;
  String jerseyUrl;
  int teamId;
  Player({
    this.id,
    this.name,
    this.sportsId,
    this.sportName,
    this.playingStyleId,
    this.playingStyleDesc,
    this.countryId,
    this.countryName,
    this.seriesScore,
    this.score,
    this.credit,
    this.jerseyUrl,
    this.teamId,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json["id"],
      name: json["name"],
      sportsId: json["sportsId"],
      sportName: json["sportName"],
      playingStyleId: json["playingStyleId"],
      playingStyleDesc: json["playingStyleDesc"],
      countryId: json["countryId"],
      countryName: json["countryName"],
      seriesScore: json["seriesScore"],
      score: json["score"] == null ? 0.0 : (json["score"]).toDouble(),
      credit: json["credit"] == null ? 0.0 : (json["credit"]).toDouble(),
      jerseyUrl: json["jerseyUrl"],
      teamId: json["teamId"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "sportsId": sportsId,
        "sportName": sportName,
        "playingStyleId": playingStyleId,
        "playingStyleDesc": playingStyleDesc,
        "countryId": countryId,
        "countryName": countryName,
        "seriesScore": seriesScore,
        "score": score,
        "credit": credit,
        "jerseyUrl": jerseyUrl,
        "teamId": teamId,
      };
}

class PlayingStyle {
  final int id;
  final String label;
  final List<dynamic> rule;

  PlayingStyle({
    this.id,
    this.label,
    this.rule,
  });

  factory PlayingStyle.fromJson(Map<String, dynamic> json) {
    return PlayingStyle(
      id: json["id"],
      label: json["label"],
      rule: json["rule"],
    );
  }
}

class Contest {
  int id;
  String name;
  int templateId;
  int size;
  int prizeType;
  int entryFee;
  int minUsers;
  double serviceFee;
  int teamsAllowed;
  int leagueId;
  int releaseTime;
  int regStartTime;
  int startTime;
  int endTime;
  int status;
  int visibilityId;
  int realTeamId;
  String visibilityInfo;
  String contestJoinCode;
  int joined;
  List<dynamic> prizeDetails;
  Map<String, dynamic> brand;
  int milestones;
  int inningsId;
  int bonusAllowed;
  bool guaranteed;
  bool recommended;
  bool deleted;
  bool hideBonusInfo;
  Contest({
    this.id,
    this.name,
    this.templateId,
    this.size,
    this.prizeType,
    this.entryFee,
    this.minUsers,
    this.serviceFee,
    this.teamsAllowed,
    this.leagueId,
    this.releaseTime,
    this.regStartTime,
    this.startTime,
    this.endTime,
    this.status,
    this.visibilityId,
    this.visibilityInfo,
    this.contestJoinCode,
    this.joined,
    this.realTeamId,
    this.prizeDetails,
    this.brand,
    this.milestones,
    this.inningsId,
    this.bonusAllowed,
    this.guaranteed,
    this.recommended,
    this.deleted,
    this.hideBonusInfo,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json["id"],
      name: json["name"],
      templateId: json["templateId"],
      size: json["size"],
      prizeType: json["prizeType"],
      entryFee: json["entryFee"],
      minUsers: json["minUsers"],
      serviceFee: (json["serviceFee"]).toDouble(),
      teamsAllowed: json["teamsAllowed"],
      leagueId: json["leagueId"],
      releaseTime: json["releaseTime"],
      regStartTime: json["regStartTime"],
      startTime: json["startTime"],
      endTime: json["endTime"],
      status: json["status"],
      realTeamId: json["realTeamId"],
      visibilityId: json["visibilityId"],
      visibilityInfo: json["visibilityInfo"],
      contestJoinCode: json["contestJoinCode"],
      joined: json["joined"] == null && json["joinedTeamCount"] != null
          ? json["joinedTeamCount"]
          : json["joined"],
      prizeDetails: json["prizeDetails"],
      brand: json["brand"],
      milestones: json["milestones"],
      inningsId: json["inningsId"],
      bonusAllowed: json["bonusAllowed"],
      guaranteed: json["guaranteed"],
      recommended: json["recommended"],
      deleted: json["deleted"],
      hideBonusInfo: json["hideBonusInfo"],
    );
  }
}

class MyContest {
  Map<String, List<Contest>> leagues;

  MyContest({this.leagues});

  factory MyContest.fromJson(Map<String, dynamic> json) {
    Map<String, List<Contest>> myContests = {};
    json.forEach((String key, dynamic value) {
      myContests[key] =
          (value as List).map((i) => Contest.fromJson(i)).toList();
    });
    return MyContest(leagues: myContests);
  }
}
