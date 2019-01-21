import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/commonwidgets/prizestructure.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/commonwidgets/epoc.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/leaguedetail/prediction/predictioncontestcard.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class MyContestLeagueCard extends StatefulWidget {
  final League league;
  final MyAllContest mapContests;
  final Function onContestDetails;
  final Function onJoinNormalContest;
  final Function onJoinPredictionContest;
  final Map<int, List<MyTeam>> mapMyTeams;
  final Map<int, List<int>> mapMySheetIds;
  final Function onPredictionContestDetail;

  MyContestLeagueCard({
    this.league,
    this.mapMyTeams,
    this.mapContests,
    this.mapMySheetIds,
    this.onContestDetails,
    this.onJoinNormalContest,
    this.onJoinPredictionContest,
    this.onPredictionContestDetail,
  });

  @override
  MyContestLeagueCardState createState() {
    return new MyContestLeagueCardState();
  }
}

class MyContestLeagueCardState extends State<MyContestLeagueCard>
    with SingleTickerProviderStateMixin {
  bool bIsExpanded = false;
  TabController typeController;
  int activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    typeController = TabController(vsync: this, length: 2);
    typeController.addListener(() {
      if (!typeController.indexIsChanging) {
        setState(() {
          activeTabIndex = typeController.index;
        });
      }
    });
  }

  void _showPredictionPrizeStructure(Contest contest) async {
    List<dynamic> prizeStructure = await _getPredictionPrizeStructure(contest);
    if (prizeStructure != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return PrizeStructure(
            contest: contest,
            prizeStructure: prizeStructure,
          );
        },
      );
    }
  }

  _getPredictionPrizeStructure(Contest contest) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl.apiUrl +
          ApiUtil.GET_PREDICTION_PRIZESTRUCTURE +
          contest.id.toString()),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        } else {
          return Future.value(null);
        }
      },
    );
  }

  void _showPrizeStructure(Contest contest) async {
    List<dynamic> prizeStructure = await _getPrizeStructure(contest);
    if (prizeStructure != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return PrizeStructure(
            contest: contest,
            prizeStructure: prizeStructure,
          );
        },
      );
    }
  }

  _getPrizeStructure(Contest contest) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl.apiUrl +
          ApiUtil.GET_PRIZESTRUCTURE +
          contest.id.toString() +
          "/prizestructure"),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        }
      },
    );
  }

  List<Widget> getNormalContests() {
    if (widget.mapContests.normal.length == 0) {
      return [
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "You have not any joined contests for this match.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .primaryTextTheme
                      .subtitle
                      .copyWith(color: Colors.red),
                ),
              ),
            )
          ],
        )
      ];
    } else {
      return widget.mapContests.normal.map((contest) {
        return ContestCard(
          contest: contest,
          isMyContest: true,
          league: widget.league,
          status: widget.league.status,
          onClick: widget.onContestDetails,
          onJoin: widget.onJoinNormalContest,
          onPrizeStructure: _showPrizeStructure,
          myJoinedTeams:
              widget.mapMyTeams == null ? [] : widget.mapMyTeams[contest.id],
          margin: EdgeInsets.symmetric(vertical: 8.0),
        );
      }).toList();
    }
  }

  List<Widget> getPredictionContests() {
    if (widget.mapContests.prediction.length == 0) {
      return [
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                "You have not any joined contests for this match prediction.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .primaryTextTheme
                    .subtitle
                    .copyWith(color: Colors.red),
              ),
            )
          ],
        )
      ];
    } else {
      return widget.mapContests.prediction.map((contest) {
        return PredictionContestCard(
          contest: contest,
          isMyContest: true,
          league: widget.league,
          status: widget.league.status,
          onJoin: widget.onJoinPredictionContest,
          onClick: widget.onPredictionContestDetail,
          margin: EdgeInsets.symmetric(vertical: 8.0),
          onPrizeStructure: _showPredictionPrizeStructure,
          myJoinedSheetIds: widget.mapMySheetIds == null
              ? []
              : widget.mapMySheetIds[contest.id],
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    int cntContests =
        widget.mapContests.normal.length + widget.mapContests.prediction.length;
    double width = MediaQuery.of(context).size.width;
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 12.0,
                                        right: 16.0,
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2.0),
                                            child: CachedNetworkImage(
                                              imageUrl: widget.league.teamA !=
                                                      null
                                                  ? widget.league.teamA.logoUrl
                                                  : "",
                                              placeholder: Container(
                                                padding: EdgeInsets.all(4.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                ),
                                                width: TEAM_LOGO_HEIGHT,
                                                height: TEAM_LOGO_HEIGHT,
                                              ),
                                              height: TEAM_LOGO_HEIGHT,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              widget.league.teamA.name,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Expanded(
                              // flex: 2,
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    widget.league.matchName,
                                    style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .fontSize,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(top: 6.0, bottom: 6.0),
                                    child: Text(
                                      "vs",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .fontSize,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(
                                          Icons.alarm,
                                          size: 16.0,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      widget.league.status ==
                                              LeagueStatus.UPCOMING
                                          ? EPOC(
                                              timeInMiliseconds:
                                                  widget.league.matchStartTime,
                                            )
                                          : (widget.league.status ==
                                                  LeagueStatus.LIVE
                                              ? Text("LIVE")
                                              : Text("COMPLETED")),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: 12.0,
                                    left: 16.0,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(2.0),
                                        child: CachedNetworkImage(
                                          imageUrl: widget.league.teamB != null
                                              ? widget.league.teamB.logoUrl
                                              : null,
                                          placeholder: Container(
                                            padding: EdgeInsets.all(4.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                            ),
                                            width: TEAM_LOGO_HEIGHT,
                                            height: TEAM_LOGO_HEIGHT,
                                          ),
                                          height: TEAM_LOGO_HEIGHT,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          widget.league.teamB.name,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Divider(
            height: 2.0,
            color: Colors.black12,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 32.0,
                  child: FlatButton(
                    onPressed: () {
                      setState(() {
                        bIsExpanded = !bIsExpanded;
                      });
                    },
                    padding: EdgeInsets.all(0.0),
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            cntContests.toString() + " contests joined.",
                          ),
                          Icon(bIsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bIsExpanded
              ? Container(
                  color: Colors.black12.withAlpha(15),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(
                                width: width,
                                child: CupertinoSegmentedControl<int>(
                                  children: {
                                    0: Text("Match"),
                                    1: Text("Prediction"),
                                  },
                                  borderColor:
                                      Theme.of(context).primaryColorDark,
                                  selectedColor: Theme.of(context)
                                      .primaryColorDark
                                      .withAlpha(240),
                                  onValueChanged: (int newValue) {
                                    setState(() {
                                      activeTabIndex = newValue;
                                    });
                                  },
                                  groupValue: activeTabIndex,
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                        children: activeTabIndex == 0
                                            ? getNormalContests()
                                            : getPredictionContests()),
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
        ],
      ),
    );
  }
}
