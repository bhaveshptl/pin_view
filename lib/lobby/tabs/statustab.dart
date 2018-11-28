import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/leaguedetail/leaguedetail.dart';

class StatusTab extends StatelessWidget {
  final int leagueStatus;
  final Function onSportChange;
  final List<League> allLeagues;
  final List<League> statusLeagues;

  StatusTab({
    this.statusLeagues,
    this.leagueStatus,
    this.onSportChange,
    this.allLeagues,
  });

  onLeagueSelect(BuildContext context, League league) {
    MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => LeagueDetail(
              league,
              leagues: allLeagues,
              onSportChange: onSportChange,
            ));
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final noLeaguesMsg = leagueStatus == LeagueStatus.COMPLETED
        ? strings.get("NO_COMPLETED_MATCHES")
        : leagueStatus == LeagueStatus.LIVE
            ? strings.get("NO_RUNNING_MATCHES")
            : strings.get("NO_UPCOMING_MATCHES");

    if (statusLeagues.length > 0) {
      return ListView.builder(
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
        itemCount: statusLeagues.length,
        itemBuilder: (context, index) {
          return LeagueCard(
            statusLeagues[index],
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
                fontSize: Theme.of(context).primaryTextTheme.headline.fontSize,
              ),
            ),
          ],
        ),
      );
    }
  }
}
