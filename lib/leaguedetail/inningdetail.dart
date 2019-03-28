import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/l1.dart' as L1;
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/createcontest.dart';
import 'package:playfantasy/leaguedetail/myteams.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/leaguedetail/contests.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class InningDetails extends StatefulWidget {
  final L1.Team team;
  final League league;
  final List<League> leagues;
  final Function onSportChange;

  InningDetails({this.league, this.onSportChange, this.leagues, this.team});

  @override
  InningDetailsState createState() => InningDetailsState();
}

class InningDetailsState extends State<InningDetails> {
  String cookie;
  int _sportType;
  L1.L1 inningsData;
  List<MyTeam> _myTeams;
  bool bShowLoader = false;
  StreamSubscription _streamSubscription;
  Map<String, dynamic> inningsDataObj = {};
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<String, List<Contest>> _mapMyContests = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);

    _getInningsData();
  }

  _getInningsData() async {
    await _getSportsType();

    inningsDataObj["sportsId"] = _sportType;
    inningsDataObj["teamId"] = widget.team.id;
    inningsDataObj["id"] = widget.league.leagueId;
    inningsDataObj["inningsId"] = widget.team.inningsId;
    inningsDataObj["iType"] = RequestType.REQ_L1_INNINGS_ALL_DATA;

    _getMyContests();
    FantasyWebSocket().sendMessage(inningsDataObj);
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
        BaseUrl().apiUrl + ApiUtil.GET_MY_CONTESTS + _sportType.toString(),
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

  showLoader(bool bShow) {
    setState(() {
      bShowLoader = bShow;
    });
  }

  _getMyContestMyTeams(Map<String, List<Contest>> _mapMyContests) async {
    List<int> _contestIds = [];
    List<Contest> _contests = _mapMyContests[widget.league.leagueId.toString()];
    if (_contests != null) {
      for (Contest contest in _contests) {
        _contestIds.add(contest.id);
      }

      http.Request req = http.Request("POST",
          Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
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

  _onWsMsg(data) {
    if (data["iType"] == RequestType.REQ_L1_INNINGS_ALL_DATA &&
        data["bSuccessful"] == true) {
      setState(() {
        inningsData = L1.L1.fromJson(data["data"]["l1"]);
        _myTeams = (data["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
      });
    } else if (data["iType"] == RequestType.L1_DATA_REFRESHED &&
        data["bSuccessful"] == true) {
      if (data["diffData"]["ld"].length > 0) {
        _applyL1DataUpdate(data["diffData"]["ld"]);
      }
      if (data["diffData"]["ld1"].length > 0) {
        _applyL1DataUpdate(data["diffData"]["ld1"]);
      }
      if (data["diffData"]["ld2"].length > 0) {
        _applyL1DataUpdate(data["diffData"]["ld2"]);
      }
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _updateJoinCount(data["data"]);
      _updateContestTeams(data["data"]);
    } else if (data["iType"] == RequestType.MY_TEAMS_ADDED &&
        data["bSuccessful"] == true &&
        widget.team.inningsId == data["data"]["inningsId"]) {
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

  _updateJoinCount(Map<String, dynamic> _data) {
    for (Contest _contest in inningsData.contests) {
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
          for (Contest _curContest in inningsData.contests) {
            if (_curContest.id == _contest.id) {
              bFound = true;
            }
          }
          if (!bFound && inningsData.league.id == _contest.leagueId) {
            setState(() {
              inningsData.contests.add(_contest);
            });
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
        for (Contest _contest in inningsData.contests) {
          if (_removedContest.id == _contest.id) {
            _removedContestIndexes.add(index);
          }
          index++;
        }
      }
      setState(() {
        for (int i = _removedContestIndexes.length - 1; i >= 0; i--) {
          inningsData.contests.removeAt(_removedContestIndexes[i]);
        }
      });
    }

    if (_data["lstModified"] != null && _data["lstModified"].length >= 1) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in inningsData.contests) {
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
  }

  _launchAddCash() async {
    showLoader(true);
    routeLauncher.launchAddCash(context, onComplete: () {
      showLoader(false);
    });
  }

  _onNavigationSelectionChange(BuildContext context, int index) async {
    var result;
    switch (index) {
      case 0:
        result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => MyContests(
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
        if (squadStatus()) {
          result = await Navigator.of(context).push(
            FantasyPageRoute(
              pageBuilder: (context) => CreateContest(
                    league: widget.league,
                    l1data: inningsData,
                    myTeams: _myTeams,
                  ),
            ),
          );
        }
        break;
      case 3:
        if (squadStatus()) {
          result = await Navigator.of(context).push(
            FantasyPageRoute(
              pageBuilder: (context) => MyTeams(
                    league: widget.league,
                    l1Data: inningsData,
                    myTeams: _myTeams,
                  ),
            ),
          );
        }
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

  squadStatus() {
    if (inningsData.league.rounds[0].matches[0].squad == 0) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Expanded(
                child:
                    Text("Squad is not yet announced. Please try again later."),
              ),
            ],
          ),
          duration: Duration(
            seconds: 3,
          ),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.league.teamA.name + " vs " + widget.league.teamB.name;
    if (_sportType == 1) {
      if (widget.league.teamA.inningsId == widget.team.inningsId) {
        title = widget.league.teamA.name + " inning";
      } else {
        title = widget.league.teamB.name + " inning";
      }
    } else {
      if (widget.league.teamA.inningsId == widget.team.inningsId) {
        title = "First" + " half";
      } else {
        title = "Second" + " half";
      }
    }
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
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    // _showFilterDialog();
                  },
                ),
              )
            ],
          ),
          body: Container(
            decoration: AppConfig.of(context).showBackground
                ? BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/background.png"),
                        repeat: ImageRepeat.repeat),
                  )
                : null,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: LeagueCard(
                        widget.league,
                        clickable: false,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: inningsData == null
                      ? Container()
                      : Contests(
                          showLoader: showLoader,
                          l1Data: inningsData,
                          myTeams: _myTeams,
                          league: widget.league,
                          scaffoldKey: _scaffoldKey,
                          mapContestTeams: _mapContestTeams,
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              LobbyBottomNavigation(_onNavigationSelectionChange, 1),
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
