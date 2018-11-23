import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/lobby/tabs/myconteststatustab.dart';

class MyContests extends StatefulWidget {
  final List<League> leagues;
  final Function onSportChange;
  final double tabBarHeight = 32.0;

  MyContests({this.leagues, this.onSportChange});

  @override
  MyContestsState createState() {
    return new MyContestsState();
  }
}

class MyContestsState extends State<MyContests>
    with SingleTickerProviderStateMixin {
  String cookie;
  int _sportType = 1;
  int selectedSegment = 0;
  List<League> _leagues = [];
  TabController tabController;
  Map<int, List<MyContestStatusTab>> tabs = {};
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
    tabController = TabController(length: 2, vsync: this);
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);
    if (_response["iType"] == RequestType.GET_ALL_SERIES &&
        _response["bSuccessful"] == true) {
      List<dynamic> _mapLeagues = json.decode(_response["data"]);
      List<League> leagues =
          _mapLeagues.map((i) => League.fromJson(i)).toList();
      setState(() {
        _leagues = leagues;
      });
    } else if (_response["iType"] == RequestType.LOBBY_REFRESH_DATA &&
        _response["bSuccessful"] == true) {
      if (_response["data"]["bDataModified"] == true &&
          (_response["data"]["lstModified"] as List).length > 0) {
        List<League> _modifiedLeagues =
            (_response["data"]["lstModified"] as List)
                .map((i) => League.fromJson(i))
                .toList();
        Map<String, List<Contest>> _mapMyAllContests = _mapUpcomingContest;
        _mapMyAllContests.addAll(_mapLiveContest);
        _mapMyAllContests.addAll(_mapResultContest);

        for (League _league in _modifiedLeagues) {
          int index = getLeagueIndex(_leagues, _league);
          if (index != -1) {
            _leagues[index] = _league;
          }
        }

        setState(() {
          _setContestsByStatus(_mapMyAllContests);
        });
      }
    } else if (_response["iType"] == RequestType.L1_DATA_REFRESHED &&
        _response["bSuccessful"] == true) {
      _applyContestDataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        _response["bSuccessful"] == true) {
      _update(_response["data"]);
    }
  }

  int getLeagueIndex(List<League> _leagues, League _league) {
    int index = 0;
    for (League _curLeague in _leagues) {
      if (_curLeague.leagueId == _league.leagueId) {
        return index;
      }
      index++;
    }
    return -1;
  }

  _update(Map<String, dynamic> _data) {
    Map<String, dynamic> _mapContestTeamsUpdate = _data["teamsByContest"];
    _mapContestTeamsUpdate.forEach((String key, dynamic _contestTeams) {
      List<MyTeam> _teams = (_mapContestTeamsUpdate[key] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      setState(() {
        _mapContestTeams[int.parse(key)] = _teams;
      });
    });
    _mapUpcomingContest.forEach((String key, List<Contest> _contests) {
      _updateContestJoinCount(_data, _contests);
    });
  }

  _updateContestJoinCount(Map<String, dynamic> _data, List<Contest> _contests) {
    for (Contest _contest in _contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
          updateTabs();
        });
      }
    }
  }

  _applyContestDataUpdate(Map<String, dynamic> _data) {
    Map<String, List<Contest>> _mapMyAllContests = _mapUpcomingContest;
    _mapMyAllContests.addAll(_mapLiveContest);
    _mapMyAllContests.addAll(_mapResultContest);

    if (_data["lstModified"] != null && _data["lstModified"].length >= 1) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        _mapMyAllContests.forEach(
          (String key, List<Contest> _contests) {
            for (Contest _contest in _contests) {
              if (_contest.id == _changedContest["id"]) {
                setState(() {
                  if (_changedContest["name"] != null &&
                      _contest.name != _changedContest["name"]) {
                    _contest.name = _changedContest["name"];
                  }
                  if (_changedContest["templateId"] != null &&
                      _contest.templateId != _changedContest["templateId"]) {
                    _contest.templateId = _changedContest["templateId"];
                  }
                  if (_changedContest["size"] != null &&
                      _contest.size != _changedContest["size"]) {
                    _contest.size = _changedContest["size"];
                  }
                  if (_changedContest["prizeType"] != null &&
                      _contest.prizeType != _changedContest["prizeType"]) {
                    _contest.prizeType = _changedContest["prizeType"];
                  }
                  if (_changedContest["entryFee"] != null &&
                      _contest.entryFee != _changedContest["entryFee"]) {
                    _contest.entryFee = _changedContest["entryFee"];
                  }
                  if (_changedContest["minUsers"] != null &&
                      _contest.minUsers != _changedContest["minUsers"]) {
                    _contest.minUsers = _changedContest["minUsers"];
                  }
                  if (_changedContest["serviceFee"] != null &&
                      _contest.serviceFee != _changedContest["serviceFee"]) {
                    _contest.serviceFee = _changedContest["serviceFee"];
                  }
                  if (_changedContest["teamsAllowed"] != null &&
                      _contest.teamsAllowed !=
                          _changedContest["teamsAllowed"]) {
                    _contest.teamsAllowed = _changedContest["teamsAllowed"];
                  }
                  if (_changedContest["leagueId"] != null &&
                      _contest.leagueId != _changedContest["leagueId"]) {
                    _contest.leagueId = _changedContest["leagueId"];
                  }
                  if (_changedContest["releaseTime"] != null &&
                      _contest.releaseTime != _changedContest["releaseTime"]) {
                    _contest.releaseTime = _changedContest["releaseTime"];
                  }
                  if (_changedContest["regStartTime"] != null &&
                      _contest.regStartTime !=
                          _changedContest["regStartTime"]) {
                    _contest.regStartTime = _changedContest["regStartTime"];
                  }
                  if (_changedContest["startTime"] != null &&
                      _contest.startTime != _changedContest["startTime"]) {
                    _contest.startTime = _changedContest["startTime"];
                  }
                  if (_changedContest["endTime"] != null &&
                      _contest.endTime != _changedContest["endTime"]) {
                    _contest.endTime = _changedContest["endTime"];
                  }
                  if (_changedContest["status"] != null &&
                      _contest.status != _changedContest["status"]) {
                    _contest.status = _changedContest["status"];
                  }
                  if (_changedContest["visibilityId"] != null &&
                      _contest.visibilityId !=
                          _changedContest["visibilityId"]) {
                    _contest.visibilityId = _changedContest["visibilityId"];
                  }
                  if (_changedContest["visibilityInfo"] != null &&
                      _contest.visibilityInfo !=
                          _changedContest["visibilityInfo"]) {
                    _contest.visibilityInfo = _changedContest["visibilityInfo"];
                  }
                  if (_changedContest["contestJoinCode"] != null &&
                      _contest.contestJoinCode !=
                          _changedContest["contestJoinCode"]) {
                    _contest.contestJoinCode =
                        _changedContest["contestJoinCode"];
                  }
                  if (_changedContest["joined"] != null &&
                      _contest.joined != _changedContest["joined"]) {
                    _contest.joined = _changedContest["joined"];
                  }
                  if (_changedContest["bonusAllowed"] != null &&
                      _contest.bonusAllowed !=
                          _changedContest["bonusAllowed"]) {
                    _contest.bonusAllowed = _changedContest["bonusAllowed"];
                  }
                  if (_changedContest["guaranteed"] != null &&
                      _contest.guaranteed != _changedContest["guaranteed"]) {
                    _contest.guaranteed = _changedContest["guaranteed"];
                  }
                  if (_changedContest["recommended"] != null &&
                      _contest.recommended != _changedContest["recommended"]) {
                    _contest.recommended = _changedContest["recommended"];
                  }
                  if (_changedContest["deleted"] != null &&
                      _contest.deleted != _changedContest["deleted"]) {
                    _contest.deleted = _changedContest["deleted"];
                  }
                  if (_changedContest["brand"] != null &&
                      _changedContest["brand"]["info"] != null &&
                      _contest.brand["info"] !=
                          _changedContest["brand"]["info"]) {
                    _contest.brand["info"] = _changedContest["brand"]["info"];
                  }
                  if ((_changedContest["lstAdded"] as List).length > 0) {
                    for (dynamic _prize in _changedContest["lstAdded"]) {
                      _contest.prizeDetails.add(_prize);
                    }
                  }
                  if ((_changedContest["lstModified"] as List).length > 0) {
                    for (dynamic _modifiedPrize
                        in _changedContest["lstModified"]) {
                      for (dynamic _prize in _contest.prizeDetails) {
                        if (_prize["id"] == _modifiedPrize["id"]) {
                          if (_modifiedPrize["label"] != null) {
                            _prize["label"] = _modifiedPrize["label"];
                          }
                          if (_modifiedPrize["noOfPrizes"] != null) {
                            _prize["noOfPrizes"] = _modifiedPrize["noOfPrizes"];
                          }
                          if (_modifiedPrize["totalPrizeAmount"] != null) {
                            _prize["totalPrizeAmount"] =
                                _modifiedPrize["totalPrizeAmount"];
                          }
                        }
                      }
                    }
                  }
                });
              }
            }
          },
        );
      }
      setState(() {
        _setContestsByStatus(_mapMyAllContests);
      });
    }
  }

  _getMyContests({bool checkForPrevSelection = true}) async {
    if (checkForPrevSelection == true) {
      await _getSportsType();
    }
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.GET_MY_CONTESTS + _sportType.toString(),
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
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
      int _sport = int.parse(value == null ? "1" : value);
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
      updateTabs();
    });
  }

  updateTabs() {
    tabs = {
      1: [
        MyContestStatusTab(
          fantasyType: 1,
          leagues: _leagues,
          sportsType: _sportType,
          scaffoldKey: _scaffoldKey,
          onContestClick: _onContestClick,
          mapContestTeams: _mapContestTeams,
          mapMyContests: _mapUpcomingContest,
          leagueStatus: LeagueStatus.UPCOMING,
        ),
        MyContestStatusTab(
          fantasyType: 1,
          leagues: _leagues,
          sportsType: _sportType,
          scaffoldKey: _scaffoldKey,
          mapMyContests: _mapLiveContest,
          onContestClick: _onContestClick,
          mapContestTeams: _mapContestTeams,
          leagueStatus: LeagueStatus.LIVE,
        ),
        MyContestStatusTab(
          fantasyType: 1,
          leagues: _leagues,
          sportsType: _sportType,
          scaffoldKey: _scaffoldKey,
          onContestClick: _onContestClick,
          mapMyContests: _mapResultContest,
          mapContestTeams: _mapContestTeams,
          leagueStatus: LeagueStatus.COMPLETED,
        )
      ],
      2: [
        MyContestStatusTab(
          fantasyType: 2,
          leagues: _leagues,
          sportsType: _sportType,
          scaffoldKey: _scaffoldKey,
          onContestClick: _onContestClick,
          mapContestTeams: _mapContestTeams,
          mapMyContests: _mapUpcomingContest,
          leagueStatus: LeagueStatus.UPCOMING,
        ),
        MyContestStatusTab(
          fantasyType: 2,
          leagues: _leagues,
          sportsType: _sportType,
          scaffoldKey: _scaffoldKey,
          mapMyContests: _mapLiveContest,
          onContestClick: _onContestClick,
          mapContestTeams: _mapContestTeams,
          leagueStatus: LeagueStatus.LIVE,
        ),
        MyContestStatusTab(
          fantasyType: 2,
          leagues: _leagues,
          sportsType: _sportType,
          scaffoldKey: _scaffoldKey,
          onContestClick: _onContestClick,
          mapMyContests: _mapResultContest,
          mapContestTeams: _mapContestTeams,
          leagueStatus: LeagueStatus.COMPLETED,
        )
      ]
    };
  }

  _getMyContestMyTeams(Map<String, List<Contest>> _mapMyContests) async {
    List<int> _contestIds = [];
    _mapMyContests.forEach((String key, dynamic value) {
      List<Contest> _contests = _mapMyContests[key];
      for (Contest contest in _contests) {
        _contestIds.add(contest.id);
      }
    });

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
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
          updateTabs();
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
      MaterialPageRoute(
        builder: (context) => ContestDetail(
              league: league,
              contest: contest,
              mapContestTeams: _mapContestTeams[contest.id],
            ),
      ),
    );
  }

  getMyContestTabs(int fantasyType) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: 500.0,
            child: CupertinoSegmentedControl<int>(
              children: {
                0: Text(strings.get("UPCOMING").toUpperCase()),
                1: Text(strings.get("LIVE").toUpperCase()),
                2: Text(strings.get("RESULT").toUpperCase()),
              },
              onValueChanged: (int newValue) {
                setState(() {
                  selectedSegment = newValue;
                });
              },
              groupValue: selectedSegment,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
            ),
            child: tabs[fantasyType] != null
                ? tabs[fantasyType][selectedSegment]
                : Container(),
          ),
        ),
      ],
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
                    fontSize:
                        Theme.of(context).primaryTextTheme.title.fontSize),
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(widget.tabBarHeight),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white30,
              controller: tabController,
              tabs: [
                Container(
                  height: widget.tabBarHeight,
                  child: Tab(
                    text: "MATCH",
                  ),
                ),
                Container(
                  height: widget.tabBarHeight,
                  child: Tab(
                    text: "INNINGS",
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: <Widget>[
            Container(
              child: getMyContestTabs(1),
            ),
            Container(
              child: getMyContestTabs(2),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }
}
