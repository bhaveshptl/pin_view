import 'package:flutter/material.dart';
import 'package:playfantasy/leaguedetail/leaguedetail.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';

class StatusTab extends StatelessWidget {
  final int leagueStatus;
  final List<League> leagues;

  StatusTab({this.leagues, this.leagueStatus});

  onLeagueSelect(BuildContext context, League league) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LeagueDetail(league)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noLeaguesMsg = leagueStatus == LeagueStatus.COMPLETED
        ? "There are no completed matches."
        : leagueStatus == LeagueStatus.LIVE
            ? "There are no running matches."
            : "There are no upcoming matches.";

    if (leagues.length > 0) {
      return ListView.builder(
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          return LeagueCard(
            leagues[index],
            onClick: (league) {
              onLeagueSelect(context, league);
            },
          );
        },
      );
    } else {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              noLeaguesMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).errorColor,
                fontSize: Theme.of(context).primaryTextTheme.display1.fontSize,
              ),
            ),
          ],
        ),
      );
    }
  }
}
