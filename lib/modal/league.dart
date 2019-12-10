class League {
  int status;
  final int squad;
  final Team teamA;
  final Team teamB;
  final int matchId;
  final int leagueId;
  final Series series;
  final int prediction;
  final int matchEndTime;
  final String matchName;
  int matchStartTime;

  League({
    this.squad,
    this.teamA,
    this.teamB,
    this.status,
    this.series,
    this.matchId,
    this.leagueId,
    this.matchName,
    this.prediction,
    this.matchEndTime,
    this.matchStartTime,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return League();
    } else {
      return League(
        squad: json["squad"],
        status: json['status'],
        matchId: json['matchId'],
        leagueId: json['leagueId'],
        matchName: json['matchName'],
        prediction: json['prediction'],
        matchEndTime: json['matchEndTime'],
        teamA: Team.fromJson(json['teamA']),
        teamB: Team.fromJson(json['teamB']),
        matchStartTime: json['matchStartTime'],
        series: Series.fromJson(json['series']),
      );
    }
  }
}

class LeagueStatus {
  static const int UPCOMING = 1;
  static const int LIVE = 2;
  static const int COMPLETED = 3;
}

class Series {
  final int id;
  final String name;
  final String info;
  final int priority;
  final int endDate;
  final int startDate;
  final int countryId;
  final int seriesTypeId;
  final String seriesTypeInfo;
  Series({
    this.id,
    this.name,
    this.info,
    this.endDate,
    this.startDate,
    this.countryId,
    this.seriesTypeId,
    this.priority = 0,
    this.seriesTypeInfo,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'],
      name: json['name'],
      info: json['info'],
      endDate: json['endDate'],
      priority: json['priority'] == null ? 0 : json['priority'],
      startDate: json['startDate'],
      countryId: json['countryId'],
      seriesTypeId: json['seriesTypeId'],
      seriesTypeInfo: json['seriesTypeInfo'],
    );
  }
}

class Team {
  final int id;
  final String name;
  final int sportType;
  final int inningsId;
  final String logoUrl;
  final String sportDesc;
  final String colorCode;
  final String jerseyUrl;
  Team({
    this.id,
    this.name,
    this.logoUrl,
    this.sportType,
    this.sportDesc,
    this.colorCode,
    this.jerseyUrl,
    this.inningsId,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
        id: json['id'],
        name: json['name'],
        logoUrl: json['logoUrl'],
        sportType: json['sportType'],
        sportDesc: json['sportDesc'],
        colorCode: json['colorCode'],
        jerseyUrl: json['jerseyUrl'],
        inningsId: json['inningsId']);
  }
}
