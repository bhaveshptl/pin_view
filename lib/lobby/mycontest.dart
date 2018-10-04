import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/lobby/tabs/myconteststatustab.dart';

class MyContests extends StatefulWidget {
  final List<League> leagues;
  final Function onSportChange;

  MyContests({this.leagues, this.onSportChange});

  @override
  MyContestsState createState() {
    return new MyContestsState();
  }
}

class MyContestsState extends State<MyContests> {
  String cookie;
  int _sportType = 1;
  List<League> _leagues = [];
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<String, List<Contest>> _mapLiveContest = {};
  Map<String, List<Contest>> _mapResultContest = {};
  Map<String, List<Contest>> _mapUpcomingContest = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getMyContests();
    _leagues = widget.leagues;
    sockets.register(_onWsMsg);
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);
    if (_response["iType"] == 1 && _response["bSuccessful"] == true) {
      List<dynamic> _mapLeagues = json.decode(_response["data"]);
      List<League> leagues =
          _mapLeagues.map((i) => League.fromJson(i)).toList();
      setState(() {
        _leagues = leagues;
      });
    } else if (_response["iType"] == 2 && _response["bSuccessful"] == true) {
    } else if (_response["iType"] == 6 && _response["bSuccessful"] == true) {
      _update(_response["data"]);
    }
  }

  _update(Map<String, dynamic> _data) {
    _mapUpcomingContest.forEach((String key, List<Contest> _contests) {
      _updateContestJoinCount(_data, _contests);
    });
  }

  _updateContestJoinCount(Map<String, dynamic> _data, List<Contest> _contests) {
    for (Contest _contest in _contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
        });
      }
    }
  }

  _getMyContests({bool checkForPrevSelection = true}) async {
    if (checkForPrevSelection == true) {
      await _getSportsType();
    }
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client().get(
      ApiUtil.GET_MY_CONTESTS + _sportType.toString(),
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
      if (res.statusCode == 200) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          Map<String, List<Contest>> _mapMyContests =
              MyContest.fromJson(response).leagues;
          _getMyContestMyTeams(_mapMyContests);
          _setContestsByStatus(_mapMyContests);
        });
      }
    });
  }

  _getSportsType() async {
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getSportsType();
    await futureCookie.then((value) {
      int _sport = int.parse(value);
      if (_sport != _sportType) {
        setState(() {
          _sportType = _sport;
        });
      }
    });
  }

  _setContestsByStatus(Map<String, List<Contest>> _mapMyContests) {
    Map<String, List<Contest>> mapLiveContest = {};
    Map<String, List<Contest>> mapResultContest = {};
    Map<String, List<Contest>> mapUpcomingContest = {};
    _mapMyContests.forEach((String key, List<Contest> _contests) {
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
    setState(() {
      _mapLiveContest = mapLiveContest;
      _mapResultContest = mapResultContest;
      _mapUpcomingContest = mapUpcomingContest;
    });
  }

  _getMyContestMyTeams(Map<String, List<Contest>> _mapMyContests) async {
    List<int> _contestIds = [];
    _mapMyContests.forEach((String key, dynamic value) {
      List<Contest> _contests = _mapMyContests[key];
      for (Contest contest in _contests) {
        _contestIds.add(contest.id);
      }
    });

    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client()
        .post(
      ApiUtil.GET_MY_CONTEST_MY_TEAMS,
      headers: {'Content-type': 'application/json', "cookie": cookie},
      body: json.encoder.convert(_contestIds),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<int, List<MyTeam>> _mapContestMyTeams = {};
        Map<String, dynamic> response = json.decode(res.body);
        response.forEach((String key, dynamic value) {
          List<MyTeam> _myTeams =
              (value as List).map((i) => MyTeam.fromJson(i)).toList();
          _mapContestMyTeams[int.parse(key)] = _myTeams;
        });

        setState(() {
          _mapContestTeams = _mapContestMyTeams;
        });
      }
    });
  }

  _getLeague(int _leagueId) {
    for (League _league in _leagues) {
      if (_league.leagueId == _leagueId) {
        return _league;
      }
    }
    return null;
  }

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) => ContestDetail(
              league: league,
              contest: contest,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton(
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: Theme.of(context).primaryTextTheme.title.fontSize),
              onChanged: (value) {
                setState(() {
                  _sportType = value;

                  _getMyContests(checkForPrevSelection: false);
                });
                if (widget.onSportChange != null) {
                  widget.onSportChange(value);
                }
              },
              value: _sportType,
              items: [
                DropdownMenuItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 24.0),
                    child: Text(strings.get("CRICKET").toUpperCase()),
                  ),
                  value: 1,
                ),
                DropdownMenuItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 24.0),
                    child: Text(strings.get("FOOTBALL").toUpperCase()),
                  ),
                  value: 2,
                ),
                DropdownMenuItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 24.0),
                    child: Text(strings.get("KABADDI").toUpperCase()),
                  ),
                  value: 3,
                )
              ],
            ),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            new Container(
              constraints: BoxConstraints(maxHeight: 150.0),
              child: new Material(
                color: Theme.of(context).primaryColor,
                child: TabBar(
                  tabs: <Widget>[
                    Tooltip(
                      message: "Upcoming matches",
                      child: Tab(
                        text: strings.get("UPCOMING").toUpperCase(),
                      ),
                    ),
                    Tooltip(
                      message: "Live matches",
                      child: Tab(
                        text: strings.get("LIVE").toUpperCase(),
                      ),
                    ),
                    Tooltip(
                      message: "Completed matches",
                      child: Tab(
                        text: strings.get("RESULT").toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            new Expanded(
              flex: 1,
              child: TabBarView(
                children: <Widget>[
                  MyContestStatusTab(
                    leagues: _leagues,
                    scaffoldKey: _scaffoldKey,
                    onContestClick: _onContestClick,
                    mapContestTeams: _mapContestTeams,
                    mapMyContests: _mapUpcomingContest,
                    leagueStatus: LeagueStatus.UPCOMING,
                  ),
                  MyContestStatusTab(
                    leagues: _leagues,
                    scaffoldKey: _scaffoldKey,
                    mapMyContests: _mapLiveContest,
                    onContestClick: _onContestClick,
                    mapContestTeams: _mapContestTeams,
                    leagueStatus: LeagueStatus.LIVE,
                  ),
                  MyContestStatusTab(
                    leagues: _leagues,
                    scaffoldKey: _scaffoldKey,
                    onContestClick: _onContestClick,
                    mapMyContests: _mapResultContest,
                    mapContestTeams: _mapContestTeams,
                    leagueStatus: LeagueStatus.COMPLETED,
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
}
