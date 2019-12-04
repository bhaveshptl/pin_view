import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/addcashbutton.dart';
import 'package:playfantasy/commonwidgets/leaguetitleepoc.dart';
import 'dart:io';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/mysheet.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/modal/prediction.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/searchcontest.dart';
import 'package:playfantasy/leaguedetail/myteams.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/leaguedetail/contests.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/mymatches/joined_contests.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/createcontest/createcontest.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/leaguedetail/prediction/mysheets.dart';
import 'package:playfantasy/leaguedetail/prediction/prediction.dart';
import 'package:playfantasy/leaguedetail/prediction/createsheet/createsheet.dart';

class LeagueDetail extends StatefulWidget {
  final League league;
  final int sportType;
  final List<League> leagues;
  final Function onSportChange;
  final Map<String, int> mapSportTypes;
  final bool activateDeepLinkingNavigation;
  final double cashBalance;

  LeagueDetail(
    this.league, {
    this.leagues,
    this.sportType,
    this.onSportChange,
    this.mapSportTypes,
    this.cashBalance,
    this.activateDeepLinkingNavigation,
  });

  @override
  State<StatefulWidget> createState() => LeagueDetailState();
}

class LeagueDetailState extends State<LeagueDetail>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  L1 l1Data;
  String cookie;
  int _sportType;
  List<MyTeam> _myTeams;
  String title = "Contest".toUpperCase();
  bool isIos = false;
  bool bIsPredictionAvailable = false;
  List<MySheet> _mySheets;
  Prediction predictionData;
  int joinedContestCount = 0;
  List<int> predictionContestIds;
  int joinedPredictionContestCount = 0;
  StreamSubscription _streamSubscription;
  Map<String, dynamic> l1UpdatePackate = {};
  Map<int, List<MyTeam>> _mapContestTeams = {};
  Map<int, List<MySheet>> _mapContestSheets = {};
  Map<String, List<Contest>> _mapMyContests = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic> myContestIds = {};
  bool deactivateDeepLinkingNavigation = true;
  TabController tabController;
  int activeTabIndex = 0;
  final CreateTeamState createTeamState = new CreateTeamState();

  @override
  initState() {
    super.initState();
    bIsPredictionAvailable = widget.league.prediction == 1;
    deepLinkingNavigationManager();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
    _sportType = widget.sportType;
    _createL1WSObject();

    _getMyContests();
    tabController =
        TabController(length: bIsPredictionAvailable ? 2 : 1, vsync: this);
    tabController.addListener(() {
      setState(() {
        activeTabIndex = tabController.index;
      });
    });

    if (Platform.isIOS) {
      isIos = true;
    }
  }

  _onWsMsg(data) {
    if (data["bReady"] == 1) {
      _getL1Data();
    } else if (data["iType"] == RequestType.GET_ALL_L1 &&
        data["bSuccessful"] == true) {
      showLoader(false);
      List<dynamic> contestIds = data["data"]["myPredictionContestIds"]
          [widget.league.leagueId.toString()];
      predictionContestIds = contestIds != null
          ? contestIds.map((f) => (f as int).toInt()).toList()
          : [];
      getMyContestMySheets(predictionContestIds);

      setState(() {
        l1Data = L1.fromJson(data["data"]["l1"]);
        _myTeams = (data["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
        myContestIds = data["data"]["mycontestid"];
        joinedContestCount = (data["data"]["mycontestid"]
                    [widget.league.leagueId.toString()] ==
                null)
            ? 0
            : data["data"]["mycontestid"][widget.league.leagueId.toString()]
                .length;
        joinedPredictionContestCount = predictionContestIds.length;
        if (data["data"]["prediction"] != null) {
          predictionData = Prediction.fromJson(data["data"]["prediction"]);
        }
        if (data["data"]["mySheets"] != null &&
            data["data"]["mySheets"] != "") {
          _mySheets = (data["data"]["mySheets"] as List<dynamic>).map((f) {
            return MySheet.fromJson(f);
          }).toList();
        }
      });
    } else if (l1Data != null &&
        data["iType"] == RequestType.L1_DATA_REFRESHED &&
        data["bSuccessful"] == true) {
      _applyL1DataUpdate(data["diffData"]["ld"]);
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
    } else if (data["iType"] == RequestType.PREDICTION_DATA_UPDATE) {
      if (data["leagueId"] == widget.league.leagueId) {
        _applyPredictionUpdate(data["diffData"]);
      }
    } else if (data["iType"] == RequestType.MY_SHEET_ADDED &&
        data["bSuccessful"] == true) {
      MySheet sheetAdded = MySheet.fromJson(data["data"]);
      int existingIndex = -1;
      List<int>.generate(_mySheets.length, (index) {
        MySheet mySheet = _mySheets[index];
        if (mySheet.id == sheetAdded.id) {
          existingIndex = index;
        }
      });
      if (existingIndex == -1) {
        setState(() {
          _mySheets.add(sheetAdded);
        });
      } else {
        setState(() {
          _mySheets[existingIndex] = sheetAdded;
        });
      }
    }
  }

  deepLinkingNavigationManager() {
    if (widget.activateDeepLinkingNavigation != null) {
      if (widget.activateDeepLinkingNavigation) {
        deactivateDeepLinkingNavigation = false;
      }
    }
  }

  launchCreateTeamByDeepLinking() async {
    var result;
    if (!deactivateDeepLinkingNavigation) {
      if (squadStatus()) {
        result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: l1Data,
              mode: TeamCreationMode.CREATE_TEAM,
            ),
          ),
        );
      }
    }
  }

  _applyPredictionUpdate(List<dynamic> updates) {
    Map<String, dynamic> predictionJson = predictionData.toJson();
    updates.forEach((diff) {
      if (diff["kind"] == "E") {
        dynamic tmpData = predictionJson;
        List<int>.generate(diff["path"].length - 1, (index) {
          tmpData = tmpData[diff["path"][index]];
        });
        tmpData[diff["path"][diff["path"].length - 1]] = diff["rhs"];
      } else if (diff["kind"] == "A" && diff["item"]["kind"] == "N") {
        dynamic tmpData = predictionJson;
        List<int>.generate(diff["path"].length - 1, (index) {
          tmpData = tmpData[diff["path"][index]];
        });
        if (tmpData[diff["path"][diff["path"].length - 1]].length <=
            diff["index"]) {
          tmpData[diff["path"][diff["path"].length - 1]]
              .add(diff["item"]["rhs"]);
        }
      }
    });
    setState(() {
      predictionData = Prediction.fromJson(predictionJson);
    });
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    for (Contest _contest in l1Data.contests) {
      if (_contest.id == _data["cId"]) {
        if (myContestIds[_data["lId"].toString()] == null) {
          myContestIds[_data["lId"].toString()] = [];
        }
        if ((myContestIds[_data["lId"].toString()]).indexOf(_data["cId"]) ==
            -1) {
          (myContestIds[_data["lId"].toString()]).add(_data["cId"]);
        }
        setState(() {
          _contest.joined = _data["iJC"];
          joinedContestCount =
              myContestIds[widget.league.leagueId.toString()].length;
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
    if (_data["initialSquad"] != null) {
      setState(() {
        l1Data.initialSquad = _data["initialSquad"] != null
            ? (_data["initialSquad"] as List)
                .map((i) => (i as int).toInt())
                .toList()
            : [];
      });
    }
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
      List<Contest> updatedContests = [];
      List<Contest> _lstRemovedContests = (_data["lstRemoved"] as List)
          .map((i) => Contest.fromJson(i))
          .toList();
      for (Contest _contest in l1Data.contests) {
        bool bFound = false;
        for (Contest _removedContest in _lstRemovedContests) {
          if (_removedContest.id == _contest.id) {
            bFound = true;
          }
        }
        if (!bFound) {
          updatedContests.add(_contest);
        }
      }
      print("Contest removed!!");
      l1Data.contests = updatedContests;
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
      if (_modifiedleague["lstAdded"] != null) {
        (_modifiedleague["lstAdded"] as List).forEach((round) {
          l1Data.league.rounds.add(round);
        });
      }

      if (_modifiedleague["lstRemoved"] != null) {
        (_modifiedleague["lstRemoved"] as List).forEach((round) {
          l1Data.league.rounds.forEach((origRound) {
            l1Data.league.rounds.remove(origRound);
          });
        });
      }

      if (_modifiedleague["lstModified"] != null) {
        _modifiedleague["lstModified"].forEach((round) {
          l1Data.league.rounds.forEach((Round origRound) {
            if (round["id"] == origRound.id) {
              if (round["lstAdded"].length > 0) {
                round["lstAdded"].forEach((MatchInfo match) {
                  origRound.matches.add(match);
                });
              }

              if (round["lstRemoved"].length > 0) {
                round["lstRemoved"].forEach((match) {
                  origRound.matches.forEach((MatchInfo origMatch) {
                    if (origMatch.id == match["id"]) {
                      origRound.matches.remove(origMatch);
                    }
                  });
                });
              }

              if (round["lstModified"].length > 0) {
                round["lstModified"].forEach((match) {
                  origRound.matches.forEach((MatchInfo origMatch) {
                    if (origMatch.id == match["id"]) {
                      if (match["sportDesc"] != null) {
                        origMatch.sportDesc = match["sportDesc"];
                      }
                      if (match["name"] != null) {
                        origMatch.name = match["name"];
                      }
                      if (match["startTime"] != null) {
                        origMatch.startTime = match["startTime"];
                      }
                      if (match["endTime"] != null) {
                        origMatch.endTime = match["endTime"];
                      }
                      if (match["status"] != null) {
                        origMatch.status = match["status"];
                      }
                      if (match["sportType"] != null) {
                        origMatch.sportType = match["sportType"];
                      }
                      if (match["squad"] == 0 || match["squad"] == 1) {
                        origMatch.squad = match["squad"];
                      }
                    }
                  });
                });
              }
            }
          });
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
    l1UpdatePackate["withPrediction"] = true;
    _getL1Data();
  }

  _getL1Data() {
    FantasyWebSocket().sendMessage(l1UpdatePackate);
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
    }).whenComplete(() {
      showLoader(false);
    });
  }

  onContestTeamsUpdated() async {
    await _getMyContests();
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
      }).whenComplete(() {
        showLoader(false);
      });
    }
  }

  getMyContestMySheets(List<int> contests) {
    if (contests != null && contests.length > 0) {
      http.Request req = http.Request("POST",
          Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_SHEETS));
      req.body = json.encode(contests);
      return HttpManager(http.Client())
          .sendRequest(req)
          .then((http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<int, List<MySheet>> _mapContestMySheets = {};
          Map<String, dynamic> response = json.decode(res.body);
          response.keys.forEach((k) {
            List<dynamic> sheetIds = response[k];
            List<MySheet> mySheets = [];
            sheetIds.forEach((sheetId) {
              _mySheets.forEach((sheet) {
                if (sheet.id == sheetId) {
                  mySheets.add(sheet);
                }
              });
            });
            if (mySheets.length > 0) {
              _mapContestMySheets[int.parse(k)] = mySheets;
            }
          });
          setState(() {
            _mapContestSheets = _mapContestMySheets;
          });
        }
      }).whenComplete(() {
        showLoader(false);
      });
    }
  }

  _launchAddCash() async {
    showLoader(true);
    routeLauncher.launchAddCash(
      context,
      onSuccess: (result) {},
      onComplete: () {
        showLoader(false);
      },
    );
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  launchMySheet() async {
    Quiz quiz = predictionData.quizSet.quiz["0"];
    if (predictionData.league.qfVisibility != 0 &&
        quiz != null &&
        quiz.questions != null &&
        quiz.questions.length > 0) {
      final result = await Navigator.of(context).push(
        FantasyPageRoute(
          pageBuilder: (context) => MySheets(
            league: widget.league,
            predictionData: predictionData,
            mySheets: _mySheets,
          ),
        ),
      );
    } else {
      ActionUtil().showMsgOnTop(
          "Questions are not yet set for this prediction. Please try again later!!",
          context);
      // _scaffoldKey.currentState.showSnackBar(SnackBar(
      //   content: Text(
      //       "Questions are not yet set for this prediction. Please try again later!!"),
      // ));
    }
  }

  squadStatus() {
    if (l1Data.league.rounds[0].matches[0].squad == 0) {
      ActionUtil().showMsgOnTop(
          "Squad is not yet announced. Please try again later.", context);
      // _scaffoldKey.currentState.showSnackBar(
      //   SnackBar(
      //     content: Row(
      //       children: <Widget>[
      //         Expanded(
      //           child:
      //               Text("Squad is not yet announced. Please try again later."),
      //         ),
      //       ],
      //     ),
      //     duration: Duration(
      //       seconds: 3,
      //     ),
      //   ),
      // );
      return false;
    }
    return true;
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

  _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert!!"),
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
      FantasyPageRoute(
        pageBuilder: (context) => SearchContest(
          leagues: widget.leagues,
        ),
      ),
    );
  }

  _onCreateContest(BuildContext context) async {
    if (squadStatus()) {
      var createTeamResult;
      var waitForCreateTeam = _myTeams.length == 0;
      if (_myTeams.length == 0) {
        waitForCreateTeam = false;
        createTeamResult = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: l1Data,
              mode: TeamCreationMode.CREATE_TEAM,
            ),
          ),
        );
      }
      if (!waitForCreateTeam ||
          (waitForCreateTeam && createTeamResult != null)) {
        var result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => CreateContest(
              league: widget.league,
              l1data: l1Data,
              sportsType: widget.sportType,
              myTeams: _myTeams,
            ),
          ),
        );
        ActionUtil().showMsgOnTop(result, context);
      }
    }
  }

  _onBottomButtonClick(int index) async {
    var result;
    switch (index) {
      case 0:
        if (activeTabIndex == 0) {
        } else {
          _showComingSoonDialog();
        }
        break;
      case 1:
        if (activeTabIndex == 0) {
          if (squadStatus()) {
            result = await Navigator.of(context).push(
              FantasyPageRoute(
                pageBuilder: (context) => MyTeams(
                  league: widget.league,
                  l1Data: l1Data,
                  myTeams: _myTeams,
                ),
              ),
            );
          }
        } else {
          launchMySheet();
        }
        break;
      case 2:
        final result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (BuildContext context) => JoinedContests(
                l1Data: l1Data,
                myTeams: _myTeams,
                league: widget.league,
                sportsType: widget.sportType,
                onContestTeamsUpdated: onContestTeamsUpdated),
          ),
        );

        await _getMyContests();
        break;
      case 3:
        if (activeTabIndex == 0) {
          if (squadStatus()) {
            result = await Navigator.of(context).push(
              FantasyPageRoute(
                pageBuilder: (context) => CreateTeam(
                  league: widget.league,
                  l1Data: l1Data,
                  mode: TeamCreationMode.CREATE_TEAM,
                ),
              ),
            );
          }
        } else {
          launchCreateSheet();
        }
        break;
    }
    if (result != null) {
      ActionUtil().showMsgOnTop(result, context);
      // _scaffoldKey.currentState.showSnackBar(
      //   SnackBar(
      //     content: Text(result),
      //     duration: Duration(
      //       seconds: 3,
      //     ),
      //   ),
      // );
    }
  }

  launchCreateSheet() async {
    Quiz quiz = predictionData.quizSet.quiz["0"];
    if (predictionData.league.qfVisibility != 0 &&
        quiz != null &&
        quiz.questions != null &&
        quiz.questions.length > 0) {
      final result = await Navigator.of(context).push(
        FantasyPageRoute(
          pageBuilder: (context) => CreateSheet(
            league: widget.league,
            predictionData: predictionData,
            mode: SheetCreationMode.CREATE_SHEET,
          ),
        ),
      );
      if (result != null) {
        ActionUtil().showMsgOnTop(result, context);
        // _scaffoldKey.currentState
        //     .showSnackBar(SnackBar(content: Text("$result")));
      }
    } else {
      ActionUtil().showMsgOnTop(
          "Questions are not yet set for this prediction. Please try again later!!",
          context);
      // _scaffoldKey.currentState.showSnackBar(SnackBar(
      //   content: Text(
      //       "Questions are not yet set for this prediction. Please try again later!!"),
      // ));
    }
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: strings.rupee,
      decimalDigits: 2,
    );

    bool notAllowJoinedContests =
        (activeTabIndex == 0 && joinedContestCount == 0) ||
            (activeTabIndex == 1 && joinedPredictionContestCount == 0);

    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            "images/Arrow.png",
            height: 18.0,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        titleSpacing: 0.0,
        title: Row(
          children: <Widget>[
            Expanded(
              child: LeagueTitleEPOC(
                title: widget.league.teamA.name +
                    " vs " +
                    widget.league.teamB.name,
                timeInMiliseconds: widget.league.matchStartTime,
                onTimeComplete: () {},
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          AddCashButton(
            text: formatCurrency.format(widget.cashBalance),
            onPressed: () {
              _launchAddCash();
            },
          ),
          // FlatButton(
          //   child: Row(
          //     children: <Widget>[
          //       Icon(
          //         Icons.search,
          //         color: Colors.white,
          //       ),
          //       Text(
          //         " Contest code".toUpperCase(),
          //         style: Theme.of(context).primaryTextTheme.button.copyWith(
          //               color: Colors.white,
          //             ),
          //       ),
          //     ],
          //   ),
          //   onPressed: () {
          //     _onSearchContest();
          //   },
          // ),
        ],
        elevation: 0.0,
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 56.0,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Container(
                      margin: EdgeInsets.only(left: 16.0, right: 16.0),
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0.0, 0),
                            color: Colors.grey.shade400,
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                      child: FlatButton(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 2.0, bottom: 2.0, right: 8.0),
                              child: Image.asset("images/Contest_Icon.png"),
                            ),
                            Text(
                              "CREATE CONTEST",
                              style: TextStyle(
                                color: Color.fromRGBO(41, 41, 41, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          _onCreateContest(context);
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Container(
                      margin: EdgeInsets.only(right: 16.0, left: 16.0),
                      height: 30.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0.0, 0),
                            color: Colors.grey.shade400,
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                      child: FlatButton(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 4.0, bottom: 4.0, right: 8.0),
                              child: Image.asset("images/ContestCode_Icon.png"),
                            ),
                            Text(
                              "CONTEST CODE",
                              style: TextStyle(
                                color: Color.fromRGBO(41, 41, 41, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          _onSearchContest();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bIsPredictionAvailable
              ? Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.black,
                    labelStyle:
                        Theme.of(context).primaryTextTheme.title.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 4.0,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    tabs: <Widget>[
                      Tab(
                        child: Text(
                          "Contest".toUpperCase(),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "Prediction".toUpperCase(),
                        ),
                      )
                    ],
                  ),
                )
              : Container(),
          bIsPredictionAvailable
              ? Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: <Widget>[
                      l1Data == null
                          ? Container()
                          : Contests(
                              l1Data: l1Data,
                              myTeams: _myTeams,
                              league: widget.league,
                              sportsType: _sportType,
                              showLoader: showLoader,
                              scaffoldKey: _scaffoldKey,
                              mapContestTeams: _mapContestTeams,
                            ),
                      predictionData == null
                          ? Container()
                          : PredictionView(
                              mySheets: _mySheets,
                              league: widget.league,
                              showLoader: showLoader,
                              scaffoldKey: _scaffoldKey,
                              prediction: predictionData,
                              predictionContestIds: predictionContestIds,
                              mapContestSheets: _mapContestSheets,
                            ),
                    ],
                  ),
                )
              : Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: <Widget>[
                      l1Data == null
                          ? Container()
                          : Contests(
                              l1Data: l1Data,
                              myTeams: _myTeams,
                              league: widget.league,
                              sportsType: _sportType,
                              showLoader: showLoader,
                              scaffoldKey: _scaffoldKey,
                              mapContestTeams: _mapContestTeams,
                              onContestTeamsUpdated: onContestTeamsUpdated),
                    ],
                  ),
                ),
          Container(
            height: 64.0,
            padding: isIos ? EdgeInsets.only(bottom: 7.5) : null,
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
                (activeTabIndex == 0 &&
                            _myTeams != null &&
                            _myTeams.length > 0) ||
                        (activeTabIndex == 1 &&
                            _mySheets != null &&
                            _mySheets.length > 0)
                    ? Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                height: 72.0,
                                child: FlatButton(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                              activeTabIndex == 0
                                                  ? (_myTeams == null
                                                      ? "0"
                                                      : _myTeams.length
                                                          .toString())
                                                  : (_mySheets == null
                                                      ? "0"
                                                      : _mySheets.length
                                                          .toString()),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              activeTabIndex == 0
                                                  ? "My Teams"
                                                  : "My Sheets",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    _onBottomButtonClick(1);
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                              color: notAllowJoinedContests
                                                  ? Colors.grey
                                                  : Colors.orange,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              activeTabIndex == 0
                                                  ? joinedContestCount
                                                      .toString()
                                                  : joinedPredictionContestCount
                                                      .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              activeTabIndex == 0
                                                  ? "Joined Contests"
                                                  : "Joined Predictions",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onPressed: notAllowJoinedContests
                                      ? null
                                      : () {
                                          _onBottomButtonClick(2);
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 48.0,
                        padding: isIos ? EdgeInsets.only(bottom: 7.0) : null,
                        // width: MediaQuery.of(context).size.width / 1.6,
                        child: ColorButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(
                                    right: 8.0, top: 6.0, bottom: 6.0),
                                child: Image.asset(
                                  "images/CricketBall_Icon.png",
                                ),
                              ),
                              Text(
                                (activeTabIndex == 0
                                        ? "Create team"
                                        : "Create prediction")
                                    .toUpperCase(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: isIos
                                          ? FontWeight.w600
                                          : FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            _onBottomButtonClick(3);
                          },
                        ),
                      )
              ],
            ),
          )
        ],
      ),
    );
  }
}
