import 'package:flutter/material.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/mymatches/joined_contests.dart';
import 'package:playfantasy/utils/stringtable.dart';

class MyMatchesSportsTab extends StatefulWidget {
  final int sportsType;
  final Function onLeagueStatusChange;
  final Map<int, List<League>> myLeagues;
  final Map<String, dynamic> myContestIds;
  MyMatchesSportsTab({
    this.sportsType,
    this.myLeagues,
    this.myContestIds,
    this.onLeagueStatusChange,
  });

  @override
  MyMatchesSportsTabState createState() => MyMatchesSportsTabState();
}

class MyMatchesSportsTabState extends State<MyMatchesSportsTab> {
  int selectedSegment = 1;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final noLeaguesMsg = selectedSegment == LeagueStatus.COMPLETED
        ? strings.get("NO_COMPLETED_CONTEST")
        : selectedSegment == LeagueStatus.LIVE
            ? strings.get("NO_RUNNING_CONTEST")
            : strings.get("NO_UPCOMING_CONTEST");

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Container(
            height: 40.0,
            width: width * 0.8,
            padding: EdgeInsets.all(2.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    color: Colors.black.withAlpha(15),
                  ),
                ]),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedSegment = 1;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(2.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedSegment == 1
                            ? Color.fromRGBO(150, 27, 24, 1)
                            : null,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Text(
                        "Upcoming",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: selectedSegment == 1
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedSegment = 2;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedSegment == 2
                            ? Color.fromRGBO(150, 27, 24, 1)
                            : null,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Text(
                        "Live",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: selectedSegment == 2
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedSegment = 3;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedSegment == 3
                            ? Color.fromRGBO(150, 27, 24, 1)
                            : null,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Text(
                        "Completed",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: selectedSegment == 3
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        widget.myLeagues[selectedSegment].length > 0
            ? Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        selectedSegment == 1
                            ? "Upcoming Matches"
                            : selectedSegment == 2
                                ? "Live Matches"
                                : "Completed Matches",
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    )
                  ],
                ),
              )
            : Container(),
        widget.myLeagues[selectedSegment].length == 0
            ? Padding(
                padding: EdgeInsets.only(top: 32.0, left: 16.0, right: 16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        noLeaguesMsg,
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Theme.of(context).errorColor,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ))
            : Container(),
        widget.myLeagues[selectedSegment].length == 0
            ? Container()
            : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        widget.myLeagues[selectedSegment].map((League league) {
                      return LeagueCard(
                        league,
                        contestCount:
                            widget.myContestIds[league.leagueId.toString()] ==
                                    null
                                ? 0
                                : widget
                                    .myContestIds[league.leagueId.toString()]
                                    .length,
                        onTimeComplete: widget.onLeagueStatusChange,
                        onClick: (League league) {
                          ActionUtil().showLoader(context, true);
                          Navigator.of(context).push(
                            FantasyPageRoute(
                              pageBuilder: (BuildContext context) =>
                                  JoinedContests(
                                    league: league,
                                    sportsType: widget.sportsType,
                                  ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
      ],
    );
  }
}
