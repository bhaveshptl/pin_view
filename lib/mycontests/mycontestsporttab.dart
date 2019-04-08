import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/joincontest/joincontest.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/mycontests/myconteststatustab.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/joinpredictioncontest.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/createsheet.dart';
import 'package:playfantasy/leaguedetail/prediction/predictioncontestdetails.dart';

class MyContestSportTab extends StatefulWidget {
  final int sportsType;
  final int currentStauts;
  final bool showStatusBar;
  final Function showLoader;
  final List<League> leagues;
  final Map<int, List<MyTeam>> mapMyTeams;
  final Map<int, List<MySheet>> mapMySheets;
  final Map<String, MyAllContest> myContests;
  final GlobalKey<ScaffoldState> scaffoldKey;

  MyContestSportTab({
    this.leagues,
    this.showLoader,
    this.sportsType,
    this.myContests,
    this.mapMyTeams,
    this.mapMySheets,
    this.scaffoldKey,
    this.currentStauts,
    this.showStatusBar = true,
  });

  @override
  MyContestSportTabState createState() => MyContestSportTabState();
}

class MyContestSportTabState extends State<MyContestSportTab> {
  L1 l1Data;

  Contest _curContest;
  int selectedSegment = 0;
  Contest _curPredictionContest;
  bool bShowJoinContest = false;
  bool bShowJoinPredictionContest = false;

  List<MySheet> mySheets;
  Prediction predictionData;
  List<MyTeam> leagueAllMyTeams;
  Map<String, dynamic> l1DataObj = {};

  Map<String, MyAllContest> _mapLiveContest = {};
  Map<String, MyAllContest> _mapResultContest = {};
  Map<String, MyAllContest> _mapUpcomingContest = {};

  StreamSubscription _streamSubscription;

  @override
  initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    if (!widget.showStatusBar) {
      selectedSegment = widget.currentStauts - 1;
    }
  }

  League _getLeague(int _leagueId) {
    for (League _league in widget.leagues) {
      if (_league.leagueId == _leagueId) {
        return _league;
      }
    }
    return null;
  }

  getLeagueStatus(int leagueId) {}

  setContestsByStatus(Map<String, MyAllContest> _mapMyContests) {
    Map<String, MyAllContest> mapLiveContest = {};
    Map<String, MyAllContest> mapResultContest = {};
    Map<String, MyAllContest> mapUpcomingContest = {};
    _mapMyContests.forEach((String key, MyAllContest _contests) {
      League league = _getLeague(int.parse(key));
      if (league != null) {
        if (league.status == LeagueStatus.UPCOMING) {
          mapUpcomingContest[key] = _contests;
        } else if (league.status == LeagueStatus.LIVE) {
          mapLiveContest[key] = _contests;
        } else if (league.status == LeagueStatus.COMPLETED) {
          mapResultContest[key] = _contests;
        }
      }
    });

    List<String> upcomingKeys = mapUpcomingContest.keys.toList();
    upcomingKeys.sort((a, b) {
      League leagueA = _getLeague(int.parse(a));
      League leagueB = _getLeague(int.parse(b));
      int leagueAStartTime = leagueA != null ? leagueA.matchStartTime : 0;
      int leagueBStartTime = leagueB != null ? leagueB.matchStartTime : 0;
      return leagueAStartTime - leagueBStartTime;
    });

    List<String> liveKeys = mapLiveContest.keys.toList();
    liveKeys.sort((a, b) {
      League leagueA = _getLeague(int.parse(a));
      League leagueB = _getLeague(int.parse(b));
      int leagueAStartTime = leagueA != null ? leagueA.matchStartTime : 0;
      int leagueBStartTime = leagueB != null ? leagueB.matchStartTime : 0;
      return leagueBStartTime - leagueAStartTime;
    });

    List<String> resultKeys = mapResultContest.keys.toList();
    resultKeys.sort((a, b) {
      League leagueA = _getLeague(int.parse(a));
      League leagueB = _getLeague(int.parse(b));
      int leagueAEndTime = leagueA != null ? leagueA.matchEndTime : 0;
      int leagueBEndTime = leagueB != null ? leagueB.matchEndTime : 0;
      return leagueBEndTime - leagueAEndTime;
    });
    _mapUpcomingContest = {};
    _mapLiveContest = {};
    _mapResultContest = {};

    setState(() {
      upcomingKeys.forEach((key) {
        _mapUpcomingContest[key] = mapUpcomingContest[key];
      });

      liveKeys.forEach((key) {
        _mapLiveContest[key] = mapLiveContest[key];
      });

      resultKeys.forEach((key) {
        _mapResultContest[key] = mapResultContest[key];
      });
    });
  }

  _onWsMsg(data) {
    if ((data["iType"] == RequestType.GET_ALL_L1 ||
            data["iType"] == RequestType.REQ_L1_INNINGS_ALL_DATA) &&
        data["bSuccessful"] == true) {
      l1Data = L1.fromJson(data["data"]["l1"]);
      leagueAllMyTeams = (data["data"]["myteams"] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      if (data["data"]["prediction"] != null) {
        predictionData = Prediction.fromJson(data["data"]["prediction"]);
      }
      if (data["data"]["mySheets"] != null && data["data"]["mySheets"] != "") {
        mySheets = (data["data"]["mySheets"] as List<dynamic>).map((f) {
          return MySheet.fromJson(f);
        }).toList();
      }
      if (bShowJoinContest) {
        joinContest(_curContest);
      } else if (bShowJoinPredictionContest) {
        joinPredictionContest(_curPredictionContest);
      }
    }
  }

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => ContestDetail(
              league: league,
              contest: contest,
              mapContestTeams: widget.mapMyTeams[contest.id],
            ),
      ),
    );
  }

  _onPredictionContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => PredictionContestDetail(
              league: league,
              contest: contest,
              mapContestSheets: widget.mapMySheets[contest.id],
            ),
      ),
    );
  }

  _createL1WSObject(Contest contest) {
    if (contest != null && contest.realTeamId != null) {
      l1DataObj["id"] = contest.leagueId;
      l1DataObj["teamId"] = contest.realTeamId;
      l1DataObj["sportsId"] = widget.sportsType;
      l1DataObj["inningsId"] = contest.inningsId;
      l1DataObj["iType"] = RequestType.REQ_L1_INNINGS_ALL_DATA;
    } else {
      l1DataObj["iType"] = RequestType.GET_ALL_L1;
      l1DataObj["bResAvail"] = true;
      l1DataObj["withPrediction"] = true;
      l1DataObj["id"] = contest.leagueId;
      l1DataObj["sportsId"] = widget.sportsType;
    }
  }

  _onJoinContest(Contest contest) async {
    _curContest = contest;
    bShowJoinContest = true;
    _createL1WSObject(contest);
    FantasyWebSocket().sendMessage(l1DataObj);
  }

  _onJoinPredictionContest(Contest contest) async {
    _curPredictionContest = contest;
    bShowJoinPredictionContest = true;
    _createL1WSObject(contest);
    FantasyWebSocket().sendMessage(l1DataObj);
  }

  joinPredictionContest(Contest contest) async {
    _curPredictionContest = null;
    bShowJoinPredictionContest = false;
    if (mySheets.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinPredictionContest(
            contest: contest,
            mySheets: mySheets,
            prediction: predictionData,
            onError: onJoinContestError,
            onCreateSheet: _onCreateSheet,
          );
        },
      );

      if (result != null) {
        final response = json.decode(result);
        widget.scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text(response["message"]),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(strings.get("ALERT").toUpperCase()),
            content: Text(
              "No sheet created for this match. Please create one to join contest.",
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  strings.get("CANCEL").toUpperCase(),
                ),
              ),
              FlatButton(
                onPressed: () {
                  _onCreateSheet(context, contest);
                },
                child: Text(strings.get("CREATE").toUpperCase()),
              )
            ],
          );
        },
      );
    }
  }

  joinContest(Contest contest) async {
    _curContest = null;
    bShowJoinContest = false;
    if (leagueAllMyTeams.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            l1Data: l1Data,
            contest: contest,
            onCreateTeam: _onCreateTeam,
            onError: onJoinContestError,
            myTeams: leagueAllMyTeams,
          );
        },
      );

      if (result != null) {
        widget.scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text("$result")));
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(strings.get("ALERT").toUpperCase()),
            content: Text(
              strings.get("CREATE_TEAM_WARNING"),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  strings.get("CANCEL").toUpperCase(),
                ),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _onCreateTeam(context, contest);
                },
                child: Text(strings.get("CREATE").toUpperCase()),
              )
            ],
          );
        },
      );
    }
  }

  void _onCreateSheet(BuildContext context, Contest contest) async {
    final curContest = contest;
    Navigator.of(context).pop();
    final league = _getLeague(contest.leagueId);
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateSheet(
              league: league,
              predictionData: predictionData,
              mode: SheetCreationMode.CREATE_SHEET,
            ),
      ),
    );

    if (result != null) {
      if (curContest != null) {
        _onJoinPredictionContest(curContest);
      }
      widget.scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  onStateDobUpdate(String msg) {
    widget.scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
  }

  _showAddCashConfirmation(Contest contest) {
    final curContest = contest;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            strings.get("INSUFFICIENT_FUND").toUpperCase(),
          ),
          content: Text(
            strings.get("INSUFFICIENT_FUND_MSG"),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                strings.get("CANCEL").toUpperCase(),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchDepositJourneyForJoinContest(curContest);
              },
              child: Text(
                strings.get("DEPOSIT").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }

  _launchDepositJourneyForJoinContest(Contest contest) async {
    final curContest = contest;
    widget.showLoader(true);
    routeLauncher.launchAddCash(context, onSuccess: (result) {
      if (result != null) {
        _onJoinContest(curContest);
      }
    }, onComplete: () {
      widget.showLoader(false);
    });
  }

  _showJoinContestError({String title, String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }

  onJoinContestError(Contest contest, Map<String, dynamic> errorResponse) {
    JoinContestError error;
    if (errorResponse["error"] == true) {
      error = JoinContestError([errorResponse["resultCode"]]);
    } else {
      error = JoinContestError(errorResponse["reasons"]);
    }

    Navigator.of(context).pop();
    if (error.isBlockedUser()) {
      _showJoinContestError(
        title: error.getTitle(),
        message: error.getErrorMessage(),
      );
    } else {
      int errorCode = error.getErrorCode();
      switch (errorCode) {
        case 3:
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StateDob();
            },
          );
          break;
        case 12:
          _showAddCashConfirmation(contest);
          break;
        case 6:
          _showJoinContestError(
            message: strings.get("ALERT"),
            title: strings.get("NOT_VERIFIED"),
          );
          break;
      }
    }
  }

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;
    final league = _getLeague(contest.leagueId);
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: league,
              l1Data: l1Data,
            ),
      ),
    );

    if (result != null) {
      Navigator.of(context).pop();
      widget.scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        _onJoinContest(curContest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.myContests == null) {
      return Container();
    }
    setContestsByStatus(widget.myContests);
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: <Widget>[
        widget.showStatusBar
            ? Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Container(
                  height: 40.0,
                  width: width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedSegment = 0;
                            });
                          },
                          child: Container(
                            height: 40.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedSegment == 0
                                  ? Theme.of(context).primaryColor
                                  : null,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Text(
                              "Upcoming",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    selectedSegment == 0 ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedSegment = 1;
                            });
                          },
                          child: Container(
                            height: 40.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedSegment == 1
                                  ? Theme.of(context).primaryColor
                                  : null,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Text(
                              "Live",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    selectedSegment == 1 ? Colors.white : null,
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
                            height: 40.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedSegment == 2
                                  ? Theme.of(context).primaryColor
                                  : null,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Text(
                              "Completed",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    selectedSegment == 2 ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  selectedSegment == 0
                      ? "Upcoming Matches"
                      : selectedSegment == 1
                          ? "Live Matches"
                          : "Completed Matches",
                  style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: MyContestStatusTab(
            leagues: widget.leagues,
            mapContests: selectedSegment == 0
                ? _mapUpcomingContest
                : (selectedSegment == 1 ? _mapLiveContest : _mapResultContest),
            tabStatus: selectedSegment + 1,
            mapMyTeams: widget.mapMyTeams,
            mapMySheets: widget.mapMySheets,
            onContestDetails: _onContestClick,
            onJoinNormalContest: _onJoinContest,
            leagueContests: !widget.showStatusBar,
            onJoinPredictionContest: _onJoinPredictionContest,
            onPredictionContestDetails: _onPredictionContestClick,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
