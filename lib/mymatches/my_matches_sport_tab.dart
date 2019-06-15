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

class MyMatchesSportsTabState extends State<MyMatchesSportsTab>
    with SingleTickerProviderStateMixin {
  int selectedSegment = 1;
  TabController _statusController;
  Map<String, int> status = {"UPCOMING": 1, "LIVE": 2, "COMPLETED": 3};

  @override
  void initState() {
    _statusController = TabController(vsync: this, length: 3);
    _statusController.addListener(() {
      setState(() {
        selectedSegment = _statusController.index + 1;
      });
    });
    super.initState();
  }

  getTabView(int index) {
    final noLeaguesMsg = index == LeagueStatus.COMPLETED
        ? strings.get("NO_COMPLETED_CONTEST")
        : index == LeagueStatus.LIVE
            ? strings.get("NO_RUNNING_CONTEST")
            : strings.get("NO_UPCOMING_CONTEST");

    return Column(
      children: <Widget>[
        widget.myLeagues[index].length > 0
            ? Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        index == 1
                            ? "Upcoming Matches"
                            : index == 2 ? "Live Matches" : "Completed Matches",
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
        widget.myLeagues[index].length == 0
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
        widget.myLeagues[index].length == 0
            ? Container()
            : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.myLeagues[index].map((League league) {
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

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
            child: TabBar(
              controller: _statusController,
              isScrollable: false,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(18.0),
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).primaryColor,
              labelStyle: Theme.of(context).primaryTextTheme.subhead,
              tabs: status.keys.map<Tab>((page) {
                return Tab(
                  text: page,
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _statusController,
            children: <Widget>[
              getTabView(1),
              getTabView(2),
              getTabView(3),
            ],
          ),
        ),
      ],
    );
  }
}
