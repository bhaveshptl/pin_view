import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/lobby/tabs/myconteststatustab.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

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
  bool bShowInnings = true;
  bool bShowLoader = false;
  List<League> _leagues = [];
  TabController tabController;
  TabController _sportsController;
  Map<String, int> _mapSportTypes;
  StreamSubscription _streamSubscription;
  Map<int, List<MyContestStatusTab>> tabs = {};
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<String, List<Contest>> _mapLiveContest = {};
  Map<String, List<Contest>> _mapResultContest = {};
  Map<String, List<Contest>> _mapUpcomingContest = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _mapSportTypes = {
      "CRICKET": 1,
      "FOOTBALL": 2,
      "KABADDI": 3,
    };

    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);

    _getMyContests();
    _leagues = widget.leagues;
    _sportsController =
        TabController(vsync: this, length: _mapSportTypes.keys.length);
    _sportsController.addListener(() {
      _setContestsByStatus({});
      if (!_sportsController.indexIsChanging) {
        setState(() {
          _sportType = _sportsController.index + 1;
          widget.onSportChange(_sportType);
          _getMyContests(checkForPrevSelection: false);
        });
        SharedPrefHelper().saveSportsType(_sportType.toString());
      }
    });
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.GET_ALL_SERIES &&
        data["bSuccessful"] == true) {
      List<dynamic> _mapLeagues = json.decode(data["data"]);
      List<League> leagues =
          _mapLeagues.map((i) => League.fromJson(i)).toList();
      setState(() {
        _leagues = leagues;
      });
    } else if (data["iType"] == RequestType.LOBBY_REFRESH_DATA &&
        data["bSuccessful"] == true) {
      if (data["data"]["bDataModified"] == true &&
          (data["data"]["lstModified"] as List).length > 0) {
        List<League> _modifiedLeagues = (data["data"]["lstModified"] as List)
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
    } else if (data["iType"] == RequestType.L1_DATA_REFRESHED &&
        data["bSuccessful"] == true) {
      _applyContestDataUpdate(data["diffData"]["ld"]);
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _update(data["data"]);
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
        BaseUrl().apiUrl + ApiUtil.GET_MY_ALL_CONTESTS + _sportType.toString(),
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> response = json.decode(res.body);
        setState(() {
          Map<String, List<Contest>> _mapMyContests =
              MyContest.fromJson(response["normal"]).leagues;
          _getMyContestMyTeams(_mapMyContests);
          _setContestsByStatus(_mapMyContests);
        });
      }
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
      } else if (_contests.length > 0) {
        int status = (_contests[0].status <= 3
            ? LeagueStatus.UPCOMING
            : (_contests[0].status <= 5
                ? LeagueStatus.LIVE
                : LeagueStatus.COMPLETED));
        if (status == LeagueStatus.UPCOMING) {
          mapUpcomingContest[key] = _contests;
        } else if (status == LeagueStatus.LIVE) {
          mapLiveContest[key] = _contests;
        } else if (status == LeagueStatus.COMPLETED) {
          mapResultContest[key] = _contests;
        }
      }
    });

    List<String> upcomingKeys = mapUpcomingContest.keys.toList();
    upcomingKeys.sort((a, b) {
      League leagueA = _getLeague(int.parse(a));
      League leagueB = _getLeague(int.parse(b));
      int leagueAStartTime = leagueA != null ? leagueA.matchStartTime : 0;
      int leagueBStartTime = leagueB != null ? leagueB.matchStartTime : 0;
      return leagueAStartTime - leagueBStartTime;
    });

    List<String> liveKeys = mapLiveContest.keys.toList();
    liveKeys.sort((a, b) {
      League leagueA = _getLeague(int.parse(a));
      League leagueB = _getLeague(int.parse(b));
      int leagueAStartTime = leagueA != null ? leagueA.matchStartTime : 0;
      int leagueBStartTime = leagueB != null ? leagueB.matchStartTime : 0;
      return leagueBStartTime - leagueAStartTime;
    });

    List<String> resultKeys = mapResultContest.keys.toList();
    resultKeys.sort((a, b) {
      League leagueA = _getLeague(int.parse(a));
      League leagueB = _getLeague(int.parse(b));
      int leagueAEndTime = leagueA != null ? leagueA.matchEndTime : 0;
      int leagueBEndTime = leagueB != null ? leagueB.matchEndTime : 0;
      return leagueBEndTime - leagueAEndTime;
    });
    _mapUpcomingContest = {};
    _mapLiveContest = {};
    _mapResultContest = {};

    setState(() {
      upcomingKeys.forEach((key) {
        _mapUpcomingContest[key] = mapUpcomingContest[key];
      });

      liveKeys.forEach((key) {
        _mapLiveContest[key] = mapLiveContest[key];
      });

      resultKeys.forEach((key) {
        _mapResultContest[key] = mapResultContest[key];
      });
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

  League _getLeague(int _leagueId) {
    for (League _league in _leagues) {
      if (_league.leagueId == _leagueId) {
        return _league;
      }
    }
    return null;
  }

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => ContestDetail(
              league: league,
              contest: contest,
              mapContestTeams: _mapContestTeams[contest.id],
            ),
      ),
    );
  }

  showLoader(bool bShow) {
    setState(() {
      bShowLoader = bShow;
    });
  }

  getMyContestTabs({int fantasyType, int sportsType}) {
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
              borderColor: Theme.of(context).primaryColorDark,
              selectedColor: Theme.of(context).primaryColorDark.withAlpha(240),
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
              child: MyContestStatusTab(
                leagues: _leagues,
                sportsType: sportsType,
                showLoader: showLoader,
                fantasyType: fantasyType,
                scaffoldKey: _scaffoldKey,
                onContestClick: _onContestClick,
                mapContestTeams: _mapContestTeams,
                mapMyContests: selectedSegment == 0
                    ? _mapUpcomingContest
                    : (selectedSegment == 1
                        ? _mapLiveContest
                        : _mapResultContest),
                leagueStatus: selectedSegment + 1,
              )),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bShowInnings = AppConfig.of(context).channelId == "3" ? true : false;
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
                          // child: Row(
                          //   children: <Widget>[
                          //     SvgPicture.asset(
                          //       _sportType == _mapSportTypes[page]
                          //           ? "images/" + page.toLowerCase() + ".svg"
                          //           : "images/" +
                          //               page.toLowerCase() +
                          //               "light" +
                          //               ".svg",
                          //       width: 18.0,
                          //     ),
                          //     Padding(
                          //       padding: EdgeInsets.only(left: 6.0),
                          //       child: Text(page),
                          //     ),
                          //   ],
                          // ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _sportsController,
            children: _mapSportTypes.keys.map<Widget>((page) {
              return bShowInnings
                  ? DefaultTabController(
                      length: 2,
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(boxShadow: [
                              BoxShadow(
                                blurRadius: 3.0,
                                spreadRadius: 3.0,
                                color: Colors.black12,
                              )
                            ]),
                            child: Container(
                              color: Colors.white,
                              child: TabBar(
                                // indicatorColor: Colors.white,
                                labelColor: Theme.of(context).primaryColor,
                                indicatorSize: TabBarIndicatorSize.label,
                                unselectedLabelColor: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(100),
                                tabs: [
                                  Tab(
                                    text: "MATCH",
                                  ),
                                  Tab(
                                    text: "INNINGS",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(top: 6.0),
                              child: TabBarView(
                                children: <Widget>[
                                  Container(
                                    child: getMyContestTabs(
                                      fantasyType: 1,
                                      sportsType: _mapSportTypes[page],
                                    ),
                                  ),
                                  Container(
                                    child: getMyContestTabs(
                                      fantasyType: 2,
                                      sportsType: _mapSportTypes[page],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      child: getMyContestTabs(
                        fantasyType: 1,
                        sportsType: _mapSportTypes[page],
                      ),
                    );
            }).toList(),
          ),
        ),
        bShowLoader ? Loader() : Container(),
      ],
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
