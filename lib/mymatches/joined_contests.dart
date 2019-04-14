import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/leaguedetail/prediction/predictioncontestcard.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/prediction.dart';
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
  List<MySheet> _mySheets;
  MyAllContest _myContests;
  Prediction _predictionData;
  GlobalKey<ScaffoldState> scaffoldKey;
  StreamSubscription _streamSubscription;
  Map<String, dynamic> l1UpdatePackate = {};
  Map<int, List<MySheet>> _mapContestSheets;
  Map<int, List<MyTeam>> _mapContestTeams = {};

  TabController _tabController;

  @override
  void initState() {
    _getMyContests();
    _createL1WSObject();
    _getL1Data();
    scaffoldKey = GlobalKey<ScaffoldState>();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    _tabController = TabController(length: 1, vsync: this);
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

      if (data["data"]["prediction"] != null) {
        _predictionData = Prediction.fromJson(data["data"]["prediction"]);
      }
      if (data["data"]["mySheets"] != null && data["data"]["mySheets"] != "") {
        _mySheets = (data["data"]["mySheets"] as List<dynamic>).map((f) {
          return MySheet.fromJson(f);
        }).toList();
      }
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
          _tabController = TabController(
              length: _myContests.normal.length > 0 &&
                      _myContests.prediction.length > 0
                  ? 2
                  : 1,
              vsync: this);
        });

        _getMyContestMyTeams(_myContests);
        _getMyContestMySheets(_myContests);
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

  _getMyContestMySheets(MyAllContest _mapMyContests) async {
    List<int> _contestIds = [];
    List<Contest> _contests = _mapMyContests.prediction;
    for (Contest contest in _contests) {
      _contestIds.add(contest.id);
    }

    http.Request req = http.Request("POST",
        Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_CONTEST_MY_ANSWER_SHEETS));
    req.body = json.encode(_contestIds);
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<int, List<MySheet>> _mapContestMySheets = {};
        Map<String, dynamic> response =
            json.decode(res.body == "\"\"" ? "{}" : res.body);
        response.forEach((String key, dynamic value) {
          _mapContestMySheets[int.parse(key)] = (value as List<dynamic>)
              .map((sheet) => MySheet.fromJson(sheet))
              .toList();
        });

        setState(() {
          _mapContestSheets = _mapContestMySheets;
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

  getTabTitle() {
    List<Widget> tabs = [];
    if (_myContests == null) {
      return [Container()];
    }
    if (_myContests.normal != null && _myContests.normal.length > 0) {
      tabs.add(
        Tab(
          child: Text("Contests".toUpperCase()),
        ),
      );
    }
    if (_myContests.prediction != null && _myContests.prediction.length > 0) {
      tabs.add(
        Tab(
          child: Text("Prediction".toUpperCase()),
        ),
      );
    }

    return tabs;
  }

  getTabBody() {
    List<Widget> tabsBody = [];
    if (_myContests == null) {
      return [Container()];
    }
    if (_myContests.normal != null && _myContests.normal.length > 0) {
      tabsBody.add(
        Container(
          padding: const EdgeInsets.only(top: 8.0),
          child: ListView.builder(
            itemCount: _myContests.normal.length,
            padding: EdgeInsets.only(bottom: 16.0),
            itemBuilder: (context, index) {
              Contest contest = _myContests.normal[index];
              bool bShowBrandInfo = index > 0
                  ? !(contest.brand["info"] ==
                      _myContests.normal[index].brand["info"])
                  : true;

              return Padding(
                padding: EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
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
      );
    }
    if (_myContests.prediction != null && _myContests.prediction.length > 0) {
      tabsBody.add(
        Container(
          padding: const EdgeInsets.only(top: 8.0),
          child: ListView.builder(
            itemCount: _myContests.normal.length,
            padding: EdgeInsets.only(bottom: 16.0),
            itemBuilder: (context, index) {
              Contest contest = _myContests.normal[index];
              bool bShowBrandInfo = index > 0
                  ? !(contest.brand["info"] ==
                      _myContests.normal[index].brand["info"])
                  : true;

              return Padding(
                padding: EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
                child: PredictionContestCard(
                  radius: BorderRadius.circular(
                    5.0,
                  ),
                  league: widget.league,
                  predictionData: _predictionData,
                  onJoin: (Contest curContest) {},
                  contest: contest,
                  onClick: _onContestClick,
                  bShowBrandInfo: bShowBrandInfo,
                  onPrizeStructure: _showPrizeStructure,
                  myJoinedSheets: _mapContestSheets != null
                      ? _mapContestSheets[contest.id]
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }

    return tabsBody;
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
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.black,
                    labelStyle:
                        Theme.of(context).primaryTextTheme.body2.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 4.0,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    tabs: getTabTitle(),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: getTabBody(),
            ),
          ),
        ],
      ),
    );
  }
}
