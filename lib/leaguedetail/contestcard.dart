import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/leaguedetail/contestcards/live.dart';
import 'package:playfantasy/leaguedetail/contestcards/result.dart';
import 'package:playfantasy/leaguedetail/contestcards/upcoming.dart';

class ContestCard extends StatelessWidget {
  final L1 l1Data;
  final int status;
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onClick;
  final bool isMyContest;
  final bool bShowBrandInfo;
  final EdgeInsetsGeometry margin;
  final Function onPrizeStructure;
  final List<MyTeam> myJoinedTeams;
  final BorderRadiusGeometry radius;

  ContestCard({
    this.l1Data,
    this.onJoin,
    this.league,
    this.radius,
    this.margin,
    this.status,
    this.contest,
    this.onClick,
    this.isMyContest,
    this.myJoinedTeams,
    this.onPrizeStructure,
    this.bShowBrandInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    int leagueStatus = status != null
        ? status
        : (((l1Data != null && l1Data.league.status == LeagueStatus.UPCOMING) ||
                (league != null && league.status == LeagueStatus.UPCOMING))
            ? LeagueStatus.UPCOMING
            : (((l1Data != null && l1Data.league.status == LeagueStatus.LIVE) ||
                    (league != null && league.status == LeagueStatus.LIVE))
                ? LeagueStatus.LIVE
                : LeagueStatus.COMPLETED));
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
          child: leagueStatus == LeagueStatus.UPCOMING
              ? UpcomingContest(
                  league: league,
                  onJoin: onJoin,
                  contest: contest,
                  isMyContest: isMyContest,
                  myJoinedTeams: myJoinedTeams,
                  bShowBrandInfo: bShowBrandInfo,
                  onPrizeStructure: onPrizeStructure,
                )
              : leagueStatus == LeagueStatus.LIVE
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
