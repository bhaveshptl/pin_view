class League {
  final int matchId;
  final String matchName;
  final int status;
  final int prediction;
  final int leagueId;
  final int matchStartTime;
  final int matchEndTime;
  final Series series;
  final Team teamA;
  final Team teamB;

  League(
      {this.matchId,
      this.matchName,
      this.status,
      this.prediction,
      this.leagueId,
      this.matchStartTime,
      this.matchEndTime,
      this.series,
      this.teamA,
      this.teamB});

  factory League.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return League();
    } else {
      return League(
          matchId: json['matchId'],
          matchName: json['matchName'],
          status: json['status'],
          prediction: json['prediction'],
          leagueId: json['leagueId'],
          matchStartTime: json['matchStartTime'],
          matchEndTime: json['matchEndTime'],
          series: Series.fromJson(json['series']),
          teamA: Team.fromJson(json['teamA']),
          teamB: Team.fromJson(json['teamB']));
    }
  }
}

class LeagueStatus {
  static const int UPCOMING = 1;
  static const int LIVE = 2;
  static const int COMPLETED = 3;
}

class Series {
  final String seriesTypeInfo;
  final int seriesTypeId;
  final int id;
  final String name;
  final String info;
  final int startDate;
  final int endDate;
  final int countryId;
  Series(
      {this.seriesTypeInfo,
      this.seriesTypeId,
      this.id,
      this.name,
      this.info,
      this.startDate,
      this.endDate,
      this.countryId});

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
        seriesTypeInfo: json['seriesTypeInfo'],
        seriesTypeId: json['seriesTypeId'],
        id: json['id'],
        name: json['name'],
        info: json['info'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        countryId: json['countryId']);
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
  Team({
    this.id,
    this.name,
    this.sportType,
    this.sportDesc,
    this.colorCode,
    this.logoUrl,
    this.jerseyUrl,
    this.inningsId,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
        id: json['id'],
        name: json['name'],
        sportType: json['sportType'],
        sportDesc: json['sportDesc'],
        colorCode: json['colorCode'],
        logoUrl: json['logoUrl'],
        jerseyUrl: json['jerseyUrl'],
        inningsId: json['inningsId']);
  }
}
