import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';
import 'package:playfantasy/lobby/searchcontest.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/createcontest.dart';
import 'package:playfantasy/leaguedetail/innings.dart';
import 'package:playfantasy/leaguedetail/myteams.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  L1 l1Data;
  String cookie;
  int _sportType = 1;
  List<MyTeam> _myTeams;
  String title = "Match";
  bool bShowInnings = false;
  Map<String, dynamic> l1UpdatePackate = {};
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<String, List<Contest>> _mapMyContests = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TabController tabController;

  // bool _bShowLoader = false;

  // _showLoader(bool bShow) {
  //   setState(() {
  //     _bShowLoader = bShow;
  //   });
  // }

  @override
  initState() {
    super.initState();
    sockets.register(_onWsMsg);
    _createL1WSObject();

    _getMyContests();
    tabController = TabController(length: 2, vsync: this);
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      // _showLoader(true);
      _getL1Data();
    } else if (_response["iType"] == RequestType.GET_ALL_L1 &&
        _response["bSuccessful"] == true) {
      setState(() {
        l1Data = L1.fromJson(_response["data"]["l1"]);
        _myTeams = (_response["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
      });
      // _showLoader(false);
    } else if (_response["iType"] == RequestType.L1_DATA_REFRESHED &&
        _response["bSuccessful"] == true) {
      _applyL1DataUpdate(_response["diffData"]["ld"]);
    } else if (_response["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        _response["bSuccessful"] == true) {
      _updateJoinCount(_response["data"]);
      _updateContestTeams(_response["data"]);
    } else if (_response["iType"] == RequestType.MY_TEAMS_ADDED &&
        _response["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(_response["data"]);
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
    } else if (_response["iType"] == RequestType.MY_TEAM_MODIFIED &&
        _response["bSuccessful"] == true) {
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

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      List<Contest> _addedContests =
          (_data["lstAdded"] as List).map((i) => Contest.fromJson(i)).toList();
      setState(() {
        for (Contest _contest in _addedContests) {
          bool bFound = false;
          for (Contest _curContest in l1Data.contests) {
            if (_curContest.id == _contest.id) {
              bFound = true;
            }
          }
          if (!bFound && l1Data.league.id == _contest.leagueId) {
            l1Data.contests.add(_contest);
          }
        }
      });
    }
    if (_data["lstRemoved"] != null && _data["lstRemoved"].length > 0) {
      List<int> _removedContestIndexes = [];
      List<Contest> _lstRemovedContests = (_data["lstRemoved"] as List)
          .map((i) => Contest.fromJson(i))
          .toList();
      for (Contest _removedContest in _lstRemovedContests) {
        int index = 0;
        for (Contest _contest in l1Data.contests) {
          if (_removedContest.id == _contest.id) {
            _removedContestIndexes.add(index);
          }
          index++;
        }
      }
      setState(() {
        for (int i = _removedContestIndexes.length - 1; i >= 0; i--) {
          l1Data.contests.removeAt(_removedContestIndexes[i]);
        }
      });
    }
    if (_data["lstModified"] != null && _data["lstModified"].length >= 1) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in l1Data.contests) {
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
                  _contest.teamsAllowed != _changedContest["teamsAllowed"]) {
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
                  _contest.regStartTime != _changedContest["regStartTime"]) {
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
                  _contest.visibilityId != _changedContest["visibilityId"]) {
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
                _contest.contestJoinCode = _changedContest["contestJoinCode"];
              }
              if (_changedContest["joined"] != null &&
                  _contest.joined != _changedContest["joined"]) {
                _contest.joined = _changedContest["joined"];
              }
              if (_changedContest["bonusAllowed"] != null &&
                  _contest.bonusAllowed != _changedContest["bonusAllowed"]) {
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
                  _contest.brand["info"] != _changedContest["brand"]["info"]) {
                _contest.brand["info"] = _changedContest["brand"]["info"];
              }
              if ((_changedContest["lstAdded"] as List).length > 0) {
                for (dynamic _prize in _changedContest["lstAdded"]) {
                  _contest.prizeDetails.add(_prize);
                }
              }
              if ((_changedContest["lstModified"] as List).length > 0) {
                for (dynamic _modifiedPrize in _changedContest["lstModified"]) {
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
      }
    }
    if (_data["league"] != null) {
      Map<String, dynamic> _modifiedleague = _data["league"];
      if (_modifiedleague["name"] != null) {
        setState(() {
          l1Data.league.name = _modifiedleague["name"];
        });
      }
      if (_modifiedleague["startTime"] != null) {
        setState(() {
          l1Data.league.startTime = _modifiedleague["startTime"];
        });
      }
      if (_modifiedleague["endTime"] != null) {
        setState(() {
          l1Data.league.endTime = _modifiedleague["endTime"];
        });
      }
      if (_modifiedleague["status"] != null) {
        setState(() {
          l1Data.league.status = _modifiedleague["status"];
        });
      }
      if (_modifiedleague["fanTeamRules"] != null) {
        setState(() {
          l1Data.league.fanTeamRules = _modifiedleague["fanTeamRules"];
        });
      }
      if (_modifiedleague["allowedContestTypes"] != null) {
        setState(() {
          l1Data.league.allowedContestTypes =
              _modifiedleague["allowedContestTypes"];
        });
      }
    }
  }

  _createL1WSObject() async {
    await _getSportsType();
    l1UpdatePackate["iType"] = RequestType.GET_ALL_L1;
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["sportsId"] = _sportType;
    l1UpdatePackate["id"] = widget.league.leagueId;

    _getL1Data();
  }

  _getL1Data() {
    // _showLoader(true);
    sockets.sendMessage(l1UpdatePackate);
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        _sportType = int.parse(value);
      }
    });
  }

  _getMyContests() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.GET_MY_CONTESTS + _sportType.toString(),
      ),
    );
    HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
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
  }

  _launchAddCash() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCash(),
      ),
    );
    if (result != null) {
      _showTransactionResult(json.decode(result));
    }
  }

  _showTransactionResult(Map<String, dynamic> transactionResult) {
    if (transactionResult["authStatus"] == "Authorised") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionSuccess(transactionResult, () {
            Navigator.of(context).pop();
          });
        },
      );
    }
  }

  _onNavigationSelectionChange(BuildContext context, int index) async {
    var result;
    switch (index) {
      case 0:
        result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MyContests(
                  leagues: widget.leagues,
                  onSportChange: widget.onSportChange,
                ),
          ),
        );
        break;
      case 1:
        _launchAddCash();
        break;
      case 2:
        result = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CreateContest(
                league: widget.league,
                l1data: l1Data,
                myTeams: _myTeams,
              ),
        ));
        break;
      case 3:
        result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MyTeams(
                  league: widget.league,
                  l1Data: l1Data,
                  myTeams: _myTeams,
                ),
          ),
        );
        break;
    }
    if (result != null) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
    }
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
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _onSearchContest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchContest(
              leagues: widget.leagues,
            ),
      ),
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
                message: strings.get("CONTEST_FILTER"),
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _onSearchContest();
                  },
                ),
              ),
              Tooltip(
                message: strings.get("CONTEST_FILTER"),
                child: IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
              )
            ],
          ),
          body: Container(
            color: Color.fromARGB(255, 237, 237, 237),
            // decoration: BoxDecoration(
            //   // image: DecorationImage(
            //   //   image: AssetImage("images/1.png"),
            //   // ),
            //   gradient: LinearGradient(
            //     colors: [
            //       Color.fromARGB(255, 2, 80, 197),
            //       Color.fromARGB(255, 212, 63, 141)
            //     ],
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     // stops: [0.5, 1.0],
            //   ),
            //   // backgroundBlendMode: BlendMode.overlay,
            // ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: LeagueCard(
                        widget.league,
                        clickable: false,
                        tabBar: bShowInnings
                            ? TabBar(
                                labelColor: Colors.black87,
                                unselectedLabelColor: Colors.black38,
                                controller: tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  insets:
                                      EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                                ),
                                tabs: [
                                  Container(
                                    height: 24.0,
                                    child: Tab(
                                      text: "MATCH",
                                    ),
                                  ),
                                  Container(
                                    height: 24.0,
                                    child: Tab(
                                      text: "INNINGS",
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 2.0,
                ),
                Expanded(
                  child: Container(
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: bShowInnings
                          ? TabBarView(
                              controller: tabController,
                              children: <Widget>[
                                l1Data == null
                                    ? Container()
                                    : Contests(
                                        l1Data: l1Data,
                                        myTeams: _myTeams,
                                        league: widget.league,
                                        scaffoldKey: _scaffoldKey,
                                        mapContestTeams: _mapContestTeams,
                                      ),
                                l1Data == null
                                    ? Container()
                                    : Innings(
                                        l1Data: l1Data,
                                        myTeams: _myTeams,
                                        league: widget.league,
                                        leagues: widget.leagues,
                                        scaffoldKey: _scaffoldKey,
                                        mapContestTeams: _mapContestTeams,
                                        onSportChange: widget.onSportChange,
                                      ),
                              ],
                            )
                          : l1Data == null
                              ? Container()
                              : Contests(
                                  l1Data: l1Data,
                                  myTeams: _myTeams,
                                  league: widget.league,
                                  scaffoldKey: _scaffoldKey,
                                  mapContestTeams: _mapContestTeams,
                                ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              LobbyBottomNavigation(_onNavigationSelectionChange, 1),
        ),
        // _bShowLoader
        //     ? Center(
        //         child: Container(
        //           color: Colors.black54,
        //           child: Loader(),
        //           constraints: BoxConstraints.expand(),
        //         ),
        //       )
        //     : Container(),
      ],
    );
  }
}
