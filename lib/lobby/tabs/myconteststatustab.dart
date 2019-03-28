import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class MyContestStatusTab extends StatefulWidget {
  final int sportsType;
  final int fantasyType;
  final int leagueStatus;
  final Function showLoader;
  final List<League> leagues;
  final Function onContestClick;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<int, List<MyTeam>> mapContestTeams;
  final Map<String, List<Contest>> mapMyContests;

  MyContestStatusTab({
    this.leagues,
    this.showLoader,
    this.sportsType,
    this.scaffoldKey,
    this.fantasyType,
    this.leagueStatus,
    this.mapMyContests,
    this.onContestClick,
    this.mapContestTeams,
  });

  @override
  _MyContestStatusTabState createState() => _MyContestStatusTabState();
}

class _MyContestStatusTabState extends State<MyContestStatusTab> {
  L1 _l1Data;
  String cookie;
  Contest _curContest;
  List<MyTeam> _myTeams;
  bool bShowJoinContest = false;
  Map<String, dynamic> l1DataObj = {};
  Map<String, List<Contest>> myContests;
  StreamSubscription _streamSubscription;

  @override
  initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  filterMyContests() {
    Map<String, List<Contest>> mapContests = {};
    widget.mapMyContests.forEach((String key, List<Contest> contests) {
      contests.forEach((Contest contest) {
        if ((widget.fantasyType == 1 &&
                (contest.inningsId == null || contest.inningsId == 0) ||
            (widget.fantasyType == 2 &&
                (contest.inningsId != null && contest.inningsId > 0)))) {
          if (mapContests[key] == null) {
            mapContests[key] = [];
          }
          mapContests[key].add(contest);
        }
      });
    });

    return mapContests;
  }

  _onWsMsg(data) {
    if ((data["iType"] == RequestType.GET_ALL_L1 ||
            data["iType"] == RequestType.REQ_L1_INNINGS_ALL_DATA) &&
        data["bSuccessful"] == true) {
      _l1Data = L1.fromJson(data["data"]["l1"]);
      _myTeams = (data["data"]["myteams"] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      if (bShowJoinContest) {
        joinContest(_curContest);
      }
    }
  }

  _getLeague(int _leagueId) {
    for (League _league in widget.leagues) {
      if (_league.leagueId == _leagueId) {
        return _league;
      }
    }
    return League(
      leagueId: _leagueId,
    );
  }

  _getMyContestCards() {
    final noLeaguesMsg = widget.leagueStatus == LeagueStatus.COMPLETED
        ? strings.get("NO_COMPLETED_CONTEST")
        : widget.leagueStatus == LeagueStatus.LIVE
            ? strings.get("NO_RUNNING_CONTEST")
            : strings.get("NO_UPCOMING_CONTEST");

    return myContests.keys.length == 0
        ? Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  noLeaguesMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).errorColor,
                    fontSize:
                        Theme.of(context).primaryTextTheme.headline.fontSize,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: myContests.keys.length,
            itemBuilder: (context, index) {
              List<Contest> _leagueContests =
                  myContests[myContests.keys.elementAt(index)];
              League _league = _getLeague(_leagueContests[0].leagueId);
              return _league == null
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Card(
                        elevation: 2.0,
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
                              child: _league.teamA != null
                                  ? Column(
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: CachedNetworkImage(
                                                imageUrl: _league.teamA.logoUrl,
                                                placeholder: Container(
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
                                            Text(
                                              _league.teamA.name +
                                                  " vs " +
                                                  _league.teamB.name,
                                              style: TextStyle(
                                                  color: Colors.black54),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: CachedNetworkImage(
                                                imageUrl: _league.teamB.logoUrl,
                                                placeholder: Container(
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
                                          ],
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: <Widget>[Text("Testing")],
                                    ),
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: _getContestsCard(
                                      _leagueContests,
                                      _league,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
            },
          );
  }

  List<Widget> _getContestsCard(List<Contest> _contests, League _league) {
    List<Widget> _cards = [];
    for (Contest _contest in _contests) {
      _cards.add(
        Row(
          children: <Widget>[
            Expanded(
              child: ContestCard(
                margin: EdgeInsets.all(8.0),
                league: _league,
                isMyContest: true,
                contest: _contest,
                bShowBrandInfo: true,
                onJoin: _onJoinContest,
                status: widget.leagueStatus,
                onClick: widget.onContestClick,
                onPrizeStructure: _showPrizeStructure,
                myJoinedTeams: widget.mapContestTeams[_contest.id],
              ),
            ),
          ],
        ),
      );
    }
    return _cards;
  }

  void _showPrizeStructure(Contest contest) async {
    List<dynamic> prizeStructure = await _getPrizeStructure(contest);

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

  _onJoinContest(Contest contest) async {
    _curContest = contest;
    bShowJoinContest = true;
    _createL1WSObject(contest);
    FantasyWebSocket().sendMessage(l1DataObj);
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

  joinContest(Contest contest) async {
    _curContest = null;
    bShowJoinContest = false;
    if (_myTeams.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            l1Data: _l1Data,
            contest: contest,
            myTeams: _myTeams,
            onCreateTeam: _onCreateTeam,
            onError: onJoinContestError,
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

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;
    final league = _getLeague(contest.leagueId);
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: league,
              l1Data: _l1Data,
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

  @override
  Widget build(BuildContext context) {
    myContests = filterMyContests();
    return Container(
      child: Center(
        child: _getMyContestCards(),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
