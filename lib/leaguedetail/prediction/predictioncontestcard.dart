import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/leaguedetail/prediction/contestcards/live_prediction.dart';
import 'package:playfantasy/leaguedetail/prediction/contestcards/result_prediction.dart';
import 'package:playfantasy/leaguedetail/prediction/contestcards/upcoming_prediction.dart';

class PredictionContestCard extends StatelessWidget {
  final int status;
  final League league;
  final Contest contest;
  final Function onJoin;
  final Function onClick;
  final bool isMyContest;
  final bool bShowBrandInfo;
  final List<MySheet> myAllSheets;
  final Prediction predictionData;
  final EdgeInsetsGeometry margin;
  final Function onPrizeStructure;
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
    this.myAllSheets,
    this.isMyContest,
    this.myJoinedSheets,
    this.predictionData,
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
      child: Column(
        children: <Widget>[
          contest.brand != null && bShowBrandInfo
              ? Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          CachedNetworkImage(
                            imageUrl: contest.brand["brandLogoUrl"],
                            width: 32.0,
                            placeholder: (context, string) {
                              return Container(
                                padding: EdgeInsets.all(4.0),
                                width: 32.0,
                                height: 32.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    contest.brand["info"],
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0),
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
                padding: EdgeInsets.all(0.0),
                child: leagueStatus == LeagueStatus.UPCOMING
                    ? UpcomingPrediction(
                        league: league,
                        onJoin: onJoin,
                        contest: contest,
                        myJoinedSheets: myJoinedSheets,
                        onPrizeStructure: onPrizeStructure,
                      )
                    : leagueStatus == LeagueStatus.LIVE
                        ? LivePrediction(
                            league: league,
                            contest: contest,
                            myJoinedSheets: myJoinedSheets,
                            onPrizeStructure: onPrizeStructure,
                          )
                        : ResultPrediction(
                            league: league,
                            contest: contest,
                            myJoinedSheets: myJoinedSheets,
                            onPrizeStructure: onPrizeStructure,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
