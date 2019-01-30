import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/lobby/mycontests/mycontestsporttab.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class NewMyContests extends StatefulWidget {
  final List<League> leagues;
  final Function onSportChange;
  final double tabBarHeight = 32.0;

  NewMyContests({this.leagues, this.onSportChange});

  @override
  NewMyContestsState createState() {
    return new NewMyContestsState();
  }
}

class NewMyContestsState extends State<NewMyContests>
    with SingleTickerProviderStateMixin {
  Map<String, int> _mapSportTypes = {
    "CRICKET": 1,
    "FOOTBALL": 2,
    "KABADDI": 3,
  };

  String cookie;
  int _sportType = 1;
  List<League> allLeagues;
  int selectedSegment = 0;
  bool bShowLoader = false;
  TabController _sportsController;
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<int, List<MySheet>> _mapContestSheets = {};
  Map<int, Map<String, MyAllContest>> myContests = {};

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getSportsType();
    sockets.register(_onWsMsg);
    _getMyContests();
    allLeagues = widget.leagues;
    _sportsController =
        TabController(vsync: this, length: _mapSportTypes.keys.length);
    _sportsController.addListener(() {
      if (!_sportsController.indexIsChanging) {
        setState(() {
          _sportType = _sportsController.index + 1;
          widget.onSportChange(_sportType);
          _getMyContests(checkForPrevSelection: false);
        });
      }
    });
  }

  showLoader(bool bShow) {
    setState(() {
      bShowLoader = bShow;
    });
  }

  _getSportsType() async {
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getSportsType();
    await futureCookie.then((value) {
      int _sport = int.parse(value == null || value == "0" ? "1" : value);
      if (_sport != _sportType) {
        setState(() {
          _sportType = _sport;
          _sportsController.index = _sportType - 1;
        });
      }
    });
  }

  _getMyContests({bool checkForPrevSelection = true}) async {
    showLoader(true);
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.GET_MY_ALL_CONTESTS + _sportType.toString(),
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          myContests[_sportType] = NewMyContest.fromJson(response).leagues;
        });
        showLoader(false);
        _getMyContestMyTeams(myContests[_sportType]);
        _getMyContestMySheets(myContests[_sportType]);
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  _getMyContestMyTeams(Map<String, MyAllContest> _mapMyContests) async {
    List<int> _contestIds = [];
    _mapMyContests.forEach((String key, dynamic value) {
      List<Contest> _contests = _mapMyContests[key].normal;
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
        });
      }
    });
  }

  _getMyContestMySheets(Map<String, MyAllContest> _mapMyContests) async {
    List<int> _contestIds = [];
    _mapMyContests.forEach((String key, dynamic value) {
      List<Contest> _contests = _mapMyContests[key].prediction;
      for (Contest contest in _contests) {
        _contestIds.add(contest.id);
      }
    });

    http.Request req = http.Request("POST",
        Uri.parse(BaseUrl.apiUrl + ApiUtil.GET_CONTEST_MY_ANSWER_SHEETS));
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

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);
    if (_response["iType"] == RequestType.GET_ALL_SERIES &&
        _response["bSuccessful"] == true) {
      List<dynamic> _mapLeagues = json.decode(_response["data"]);
      List<League> leagues =
          _mapLeagues.map((i) => League.fromJson(i)).toList();
      setState(() {
        allLeagues = leagues;
      });
    } else if (_response["iType"] == RequestType.LOBBY_REFRESH_DATA &&
        _response["bSuccessful"] == true) {
      if (_response["data"]["bDataModified"] == true &&
          (_response["data"]["lstModified"] as List).length > 0) {
        List<League> _modifiedLeagues =
            (_response["data"]["lstModified"] as List)
                .map((i) => League.fromJson(i))
                .toList();

        for (League _league in _modifiedLeagues) {
          int index = getLeagueIndex(allLeagues, _league);
          if (index != -1) {
            allLeagues[index] = _league;
          }
        }
      }
    } else if (_response["iType"] == RequestType.L1_DATA_REFRESHED &&
        _response["bSuccessful"] == true) {
      _applyContestDataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        _response["bSuccessful"] == true) {
      _update(_response["data"]);
    }
  }

  _applyContestDataUpdate(Map<String, dynamic> _data) {
    if (_data["lstModified"] != null && _data["lstModified"].length >= 1) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        myContests[_sportType].forEach(
          (String key, MyAllContest _contests) {
            for (Contest _contest in _contests.normal) {
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
    }
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
    myContests[_sportType].forEach((String key, MyAllContest _contests) {
      _updateContestJoinCount(_data, _contests.normal);
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            elevation: 0.0,
            title: Text("My Contests"),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(widget.tabBarHeight),
              child: Container(
                padding: EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    TabBar(
                      controller: _sportsController,
                      isScrollable: true,
                      indicator: UnderlineTabIndicator(),
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: _mapSportTypes.keys.map<Tab>((page) {
                        return Tab(
                          text: page,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/norwegian_rose.png"),
                  repeat: ImageRepeat.repeat),
            ),
            child: TabBarView(
              controller: _sportsController,
              children: <Widget>[
                MyContestSportTab(
                  leagues: allLeagues,
                  showLoader: showLoader,
                  sportsType: _sportType,
                  scaffoldKey: _scaffoldKey,
                  mapMyTeams: _mapContestTeams,
                  mapMySheets: _mapContestSheets,
                  myContests: myContests[_mapSportTypes["CRICKET"]],
                ),
                MyContestSportTab(
                  leagues: allLeagues,
                  showLoader: showLoader,
                  sportsType: _sportType,
                  scaffoldKey: _scaffoldKey,
                  mapMyTeams: _mapContestTeams,
                  mapMySheets: _mapContestSheets,
                  myContests: myContests[_mapSportTypes["FOOTBALL"]],
                ),
                MyContestSportTab(
                  leagues: allLeagues,
                  showLoader: showLoader,
                  sportsType: _sportType,
                  scaffoldKey: _scaffoldKey,
                  mapMyTeams: _mapContestTeams,
                  mapMySheets: _mapContestSheets,
                  myContests: myContests[_mapSportTypes["KABADDI"]],
                )
              ],
            ),
          ),
        ),
        bShowLoader ? Loader() : Container(),
      ],
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }
}
