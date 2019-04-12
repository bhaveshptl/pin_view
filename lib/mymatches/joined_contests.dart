import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class JoinedContests extends StatefulWidget {
  final League league;
  final int sportsType;

  JoinedContests({this.league, this.sportsType});

  @override
  JoinedContestsState createState() => JoinedContestsState();
}

class JoinedContestsState extends State<JoinedContests>
    with SingleTickerProviderStateMixin {
  L1 _l1Data;
  List<MyTeam> _myTeams;
  MyAllContest _myContests;
  GlobalKey<ScaffoldState> scaffoldKey;
  StreamSubscription _streamSubscription;
  Map<String, dynamic> l1UpdatePackate = {};
  Map<int, List<MyTeam>> _mapContestTeams = {};

  TabController tabController;

  @override
  void initState() {
    _getMyContests();
    _createL1WSObject();
    _getL1Data();
    scaffoldKey = GlobalKey<ScaffoldState>();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  _onWsMsg(data) {
    if (data["bReady"] == 1) {
      _getL1Data();
    } else if (data["iType"] == RequestType.GET_ALL_L1 &&
        data["bSuccessful"] == true) {
      setState(() {
        _l1Data = L1.fromJson(data["data"]["l1"]);
        _myTeams = (data["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
      });
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _updateJoinCount(data["data"]);
      _updateContestTeams(data["data"]);
    } else if (data["iType"] == RequestType.MY_TEAMS_ADDED &&
        data["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(data["data"]);
      bool bFound = false;
      for (MyTeam _myTeam in _myTeams) {
        if (_myTeam.id == teamAdded.id) {
          bFound = true;
        }
      }
      if (!bFound) {
        setState(() {
          _myTeams.add(teamAdded);
        });
      }
    } else if (data["iType"] == RequestType.MY_TEAM_MODIFIED &&
        data["bSuccessful"] == true) {
      MyTeam teamUpdated = MyTeam.fromJson(data["data"]);
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

  _createL1WSObject() async {
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["withPrediction"] = true;
    l1UpdatePackate["id"] = widget.league.leagueId;
    l1UpdatePackate["sportsId"] = widget.sportsType;
    l1UpdatePackate["iType"] = RequestType.GET_ALL_L1;
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

  _updateContestTeams(Map<String, dynamic> _data) {
    Map<String, dynamic> _mapContestTeamsUpdate = _data["teamsByContest"];
    _mapContestTeamsUpdate.forEach((String key, dynamic _contestTeams) {
      List<MyTeam> _teams = (_mapContestTeamsUpdate[key] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      setState(() {
        _mapContestTeams[int.parse(key)] = _teams;
      });
    });
  }

  _getL1Data() {
    FantasyWebSocket().sendMessage(l1UpdatePackate);
  }

  _getMyContests() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl().apiUrl +
          ApiUtil.GET_MY_ALL_CONTESTS +
          widget.sportsType.toString() +
          "/league/" +
          widget.league.leagueId.toString()),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          _myContests = NewMyContest.fromJson(response)
              .leagues[widget.league.leagueId.toString()];
        });

        _getMyContestMyTeams(_myContests);
        // _getMyContestMySheets(_myContests[_sportType]);
      }
    }).whenComplete(() {});
  }

  _getMyContestMyTeams(MyAllContest _mapMyContests) async {
    List<int> _contestIds = [];
    List<Contest> _contests =
        _mapMyContests == null ? [] : _mapMyContests.normal;
    for (Contest contest in _contests) {
      _contestIds.add(contest.id);
    }

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
    req.body = json.encode(_contestIds);
    return HttpManager(http.Client())
        .sendRequest(req)
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

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => ContestDetail(
              contest: contest,
              league: league,
              l1Data: _l1Data,
              myTeams: _myTeams,
              mapContestTeams: _mapContestTeams != null
                  ? _mapContestTeams[contest.id]
                  : null,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          "Joined Contests".toUpperCase(),
        ),
      ),
      body: Column(
        children: <Widget>[
          LeagueTitle(
            league: widget.league,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: <Widget>[
                _l1Data == null ||
                        _myContests == null ||
                        _myContests.normal == null
                    ? Container()
                    : Container(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _myContests.normal.length == 0
                            ? Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    strings.get("CONTESTS_NOT_AVAILABLE"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context).errorColor,
                                      fontSize: Theme.of(context)
                                          .primaryTextTheme
                                          .headline
                                          .fontSize,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _myContests.normal.length,
                                padding: EdgeInsets.only(bottom: 16.0),
                                itemBuilder: (context, index) {
                                  Contest contest = _myContests.normal[index];
                                  bool bShowBrandInfo = index > 0
                                      ? !(contest.brand["info"] ==
                                          _myContests
                                              .normal[index].brand["info"])
                                      : true;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        top: 8.0, right: 8.0, left: 8.0),
                                    child: ContestCard(
                                      radius: BorderRadius.circular(
                                        5.0,
                                      ),
                                      l1Data: _l1Data,
                                      league: widget.league,
                                      onJoin: (Contest curContest) {
                                        ActionUtil().launchJoinContest(
                                          l1Data: _l1Data,
                                          myTeams: _myTeams,
                                          contest: curContest,
                                          league: widget.league,
                                          scaffoldKey: scaffoldKey,
                                        );
                                      },
                                      contest: contest,
                                      onClick: _onContestClick,
                                      bShowBrandInfo: bShowBrandInfo,
                                      onPrizeStructure: _showPrizeStructure,
                                      myJoinedTeams: _mapContestTeams != null
                                          ? _mapContestTeams[contest.id]
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
