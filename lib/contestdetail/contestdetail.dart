import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';

class ContestDetail extends StatefulWidget {
  final League league;
  final Contest contest;

  final L1 l1Data;
  final List<MyTeam> myTeams;

  ContestDetail({this.league, this.l1Data, this.contest, this.myTeams});

  @override
  State<StatefulWidget> createState() => ContestDetailState();
}

class ContestDetailState extends State<ContestDetail> {
  L1 _l1Data;
  String cookie;
  List<MyTeam> _myTeams;
  Map<String, dynamic> l1UpdatePackate = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  initState() {
    super.initState();
    sockets.register(_onWsMsg);

    _createL1WSObject();

    if (widget.myTeams == null || widget.l1Data == null) {
      _getL1Data();
    } else {
      _l1Data = widget.l1Data;
      _myTeams = widget.myTeams;
    }
  }

  _createL1WSObject() {
    l1UpdatePackate["iType"] = 5;
    l1UpdatePackate["sportsId"] = 1;
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["id"] = widget.league.leagueId;
  }

  _getL1Data() {
    sockets.sendMessage(l1UpdatePackate);
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["iType"] == 5 && _response["bSuccessful"] == true) {
      setState(() {
        _l1Data = L1.fromJson(_response["data"]["l1"]);
        _myTeams = (_response["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
      });
    } else if (_response["iType"] == 4 && _response["bSuccessful"] == true) {
      _applyL1DataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == 7 && _response["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(_response["data"]);
      setState(() {
        _myTeams.add(teamAdded);
      });
    } else if (_response["iType"] == 6 && _response["bSuccessful"] == true) {
      _updateJoinCount(_response["data"]);
    }
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    for (Contest _contest in _l1Data.contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
        });
      }
    }
  }

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      _l1Data.contests.addAll(_data["lstAdded"]);
    }
    if (_data["lstModified"] != null && _data["lstModified"].length > 0) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in _l1Data.contests) {
          if (_contest.id == _changedContest["id"]) {
            setState(() {
              _contest.joined = _changedContest["joined"];
            });
          }
        }
      }
    }
  }

  _onJoinContest(Contest contest) async {
    if (_myTeams != null && _myTeams.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            contest: contest,
            myTeams: _myTeams,
            onCreateTeam: _onCreateTeam,
            matchId: _l1Data.league.rounds[0].matches[0].id,
            onError: _onJoinContestError,
          );
        },
      );

      if (result != null) {
        _scaffoldKey.currentState
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

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: _l1Data,
            ),
      ),
    );

    if (result != null) {
      Navigator.of(context).pop();
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        _onJoinContest(curContest);
      }
    }
  }

  _onJoinContestError(Contest contest, Map<String, dynamic> errorResponse) {
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
            message: "Alert",
            title: "User is not verified.",
          );
          break;
      }
    }
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
              child: Text("OK"),
            )
          ],
        );
      },
    );
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
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    final result = await Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => AddCash(
              cookie: cookie,
            ),
        fullscreenDialog: true));
    if (result == true) {
      _onJoinContest(curContest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Contest details"),
      ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: LeagueCard(widget.league, clickable: false),
                ),
              ],
            ),
            Divider(
              color: Colors.black12,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    "₹" +
                                        widget.contest
                                            .prizeDetails[0]["totalPrizeAmount"]
                                            .toString(),
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontSize: Theme.of(context)
                                            .primaryTextTheme
                                            .display1
                                            .fontSize),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              child: Tooltip(
                                message: "Number of winners.",
                                child: FlatButton(
                                  padding: EdgeInsets.all(0.0),
                                  onPressed: () {},
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.0),
                                            child: Text(
                                              "WINNERS",
                                              style: TextStyle(
                                                color: Colors.black45,
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .caption
                                                    .fontSize,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16.0,
                                            color: Colors.black26,
                                          )
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(widget.contest
                                              .prizeDetails[0]["noOfPrizes"]
                                              .toString())
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              child: Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: RaisedButton(
                                  onPressed: () {
                                    _onJoinContest(widget.contest);
                                  },
                                  color: Theme.of(context).primaryColorDark,
                                  child: Text(
                                    "₹" + widget.contest.entryFee.toString(),
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 5.0),
                                    child: widget.contest.bonusAllowed > 0
                                        ? Row(
                                            children: <Widget>[
                                              Tooltip(
                                                message: "You can use " +
                                                    widget.contest.bonusAllowed
                                                        .toString() +
                                                    "% of entry fee amount from bonus.",
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4.0),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    maxRadius: 10.0,
                                                    child: Text(
                                                      "B",
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .caption
                                                              .fontSize),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                widget.contest.bonusAllowed
                                                        .toString() +
                                                    "% bonus allowed.",
                                                style: TextStyle(
                                                    fontSize: Theme.of(context)
                                                        .primaryTextTheme
                                                        .caption
                                                        .fontSize),
                                              ),
                                            ],
                                          )
                                        : Container(),
                                  ),
                                  Container(
                                    child: widget.contest.teamsAllowed > 1
                                        ? Row(
                                            children: <Widget>[
                                              Tooltip(
                                                message:
                                                    "You can participate with " +
                                                        widget.contest
                                                            .teamsAllowed
                                                            .toString() +
                                                        " different teams.",
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4.0),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    maxRadius: 10.0,
                                                    child: Text(
                                                      "M",
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .caption
                                                              .fontSize),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Maximum " +
                                                    widget.contest.teamsAllowed
                                                        .toString() +
                                                    " entries allowed.",
                                                style: TextStyle(
                                                    fontSize: Theme.of(context)
                                                        .primaryTextTheme
                                                        .caption
                                                        .fontSize),
                                              )
                                            ],
                                          )
                                        : Container(),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                widget.contest.joined.toString() +
                                    "/" +
                                    widget.contest.size.toString() +
                                    " joined",
                                textAlign: TextAlign.right,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.black12,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }
}
