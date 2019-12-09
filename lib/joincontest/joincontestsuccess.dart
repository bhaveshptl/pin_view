import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/leaguedetail/contestcards/upcoming_howzat.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';

class JoinContestSuccess extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final String successMessage;
  final String launchPageSource;
  final List<MyTeam> myTeams;
  final Map<String, dynamic> balance;
  final Function onJoin;
  final Map<int, List<MyTeam>> myContestJoinedTeams;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final int sportId;
  JoinContestSuccess({
    this.balance,
    this.league,
    this.l1Data,
    this.successMessage,
    this.launchPageSource,
    this.myTeams,
    this.sportId,
    this.myContestJoinedTeams,
    this.onJoin,
    this.scaffoldKey,
  });
  @override
  JoinContestSuccessState createState() => JoinContestSuccessState();
}

class JoinContestSuccessState extends State<JoinContestSuccess> {
  List<Contest> contestToCrossSell = [];

  @override
  void initState() {
    setCrossSellContests();
    super.initState();
  }

  onGoToLobbyPressed() async {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "joinContest";
    if (widget.launchPageSource == "l1") {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pop(data);
    }
  }

  onCreateTeamPressed() async {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "createTeam";
    Navigator.of(context).pop(data);
  }

  onClosePopup() {
    Map<String, dynamic> data = new Map();
    data["userOption"] = "onClosePressed";
    Navigator.of(context).pop(data);
  }

  setCrossSellContests() {
    Map<int, List<Contest>> priorityBrandContests = {};
    widget.l1Data.contests.forEach((contest) {
      if (widget.l1Data.league.priorityBrands != null &&
          widget.l1Data.league.priorityBrands.indexOf(contest.brand["id"]) !=
              -1 &&
          (widget.myContestJoinedTeams[contest.id] == null ||
              widget.myContestJoinedTeams[contest.id].length == 0)) {
        if (priorityBrandContests[contest.brand["id"]] == null) {
          priorityBrandContests[contest.brand["id"]] = [];
        }
        priorityBrandContests[contest.brand["id"]].add(contest);
      }
    });

    priorityBrandContests.keys.forEach((key) {
      priorityBrandContests[key].sort((a, b) {
        return a.entryFee - b.entryFee;
      });
    });

    List<Contest> lstContestsToSell = [];
    priorityBrandContests.keys.forEach((key) {
      List<Contest> contests = priorityBrandContests[key];
      int i = 0;
      for (; i < contests.length; i++) {
        if (contests[i].entryFee > widget.balance["cashBalance"]) {
          break;
        }
      }
      if (i == contests.length) {
        lstContestsToSell.add(contests[contests.length - 1]);
      } else {
        lstContestsToSell.add(contests[i]);
      }
    });

    contestToCrossSell = lstContestsToSell;
  }

  void _showPrizeStructure(Contest contest) async {
    List<dynamic> prizeStructure =
        await routeLauncher.getPrizeStructure(contest);

    if (prizeStructure != null) {
      showModalBottomSheet(
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      elevation: 0.0,
      titlePadding: EdgeInsets.all(0.0),
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: FittedBox(
                child: Text(
                  "Contest joined successfully!",
                  style: Theme.of(context).primaryTextTheme.display1.copyWith(
                        color: Color.fromRGBO(70, 165, 12, 1),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      contentPadding: EdgeInsets.all(0.0),
      content: contestToCrossSell.length == 0
          ? Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0, top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ColorButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "CLOSE",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      color: Color.fromRGBO(237, 237, 237, 1),
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 4.0),
                                child: Text(
                                  "Recommendations",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .copyWith(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: contestToCrossSell.map((contest) {
                              return Card(
                                child: UpcomingHowzatContest(
                                  contest: contest,
                                  onJoin: (Contest contest) {
                                    widget.onJoin(contest);
                                  },
                                  myJoinedTeams:
                                      widget.myContestJoinedTeams == null
                                          ? []
                                          : widget.myContestJoinedTeams[
                                              contest.id.toString()],
                                  onPrizeStructure: (Contest contest) {
                                    _showPrizeStructure(contest);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
