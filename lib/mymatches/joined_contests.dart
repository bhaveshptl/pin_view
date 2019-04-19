import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/leaguedetail/prediction/mysheets.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/leaguedetail/myteams.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/createcontest/createcontest.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/predictioncontestcard.dart';
import 'package:playfantasy/leaguedetail/prediction/predictioncontestdetails.dart';

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
  int activeTabIndex = 0;

  @override
  void initState() {
    _getMyContests();
    _createL1WSObject();
    _getL1Data();
    scaffoldKey = GlobalKey<ScaffoldState>();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    initTabController();
    super.initState();
  }

  initTabController() {
    _tabController = TabController(
        length: _myContests != null &&
                _myContests.normal.length > 0 &&
                _myContests.prediction.length > 0
            ? 2
            : 1,
        vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setActiveTabIndex();
      }
    });
  }

  setActiveTabIndex() {
    if (_myContests != null &&
        _myContests.prediction != null &&
        _myContests.prediction.length > 0 &&
        _myContests.normal != null &&
        _myContests.normal.length > 0) {
      setState(() {
        activeTabIndex = _tabController.index;
      });
    } else if (_myContests != null &&
        _myContests.prediction != null &&
        _myContests.prediction.length > 0) {
      setState(() {
        activeTabIndex = 1;
      });
    } else if (_myContests != null &&
        _myContests.normal != null &&
        _myContests.normal.length > 0) {
      setState(() {
        activeTabIndex = 0;
      });
    }
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
        _myContests = NewMyContest.fromJson(response)
            .leagues[widget.league.leagueId.toString()];
        initTabController();
        setActiveTabIndex();

        setState(() {
          _myContests = _myContests;
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
    }).whenComplete(() {
      ActionUtil().showLoader(context, false);
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

  _onPredictionClick(Contest contest, League league) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => PredictionContestDetail(
              contest: contest,
              league: league,
              predictionData: _predictionData,
              mySheets: _mySheets,
              mapContestSheets: _mapContestSheets != null
                  ? _mapContestSheets[contest.id]
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
                padding: EdgeInsets.only(top: 4.0, right: 16.0, left: 16.0),
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
            itemCount: _myContests.prediction.length,
            padding: EdgeInsets.only(bottom: 16.0),
            itemBuilder: (context, index) {
              Contest contest = _myContests.prediction[index];
              bool bShowBrandInfo = index > 0
                  ? !(contest.brand["info"] ==
                      _myContests.prediction[index].brand["info"])
                  : true;

              return Padding(
                padding: EdgeInsets.only(top: 4.0, right: 16.0, left: 16.0),
                child: PredictionContestCard(
                  radius: BorderRadius.circular(
                    5.0,
                  ),
                  league: widget.league,
                  predictionData: _predictionData,
                  onJoin: (Contest curContest) {
                    ActionUtil().launchJoinPrediction(
                      contest: contest,
                      mySheets: _mySheets,
                      league: widget.league,
                      scaffoldKey: scaffoldKey,
                      predictionData: _predictionData,
                    );
                  },
                  contest: contest,
                  onClick: _onPredictionClick,
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

  onBottomNavigationClicked(int itemIndex) async {
    var result;
    switch (itemIndex) {
      case 0:
        result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => CreateContest(
                  l1data: _l1Data,
                  myTeams: _myTeams,
                  league: widget.league,
                ),
          ),
        );
        break;
      case 1:
        result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => MyTeams(
                  l1Data: _l1Data,
                  myTeams: _myTeams,
                  league: widget.league,
                ),
          ),
        );
        break;
      case 2:
        result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => MySheets(
                  predictionData: _predictionData,
                  mySheets: _mySheets,
                  league: widget.league,
                ),
          ),
        );
    }
    if (result != null) {
      scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
          duration: Duration(
            seconds: 3,
          ),
        ),
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
          widget.league.status != LeagueStatus.UPCOMING
              ? Container()
              : Container(
                  child: activeTabIndex == 0
                      ? Container(
                          height: 72.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10.0,
                                spreadRadius: 3.0,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Container(
                                        height: 72.0,
                                        child: FlatButton(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Container(
                                                width: 24.0,
                                                height: 24.0,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.orange,
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 4.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      "Create Contest",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          onPressed: () {
                                            onBottomNavigationClicked(0);
                                          },
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Container(
                                        width: 1.0,
                                        height: 72.0,
                                        color: Colors.black12,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 72.0,
                                        child: FlatButton(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Container(
                                                    width: 24.0,
                                                    height: 24.0,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.orange,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _myTeams == null
                                                          ? "0"
                                                          : _myTeams.length
                                                              .toString(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 4.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      "My Teams",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          onPressed: () {
                                            onBottomNavigationClicked(1);
                                          },
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      : Container(
                          height: 72.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10.0,
                                spreadRadius: 3.0,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Container(
                                        height: 72.0,
                                        child: FlatButton(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Container(
                                                    width: 24.0,
                                                    height: 24.0,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.orange,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _mySheets == null
                                                          ? "0"
                                                          : _mySheets.length
                                                              .toString(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 4.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      "My Sheets",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          onPressed: () {
                                            onBottomNavigationClicked(2);
                                          },
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                )
        ],
      ),
    );
  }
}
