import 'package:flutter/material.dart';
import 'package:playfantasy/leaguedetail/inningdetail.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/l1.dart' as L1;

class Innings extends StatelessWidget {
  final L1.L1 l1Data;
  final League league;
  final List<League> leagues;
  final List<MyTeam> myTeams;
  final Function onSportChange;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<int, List<MyTeam>> mapContestTeams;

  Innings({
    this.league,
    this.l1Data,
    this.leagues,
    this.myTeams,
    this.scaffoldKey,
    this.onSportChange,
    this.mapContestTeams,
  });

  showInningDetails(BuildContext context, L1.Team team) async {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) => InningDetails(
              team: team,
              league: league,
              leagues: leagues,
              onSportChange: onSportChange,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Card(
              elevation: 6.0,
              child: FlatButton(
                onPressed: () {
                  showInningDetails(
                      context, l1Data.league.rounds[0].matches[0].teamA);
                },
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(
                        l1Data.league.rounds[0].matches[0].teamA.logoUrl,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                          l1Data.league.rounds[0].matches[0].teamA.name +
                              " " +
                              "INNING"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Card(
              elevation: 6.0,
              child: FlatButton(
                onPressed: () {
                  showInningDetails(
                      context, l1Data.league.rounds[0].matches[0].teamB);
                },
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(
                        l1Data.league.rounds[0].matches[0].teamB.logoUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                          l1Data.league.rounds[0].matches[0].teamB.name +
                              " " +
                              "INNING"),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
