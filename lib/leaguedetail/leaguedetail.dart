import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/createcontest.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/leaguedetail/myteams.dart';
import 'package:playfantasy/leaguedetail/contests.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class LeagueDetail extends StatefulWidget {
  final League league;
  final List<League> leagues;
  final Function onSportChange;

  LeagueDetail(this.league, {this.leagues, this.onSportChange});

  @override
  State<StatefulWidget> createState() => LeagueDetailState();
}

class LeagueDetailState extends State<LeagueDetail>
    with WidgetsBindingObserver {
  L1 l1Data;
  String cookie;
  List<MyTeam> _myTeams;
  String title = "Match";
  Map<String, dynamic> l1UpdatePackate = {};
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<String, List<Contest>> _mapMyContests = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _bShowLoader = false;

  _showLoader(bool bShow) {
    setState(() {
      _bShowLoader = bShow;
    });
  }

  @override
  initState() {
    super.initState();
    sockets.register(_onWsMsg);
    _createL1WSObject();

    _getL1Data();
    _getMyContests();
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      _showLoader(true);
      _getL1Data();
    } else if (_response["iType"] == 5 && _response["bSuccessful"] == true) {
      setState(() {
        l1Data = L1.fromJson(_response["data"]["l1"]);
        _myTeams = (_response["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
      });
      _showLoader(false);
    } else if (_response["iType"] == 4 && _response["bSuccessful"] == true) {
      _applyL1DataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == 7 && _response["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(_response["data"]);
      setState(() {
        _myTeams.add(teamAdded);
      });
    } else if (_response["iType"] == 6 && _response["bSuccessful"] == true) {
      _updateJoinCount(_response["data"]);
    } else if (_response["iType"] == 8 && _response["bSuccessful"] == true) {
      MyTeam teamUpdated = MyTeam.fromJson(_response["data"]);
      int i = 0;
      for (MyTeam _team in _myTeams) {
        if (_team.id == teamUpdated.id) {
          setState(() {
            _myTeams[i] = teamUpdated;
          });
        }
        i++;
      }
    }
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    for (Contest _contest in l1Data.contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
        });
      }
    }
  }

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      l1Data.contests
          .addAll((_data["lstAdded"] as List).map((i) => Contest.fromJson(i)));
    }
    if (_data["lstModified"] != null && _data["lstModified"].length > 0) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in l1Data.contests) {
          if (_contest.id == _changedContest["id"]) {
            setState(() {
              _contest.joined = _changedContest["joined"];
            });
          }
        }
      }
    }
  }

  _createL1WSObject() {
    l1UpdatePackate["iType"] = 5;
    l1UpdatePackate["sportsId"] = 1;
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["id"] = widget.league.leagueId;
  }

  _getL1Data() {
    _showLoader(true);
    sockets.sendMessage(l1UpdatePackate);
  }

  _getMyContests() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return new http.Client().get(
      ApiUtil.GET_MY_CONTESTS,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
      if (res.statusCode == 200) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          _mapMyContests = MyContest.fromJson(response).leagues;
          _getMyContestMyTeams(_mapMyContests);
        });
      }
    });
  }

  _getMyContestMyTeams(Map<String, List<Contest>> _mapMyContests) async {
    List<int> _contestIds = [];
    List<Contest> _contests = _mapMyContests[widget.league.leagueId.toString()];
    if (_contests != null) {
      for (Contest contest in _contests) {
        _contestIds.add(contest.id);
      }

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
  }

  _launchAddCash() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => AddCash(
              cookie: cookie,
            ),
        fullscreenDialog: true));
  }

  _onNavigationSelectionChange(BuildContext context, int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => MyTeams(
                    league: widget.league,
                    l1Data: l1Data,
                    myTeams: _myTeams,
                  )));
          break;
        case 2:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MyContests(
                  leagues: widget.leagues,
                  onSportChange: widget.onSportChange,
                ),
          ));
          break;
        case 3:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CreateContest(widget.league),
          ));
          break;
        case 4:
          _launchAddCash();
          break;
      }
    });
  }

  _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                    child: Text(
                      "Coming Soon!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
              Text(
                  "We are currently working on this feature and will launch soon.")
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(title),
            actions: <Widget>[
              Tooltip(
                message: "Contest filter",
                child: IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
              )
            ],
          ),
          body: l1Data == null
              ? Container()
              : Contests(
                  l1Data: l1Data,
                  myTeams: _myTeams,
                  league: widget.league,
                  scaffoldKey: _scaffoldKey,
                  mapContestTeams: _mapContestTeams,
                ),
          bottomNavigationBar:
              LobbyBottomNavigation(_onNavigationSelectionChange, 1),
        ),
        _bShowLoader
            ? Center(
                child: Container(
                  color: Colors.black54,
                  child: Loader(),
                  constraints: BoxConstraints.expand(),
                ),
              )
            : Container(),
      ],
    );
  }
}
