import 'dart:convert';
import 'package:share/share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/viewteam.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/contestdetail/switchteam.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/commonwidgets/prizestructure.dart';

const TABLE_COLUMN_PADDING = 28;

class ContestDetail extends StatefulWidget {
  final League league;
  final Contest contest;
  final List<MyTeam> mapContestTeams;

  final L1 l1Data;
  final List<MyTeam> myTeams;

  ContestDetail(
      {this.league,
      this.l1Data,
      this.contest,
      this.myTeams,
      this.mapContestTeams});

  @override
  State<StatefulWidget> createState() => ContestDetailState();
}

class ContestDetailState extends State<ContestDetail> {
  L1 _l1Data;
  String cookie;
  int _sportType = 1;
  List<MyTeam> _myTeams;
  int _curPageOffset = 0;
  final int rowsPerPage = 10;
  TeamsDataSource _teamsDataSource;
  List<MyTeam> _mapContestTeams = [];
  Map<String, dynamic> l1UpdatePackate = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool bShowJoinContest = false;
  bool bWaitingForTeamCreation = false;

  @override
  initState() {
    super.initState();
    sockets.register(_onWsMsg);

    _createAndReqL1WS();
    _mapContestTeams =
        widget.mapContestTeams == null ? [] : widget.mapContestTeams;
    _teamsDataSource = TeamsDataSource(widget.league, widget.contest,
        widget.myTeams, _onViewTeam, _onSwitchTeam);
    _teamsDataSource.setMyContestTeams(widget.contest, _mapContestTeams);
    _teamsDataSource.changeLeagueStatus(widget.league.status);
    _getContestTeams(0);
  }

  _createAndReqL1WS() async {
    await _getSportsType();

    l1UpdatePackate["iType"] = 5;
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["sportsId"] = _sportType;
    l1UpdatePackate["id"] = widget.league.leagueId;

    if (widget.myTeams == null || widget.l1Data == null) {
      _getL1Data();
    } else {
      _l1Data = widget.l1Data;
      _myTeams = widget.myTeams;
    }
  }

  _getL1Data() {
    sockets.sendMessage(l1UpdatePackate);
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        _sportType = int.parse(value);
      }
    });
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["iType"] == 5 && _response["bSuccessful"] == true) {
      setState(() {
        _l1Data = L1.fromJson(_response["data"]["l1"]);
        _myTeams = (_response["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
        _teamsDataSource.updateMyAllTeams(_myTeams);
      });
    } else if (_response["iType"] == 4 && _response["bSuccessful"] == true) {
      _applyL1DataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == 7 && _response["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(_response["data"]);
      setState(() {
        bool bFound = false;
        for (MyTeam _myTeam in _myTeams) {
          if (_myTeam.id == teamAdded.id) {
            bFound = true;
          }
        }
        if (!bFound) {
          _myTeams.add(teamAdded);
          _teamsDataSource.updateMyAllTeams(_myTeams);
        }
        if (bShowJoinContest) {
          _onJoinContest(widget.contest);
        }
        bWaitingForTeamCreation = false;
      });
    } else if (_response["iType"] == 6 && _response["bSuccessful"] == true) {
      _updateJoinCount(_response["data"]);
      _updateContestTeams(_response["data"]);
    }
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    if (widget.contest.id == _data["cId"]) {
      setState(() {
        widget.contest.joined = _data["iJC"];
      });
    }
  }

  _updateContestTeams(Map<String, dynamic> _data) {
    Map<String, dynamic> _mapContestTeamsUpdate = _data["teamsByContest"];
    _mapContestTeamsUpdate.forEach((String key, dynamic _contestTeams) {
      List<MyTeam> _teams = (_mapContestTeamsUpdate[key] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      setState(() {
        _mapContestTeams = _teams;
        _teamsDataSource.updateMyContestTeam(widget.contest, _mapContestTeams);
        if (_curPageOffset > (widget.contest.joined - rowsPerPage)) {
          _getContestTeams(_curPageOffset);
        }
      });
    });
  }

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      List<Contest> _addedContests =
          (_data["lstAdded"] as List).map((i) => Contest.fromJson(i)).toList();
      setState(() {
        for (Contest _contest in _addedContests) {
          bool bFound = false;
          for (Contest _curContest in _l1Data.contests) {
            if (_curContest.id == _contest.id) {
              bFound = true;
            }
          }
          if (!bFound && _l1Data.league.id == _contest.leagueId) {
            _l1Data.contests.add(_contest);
          }
        }
      });
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

  void _onSwitchTeam(MyTeam _team, List<MyTeam> myUniqueTeams) async {
    if (myUniqueTeams.length > 0) {
      final String result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SwitchTeam(
            myTeams: _myTeams,
            oldTeam: _team,
            l1Data: widget.l1Data,
            contest: widget.contest,
            contestMyTeams: widget.mapContestTeams,
          );
        },
      );

      if (result != null) {
        Map<String, dynamic> res = json.decode(result);
        String message = res["msg"];
        if (!res["error"]) {
          updateTeams(res["oldTeam"], res["newTeam"]);
        }
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text("$message")));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(
            strings.get("SWITCH_TEAM_NOT_AVAIL"),
          ),
        ),
      );
    }
  }

  updateTeams(int oldTeam, int newTeam) {
    MyTeam teamToReplace;
    _myTeams.forEach((MyTeam team) {
      if (team.id == newTeam) {
        teamToReplace = team;
      }
    });
    for (int i = 0; i < _mapContestTeams.length; i++) {
      if (_mapContestTeams[i].id == oldTeam) {
        _mapContestTeams[i] = teamToReplace;
      }
    }

    _teamsDataSource.updateMyContestTeam(widget.contest, _mapContestTeams);
    _getContestTeams(_curPageOffset);
  }

  void _onViewTeam(MyTeam _team) {
    Navigator.of(context).push(
      new MaterialPageRoute(
          builder: (context) => ViewTeam(
                team: _team,
                l1Data: _l1Data,
                myTeam: _myTeams,
                league: widget.league,
                contest: widget.contest,
              ),
          fullscreenDialog: true),
    );
  }

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;

    bWaitingForTeamCreation = true;

    Navigator.of(context).pop();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: _l1Data,
            ),
      ),
    );

    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        if (bWaitingForTeamCreation) {
          bShowJoinContest = true;
        } else {
          _onJoinContest(curContest);
        }
      }
      Navigator.of(context).pop();
    }
    bWaitingForTeamCreation = false;
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
            message: strings.get("ALERT"),
            title: strings.get("NOT_VERIFIED"),
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
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
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

  _shareContestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            FlatButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: widget.contest.contestJoinCode),
                );
                _scaffoldKey.currentState.showSnackBar(
                  SnackBar(
                    content: Text(strings.get("CONTEST_COPIED")),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.content_copy),
                  ),
                  Text(
                    strings.get("COPY_CONTEST_CODE").toUpperCase(),
                  ),
                ],
              ),
            ),
            FlatButton(
              onPressed: () {
                String contestVisibility =
                    widget.contest.visibilityId == 1 ? "PUBLIC" : "PRIVATE";
                String contestCode = widget.contest.contestJoinCode;
                String inviteMsg =
                    "PLAY FANTASY - $contestVisibility LEAGUE \nHey! I created a Contest for our folks to play. Use this contest code $contestCode and join us.";

                Navigator.of(context).pop();
                Share.share(inviteMsg);
              },
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.share),
                  ),
                  Text("SHARE NOW"),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  _getContestTeams(int offset) async {
    _curPageOffset = offset;
    int teamListOffset = offset;
    if (offset == 0) {
      _teamsDataSource.setTeams(offset, _mapContestTeams);
    } else {
      teamListOffset = offset - _mapContestTeams.length;
    }

    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client().get(
      ApiUtil.GET_CONTEST_TEAMS +
          widget.contest.id.toString() +
          "/teams/" +
          teamListOffset.toString() +
          "/" +
          (offset == 0
              ? (rowsPerPage - _mapContestTeams.length).toString()
              : rowsPerPage.toString()),
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          List<dynamic> response = json.decode(res.body);
          List<MyTeam> _teams =
              response.map((i) => MyTeam.fromJson(i)).toList();
          _teamsDataSource.setTeams(
              offset == 0 ? (offset + _mapContestTeams.length) : offset,
              _teams);
        }
      },
    );
  }

  List<DataColumn> _getDataTableHeader() {
    double width = MediaQuery.of(context).size.width - 20.0;
    List<DataColumn> _header = [
      DataColumn(
        onSort: (int index, bool bIsAscending) {},
        label: Container(
          padding: EdgeInsets.only(right: 4.0),
          width: width - (TABLE_COLUMN_PADDING * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: Text(
                  strings.get("TEAMS"),
                ),
              ),
              widget.league.status == LeagueStatus.COMPLETED ||
                      widget.league.status == LeagueStatus.LIVE
                  ? Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 50.0,
                            child: Text(
                              strings.get("SCORE").toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50.0,
                            child: Text(
                              strings.get("RANK").toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          widget.league.status == LeagueStatus.COMPLETED
                              ? Container(
                                  width: 50.0,
                                  child: Text(
                                    strings.get("PRIZE").toUpperCase(),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    ];

    return _header;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool bIsContestFull = (_mapContestTeams != null &&
            widget.contest.teamsAllowed <= _mapContestTeams.length) ||
        widget.contest.size == widget.contest.joined ||
        widget.league.status == LeagueStatus.LIVE ||
        widget.league.status == LeagueStatus.COMPLETED;

    _teamsDataSource.setWidth(width);
    _teamsDataSource.setContext(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("CONTEST_DETAILS"),
        ),
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
                                        (widget.contest.prizeDetails != null
                                            ? widget
                                                .contest
                                                .prizeDetails[0]
                                                    ["totalPrizeAmount"]
                                                .toString()
                                            : 0.toString()),
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
                                message: strings.get("NO_OF_WINNERS"),
                                child: FlatButton(
                                  padding: EdgeInsets.all(0.0),
                                  onPressed: () {
                                    _showPrizeStructure();
                                  },
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
                                              strings
                                                  .get("WINNERS")
                                                  .toUpperCase(),
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
                                          Text(widget.contest.prizeDetails ==
                                                  null
                                              ? 0.toString()
                                              : widget.contest
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
                                    if (!bIsContestFull) {
                                      _onJoinContest(widget.contest);
                                    }
                                  },
                                  color: bIsContestFull
                                      ? Theme.of(context).disabledColor
                                      : Theme.of(context).primaryColorDark,
                                  child: Row(
                                    children: <Widget>[
                                      _mapContestTeams != null &&
                                              _mapContestTeams.length > 0
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Icon(
                                                Icons.add,
                                                color: Colors.white70,
                                                size: 20.0,
                                              ),
                                            )
                                          : Container(),
                                      Text(
                                        strings.rupee +
                                            widget.contest.entryFee.toString(),
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 5.0),
                                      child: widget.contest.bonusAllowed > 0
                                          ? Row(
                                              children: <Widget>[
                                                Tooltip(
                                                  message: strings
                                                      .get("USE_BONUS")
                                                      .replaceAll(
                                                          "\$bonusPercent",
                                                          widget.contest
                                                              .bonusAllowed
                                                              .toString()),
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
                                                            color:
                                                                Colors.white70,
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
                                                      strings.get(
                                                          "PERCENT_BONUS_ALLOWED"),
                                                  style: TextStyle(
                                                      fontSize:
                                                          Theme.of(context)
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
                                                  message: strings
                                                      .get("PARTICIPATE_WITH")
                                                      .replaceAll(
                                                          "count",
                                                          widget.contest
                                                              .teamsAllowed
                                                              .toString()),
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
                                                            color:
                                                                Colors.white70,
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
                                                  strings
                                                      .get("MAXIMUM_ENTRY")
                                                      .replaceAll(
                                                          "\$count",
                                                          widget.contest
                                                              .teamsAllowed
                                                              .toString()),
                                                  style: TextStyle(
                                                      fontSize:
                                                          Theme.of(context)
                                                              .primaryTextTheme
                                                              .caption
                                                              .fontSize),
                                                )
                                              ],
                                            )
                                          : Container(),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                child: IconButton(
                                  icon: Icon(Icons.share),
                                  onPressed: () {
                                    _shareContestDialog(context);
                                  },
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
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: widget.contest.joined,
                    child: Container(
                      height: 4.0,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: widget.contest.size,
                    child: Container(
                      height: 4.0,
                      color: Colors.black12,
                    ),
                  )
                ],
              ),
            ),
            Divider(
              height: 2.0,
              color: Colors.black12,
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  widget.contest.joined == 0
                      ? Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 64.0, 16.0, 64.0),
                          child: Center(
                            child: Text(
                              strings.get("NO_JOINED"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).errorColor,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .fontSize),
                            ),
                          ),
                        )
                      : PaginatedDataTable(
                          header: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                strings.get("LEADERBOARD"),
                              ),
                              IconButton(
                                icon: Icon(Icons.file_download),
                                onPressed: () {},
                              )
                            ],
                          ),
                          rowsPerPage: (widget.contest.joined +
                                      _mapContestTeams.length) <
                                  rowsPerPage
                              ? (widget.contest.joined == 0
                                  ? 1
                                  : (widget.contest.joined +
                                      _mapContestTeams.length))
                              : rowsPerPage,
                          onPageChanged: (int firstVisibleIndex) {
                            _getContestTeams(firstVisibleIndex);
                          },
                          columns: _getDataTableHeader(),
                          source: _teamsDataSource,
                        ),
                ],
              ),
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

  void _showPrizeStructure() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PrizeStructure(
          contest: widget.contest,
        );
      },
    );
  }
}

class TeamsDataSource extends DataTableSource {
  int size;
  double width;
  League league;
  Contest contest;
  int _leagueStatus;
  Function onViewTeam;
  BuildContext context;
  Function onSwitchTeam;
  List<MyTeam> _teams = [];
  List<MyTeam> myContestTeams;
  List<MyTeam> _myAllTeams = [];
  List<MyTeam> _myUniqueTeams = [];

  TeamsDataSource(League _league, Contest _contest, List<MyTeam> myAllTeams,
      Function _onViewTeam, Function _onSwitchTeam) {
    league = _league;
    this.contest = _contest;
    onViewTeam = _onViewTeam;
    this.size = _contest.size;
    onSwitchTeam = _onSwitchTeam;
    this._myAllTeams = myAllTeams;
    _leagueStatus = _league.status;
  }

  setMyContestTeams(Contest contest, List<MyTeam> _myContestTeams) {
    this.size = contest.joined + _myContestTeams.length;
    myContestTeams = _myContestTeams;
    for (int i = 0; i < size; i++) {
      if (i < _myContestTeams.length) {
        _teams.add(_myContestTeams[i]);
      } else {
        _teams.add(MyTeam());
      }
    }

    setUniqueTeams();
  }

  updateMyContestTeam(Contest contest, List<MyTeam> _myContestTeams) {
    this.size = contest.joined + _myContestTeams.length;
    myContestTeams = _myContestTeams;

    setUniqueTeams();
    this.notifyListeners();
  }

  updateMyAllTeams(List<MyTeam> _teams) {
    _myAllTeams = _teams;

    setUniqueTeams();
    notifyListeners();
  }

  changeLeagueStatus(int _status) {
    _leagueStatus = _status;
  }

  setUniqueTeams() {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in (_myAllTeams == null ? [] : _myAllTeams)) {
      bool bIsTeamUsed = false;
      for (MyTeam contestTeam in myContestTeams) {
        if (team.id == contestTeam.id) {
          bIsTeamUsed = true;
          break;
        }
      }
      if (!bIsTeamUsed) {
        myUniqueTeams.add(team);
      }
    }
    _myUniqueTeams = myUniqueTeams;
  }

  setContext(BuildContext context) {
    this.context = context;
  }

  setWidth(double width) {
    this.width = width;
  }

  setTeams(int offset, List<MyTeam> _teams) {
    int curIndex = 0;
    int length = offset + _teams.length;
    for (int i = offset; i < length; i++) {
      if (this._teams.length <= i) {
        this._teams.add(MyTeam());
      }
      this._teams[i] = _teams[curIndex];
      curIndex++;
    }
    this.notifyListeners();
  }

  void updateTeams(int oldTeam, int newTeam) {
    _teams.forEach((MyTeam team) {
      if (team.id == oldTeam) {}
    });
  }

  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    if (index >= _teams.length) return null;
    final MyTeam _team = _teams[index];

    return DataRow.byIndex(
      index: index,
      cells: _getBody(_team, index < myContestTeams.length),
    );
  }

  List<DataCell> _getBody(MyTeam _team, bool bIsMyJoinedTeam) {
    List<DataCell> _header = [
      DataCell(
        Container(
          width: width - (TABLE_COLUMN_PADDING * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: Text(_team.name == null ? "" : _team.name),
              ),
              _leagueStatus == LeagueStatus.UPCOMING
                  ? Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        bIsMyJoinedTeam
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  width: 72.0,
                                  child: OutlineButton(
                                    padding: EdgeInsets.all(0.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                    color: Theme.of(context).primaryColorDark,
                                    onPressed: () {
                                      onSwitchTeam(_team, _myUniqueTeams);
                                    },
                                    child: Text(
                                      strings.get("SWITCH").toUpperCase(),
                                      style: TextStyle(fontSize: 10.0),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        bIsMyJoinedTeam
                            ? Icon(Icons.chevron_right)
                            : Container(),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Container(
                          width: 50.0,
                          child: Text(
                            _team.score != null ? _team.score.toString() : "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 50.0,
                          child: Text(
                            _team.score != null ? _team.rank.toString() : "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _leagueStatus == LeagueStatus.COMPLETED
                            ? Container(
                                width: 50.0,
                                child: Text(
                                  _team.score != null
                                      ? _team.prize.toString()
                                      : "-",
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(),
                        _team.score != null
                            ? Icon(Icons.chevron_right)
                            : Container(
                                width: 20.0,
                              )
                      ],
                    ),
            ],
          ),
        ),
        onTap: () {
          if (_team != null &&
              _team.id != null &&
              ((bIsMyJoinedTeam && _leagueStatus == LeagueStatus.UPCOMING) ||
                  _leagueStatus != LeagueStatus.UPCOMING)) {
            onViewTeam(_team);
          }
        },
      ),
    ];

    return _header;
  }

  @override
  int get rowCount => size;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
