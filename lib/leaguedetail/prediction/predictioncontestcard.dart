import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/leaguedetail/contestcards/live.dart';
import 'package:playfantasy/leaguedetail/contestcards/result.dart';
import 'package:playfantasy/leaguedetail/prediction/contestcards/upcoming.dart';

class PredictionContestCard extends StatelessWidget {
  final int status;
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onClick;
  final bool isMyContest;
  final bool bShowBrandInfo;
  final Prediction predictionData;
  final EdgeInsetsGeometry margin;
  final Function onPrizeStructure;
  final List<int> myJoinedSheetIds;
  final BorderRadiusGeometry radius;
  final List<MySheet> myJoinedSheets;

  PredictionContestCard({
    this.onJoin,
    this.league,
    this.radius,
    this.margin,
    this.status,
    this.contest,
    this.onClick,
    this.isMyContest,
    this.myJoinedSheets,
    this.predictionData,
    this.myJoinedSheetIds,
    this.onPrizeStructure,
    this.bShowBrandInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    int leagueStatus = status != null
        ? status
        : (((predictionData != null &&
                    predictionData.league.status == LeagueStatus.UPCOMING) ||
                (league != null && league.status == LeagueStatus.UPCOMING))
            ? LeagueStatus.UPCOMING
            : (((predictionData != null &&
                        predictionData.league.status == LeagueStatus.LIVE) ||
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
              ? UpcomingPredictionContest(
                  league: league,
                  onJoin: onJoin,
                  contest: contest,
                  myJoinedSheets: myJoinedSheets,
                  bShowBrandInfo: bShowBrandInfo,
                  myJoinedSheetIds: myJoinedSheetIds,
                  onPrizeStructure: onPrizeStructure,
                )
              : leagueStatus == LeagueStatus.LIVE
                  ? LiveContest(
                      league: league,
                      contest: contest,
                      isMyContest: isMyContest,
                      // myJoinedTeams: myJoinedSheets,
                      onPrizeStructure: onPrizeStructure,
                    )
                  : ResultContest(
                      league: league,
                      contest: contest,
                      isMyContest: isMyContest,
                      // myJoinedTeams: myJoinedSheets,
                      onPrizeStructure: onPrizeStructure,
                    ),
        ),
      ),
    );
  }
}
