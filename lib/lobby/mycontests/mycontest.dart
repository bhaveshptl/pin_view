import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/lobby/mycontests/mycontestsporttab.dart';

class MyContests extends StatefulWidget {
  final int leagueId;
  final int sportsId;
  final List<League> leagues;
  final Function onSportChange;
  final Map<String, int> mapSportTypes;
  final double tabBarHeight = 32.0;

  MyContests({
    this.leagues,
    this.leagueId,
    this.sportsId,
    this.onSportChange,
    @required this.mapSportTypes,
  });

  @override
  MyContestsState createState() {
    return new MyContestsState();
  }
}

class MyContestsState extends State<MyContests>
    with SingleTickerProviderStateMixin {
  int currentStatus = 1;

  String cookie;
  int _sportType = 1;
  List<League> allLeagues;
  int selectedSegment = 0;
  bool bShowStatusBar = true;
  TabController _sportsController;
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<int, List<MySheet>> _mapContestSheets = {};
  Map<int, Map<String, MyAllContest>> myContests = {};

  StreamSubscription _streamSubscription;
  Map<String, dynamic> lobbyUpdatePacket = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (widget.sportsId != null) {
      _sportType = widget.sportsId;
      _getMyContests(bShowLoader: false);
    } else {
      _getSportsType();
    }

    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);

    allLeagues = widget.leagues;
    _sportsController =
        TabController(vsync: this, length: widget.mapSportTypes.keys.length);
    _sportsController.addListener(() {
      if (!_sportsController.indexIsChanging) {
        setState(() {
          _sportType = _sportsController.index + 1;
          widget.onSportChange(_sportType);
        });
        sendGetLobbyDataMsg();
        _getMyContests(bShowLoader: true);
      }
    });

    bShowStatusBar = widget.leagueId == null;
    if (!bShowStatusBar) {
      currentStatus = getLeagueStatus();
    }
  }

  sendGetLobbyDataMsg() {
    lobbyUpdatePacket["sportsId"] = _sportType;
    lobbyUpdatePacket["iType"] = RequestType.GET_ALL_SERIES;
    FantasyWebSocket().sendMessage(lobbyUpdatePacket);
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  getLeagueStatus() {
    allLeagues.forEach((league) {
      if (widget.leagueId == league.leagueId) {
        return league.status;
      }
    });
    return 1;
  }

  _getSportsType() async {
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getSportsType();
    await futureCookie.then((value) {
      int _sport = int.parse(value == null || value == "0" ? "1" : value);
      if (_sport != _sportType) {
        _sportType = _sport;
        setState(() {
          _sportType = _sport;
          _sportsController.index = _sportType - 1;
        });
      } else {
        _getMyContests(bShowLoader: true);
      }
    });
  }

  _getMyContests({bool bShowLoader = true}) async {
    if (bShowLoader) {
      showLoader(true);
    }
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl +
            ApiUtil.GET_MY_ALL_CONTESTS +
            _sportType.toString() +
            (widget.leagueId != null
                ? ("/league/" + widget.leagueId.toString())
                : ""),
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

  _getMyContestMySheets(Map<String, MyAllContest> _mapMyContests) async {
    List<int> _contestIds = [];
    _mapMyContests.forEach((String key, dynamic value) {
      List<Contest> _contests = _mapMyContests[key].prediction;
      for (Contest contest in _contests) {
        _contestIds.add(contest.id);
      }
    });

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

  _onWsMsg(data) {
    if (data["iType"] == RequestType.GET_ALL_SERIES &&
        data["bSuccessful"] == true &&
        _sportType == data["sportsId"]) {
      List<dynamic> _mapLeagues = json.decode(data["data"]);
      List<League> leagues =
          _mapLeagues.map((i) => League.fromJson(i)).toList();
      setState(() {
        allLeagues = leagues;
        currentStatus = getLeagueStatus();
      });
    } else if (data["iType"] == RequestType.LOBBY_REFRESH_DATA &&
        data["bSuccessful"] == true) {
      if (data["data"]["bDataModified"] == true &&
          (data["data"]["lstModified"] as List).length > 0) {
        List<League> _modifiedLeagues = (data["data"]["lstModified"] as List)
            .map((i) => League.fromJson(i))
            .toList();

        for (League _league in _modifiedLeagues) {
          int index = getLeagueIndex(allLeagues, _league);
          if (index != -1) {
            allLeagues[index] = _league;
            setState(() {
              currentStatus = getLeagueStatus();
            });
          }
        }
      }
    } else if (data["iType"] == RequestType.L1_DATA_REFRESHED &&
        data["bSuccessful"] == true) {
      _applyContestDataUpdate(data["diffData"]["ld"]);
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _update(data["data"]);
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
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: widget.leagueId != null
          ? AppBar(
              title: Text("My contests"),
            )
          : null,
      body: Container(
        child: widget.leagueId != null
            ? MyContestSportTab(
                leagues: allLeagues,
                showLoader: showLoader,
                sportsType: _sportType,
                scaffoldKey: _scaffoldKey,
                mapMyTeams: _mapContestTeams,
                currentStauts: currentStatus,
                showStatusBar: bShowStatusBar,
                mapMySheets: _mapContestSheets,
                myContests: myContests[_sportType],
              )
            : Column(
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _sportsController,
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
                      tabs: widget.mapSportTypes.keys.map<Tab>((page) {
                        return Tab(
                          text: page,
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: _sportsController,
                      children:
                          widget.mapSportTypes.keys.map<Widget>((sportType) {
                        final sportsId = widget.mapSportTypes[sportType];
                        return MyContestSportTab(
                          leagues: allLeagues,
                          showLoader: showLoader,
                          sportsType: sportsId,
                          scaffoldKey: _scaffoldKey,
                          mapMyTeams: _mapContestTeams,
                          mapMySheets: _mapContestSheets,
                          myContests: myContests[sportsId],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
