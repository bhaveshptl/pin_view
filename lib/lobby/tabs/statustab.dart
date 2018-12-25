import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/leaguedetail/leaguedetail.dart';

class StatusTab extends StatelessWidget {
  final int sportType;
  final int leagueStatus;
  final Function onSportChange;
  final List<League> allLeagues;
  final List<League> statusLeagues;

  StatusTab({
    this.sportType,
    this.allLeagues,
    this.leagueStatus,
    this.statusLeagues,
    this.onSportChange,
  });

  onLeagueSelect(BuildContext context, League league) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => LeagueDetail(
              league,
              leagues: allLeagues,
              sportType: sportType,
              onSportChange: onSportChange,
            ),
      ),
    );
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
              style: Theme.of(context).primaryTextTheme.title.copyWith(
                    color: Theme.of(context).errorColor,
                  ),
            ),
          ],
        ),
      );
    }
  }
}
