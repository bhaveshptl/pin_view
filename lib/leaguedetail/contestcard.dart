import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/leaguedetail/contestcards/live.dart';
import 'package:playfantasy/leaguedetail/contestcards/result.dart';
import 'package:playfantasy/leaguedetail/contestcards/upcoming.dart';

class ContestCard extends StatelessWidget {
  final L1 l1Data;
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onClick;
  final bool isMyContest;
  final bool bShowBrandInfo;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry radius;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;

  ContestCard({
    this.l1Data,
    this.onJoin,
    this.league,
    this.radius,
    this.contest,
    this.onClick,
    this.margin,
    this.isMyContest,
    this.myJoinedTeams,
    this.onPrizeStructure,
    this.bShowBrandInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: contest.id.toString() + " - " + contest.name,
      child: Card(
        elevation: 3.0,
        shape: radius != null
            ? RoundedRectangleBorder(borderRadius: radius)
            : null,
        margin: margin == null ? EdgeInsets.all(0.0) : margin,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: FlatButton(
          onPressed: () {
            onClick(contest, league);
          },
          padding: EdgeInsets.all(8.0),
          child: (l1Data != null &&
                      l1Data.league.status == LeagueStatus.UPCOMING) ||
                  (l1Data == null && league.status == LeagueStatus.UPCOMING)
              ? UpcomingContest(
                  league: league,
                  onJoin: onJoin,
                  contest: contest,
                  isMyContest: isMyContest,
                  myJoinedTeams: myJoinedTeams,
                  bShowBrandInfo: bShowBrandInfo,
                  onPrizeStructure: onPrizeStructure,
                )
              : (l1Data != null && l1Data.league.status == LeagueStatus.LIVE) ||
                      (l1Data == null && league.status == LeagueStatus.LIVE)
                  ? LiveContest(
                      league: league,
                      contest: contest,
                      isMyContest: isMyContest,
                      myJoinedTeams: myJoinedTeams,
                      onPrizeStructure: onPrizeStructure,
                    )
                  : ResultContest(
                      league: league,
                      contest: contest,
                      isMyContest: isMyContest,
                      myJoinedTeams: myJoinedTeams,
                      onPrizeStructure: onPrizeStructure,
                    ),
        ),
      ),
    );
  }
}
