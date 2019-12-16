import 'dart:async';

import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/leaguedetail/contestcards/upcoming_howzat.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';

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
  final List<Contest> contests;
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
    this.contests,
  });
  @override
  JoinContestSuccessState createState() => JoinContestSuccessState();
}

class JoinContestSuccessState extends State<JoinContestSuccess> {
  List<Contest> contests;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    contests = widget.contests;
    super.initState();
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.L1_DATA_REFRESHED &&
        data["bSuccessful"] == true) {
      _applyL1DataUpdate(data["diffData"]["ld"]);
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _updateJoinCount(data["data"]);
    }
  }

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    List<Contest> _addedContests = [];
    List<Contest> _lstRemovedContests = [];
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      _addedContests =
          (_data["lstAdded"] as List).map((i) => Contest.fromJson(i)).toList();
      setState(() {
        for (Contest _contest in _addedContests) {
          bool bFound = false;
          for (Contest _curContest in widget.l1Data.contests) {
            if (_curContest.id == _contest.id) {
              bFound = true;
            }
          }
          if (!bFound && widget.l1Data.league.id == _contest.leagueId) {
            widget.l1Data.contests.add(_contest);
          }
        }
      });
    }
    if (_data["lstRemoved"] != null && _data["lstRemoved"].length > 0) {
      List<Contest> updatedContests = [];
      _lstRemovedContests = (_data["lstRemoved"] as List)
          .map((i) => Contest.fromJson(i))
          .toList();
      for (Contest _contest in widget.l1Data.contests) {
        bool bFound = false;
        for (Contest _removedContest in _lstRemovedContests) {
          if (_removedContest.id == _contest.id) {
            bFound = true;
          }
        }
        if (!bFound) {
          updatedContests.add(_contest);
        }
      }
      widget.l1Data.contests = updatedContests;
    }

    List<Contest> updatedSuggestedContests = [];
    contests.forEach((suggestedContest) {
      widget.l1Data.contests.forEach((contest) {
        if (contest.brand["id"] == suggestedContest.brand["id"] &&
            contest.entryFee == suggestedContest.entryFee) {
          updatedSuggestedContests.add(contest);
        }
      });
    });
    var maxLength = updatedSuggestedContests.length - 1;
    setState(() {
      contests =
          updatedSuggestedContests.getRange(0, maxLength > 2 ? 2 : maxLength);
    });
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    for (Contest _contest in widget.l1Data.contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
        });
      }
    }
    for (Contest _contest in contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
        });
      }
    }
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
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
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
      content: contests.length == 0
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
                            children: contests.map((contest) {
                              return contest.size == contest.joined
                                  ? Container()
                                  : Stack(
                                      children: <Widget>[
                                        Card(
                                          child: UpcomingHowzatContest(
                                            contest: contest,
                                            onJoin: (Contest contest) {
                                              widget.onJoin(contest);
                                            },
                                            myJoinedTeams: widget
                                                        .myContestJoinedTeams ==
                                                    null
                                                ? []
                                                : widget.myContestJoinedTeams[
                                                    contest.id.toString()],
                                            onPrizeStructure:
                                                (Contest contest) {
                                              _showPrizeStructure(contest);
                                            },
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Expanded(
                                              child: Container(),
                                            ),
                                            Expanded(
                                              child: Container(
                                                margin:
                                                    EdgeInsets.only(top: 8.0),
                                                child: FittedBox(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 2.0,
                                                            horizontal: 8.0),
                                                    decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade200,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    12.0)),
                                                    child: Text(
                                                        contest.brand["info"]),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(),
                                            ),
                                          ],
                                        ),
                                      ],
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
