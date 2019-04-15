import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_share_me/flutter_share_me.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/createteam/teampreview.dart';
import 'package:playfantasy/contestdetail/viewteam.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/contestdetail/contestdetailscard.dart';

const TABLE_COLUMN_PADDING = 28;

class ContestDetail extends StatefulWidget {
  final League league;
  final Contest contest;
  final List<MyTeam> mapContestTeams;

  final L1 l1Data;
  final List<MyTeam> myTeams;

  ContestDetail({
    this.league,
    this.l1Data,
    this.contest,
    this.myTeams,
    this.mapContestTeams,
  });

  @override
  State<StatefulWidget> createState() => ContestDetailState();
}

class ContestDetailState extends State<ContestDetail> with RouteAware {
  L1 _l1Data;
  String cookie;
  Timer pollTimer;
  int _sportType = 1;
  List<MyTeam> _myTeams;

  int curPage = 0;
  final int rowsPerPage = 25;
  List<MyTeam> _allTeams = [];
  bool bDownloadTeamEnabled = false;
  List<MyTeam> _mapContestTeams = [];
  bool bIsAllTeamsRequestInProgress = false;
  Map<String, dynamic> l1UpdatePackate = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MyTeam teamToView;
  ScrollController controller;
  bool bShowJoinContest = false;
  bool bWaitingForTeamCreation = false;
  bool waitToLoadL1ForViewTeam = false;

  StreamSubscription _streamSubscription;

  Duration pollTime;
  List<int> myTeamsId = [];

  @override
  initState() {
    super.initState();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);

    _createAndReqL1WS();
    if (widget.mapContestTeams == null) {
      _getContestMyTeams();
    }
    _mapContestTeams =
        widget.mapContestTeams == null ? [] : widget.mapContestTeams;
    _mapContestTeams.forEach((MyTeam team) {
      myTeamsId.add(team.id);
    });

    initAllTeams();
    _getInitData();
    controller = new ScrollController()..addListener(_scrollListener);
  }

  initAllTeams() async {
    final teams = await _getContestTeams(0, rowsPerPage);
    setState(() {
      _allTeams.addAll(teams);
    });
  }

  _getInitData() async {
    Future<dynamic> futureInitData =
        SharedPrefHelper().getFromSharedPref(ApiUtil.KEY_INIT_DATA);
    await futureInitData.then((onValue) {
      pollTime = Duration(seconds: json.decode(onValue)["pollTime"]);
      if (widget.league.status == LeagueStatus.LIVE) {
        _startPolling();
      }
    });
  }

  _createAndReqL1WS() async {
    await _getSportsType();

    l1UpdatePackate["iType"] = RequestType.GET_ALL_L1;
    l1UpdatePackate["bResAvail"] = true;
    l1UpdatePackate["withPrediction"] = true;
    l1UpdatePackate["sportsId"] = _sportType;
    l1UpdatePackate["id"] = widget.league.leagueId;

    if (widget.myTeams == null || widget.l1Data == null) {
      _getL1Data();
    } else {
      _l1Data = widget.l1Data;
      _myTeams = widget.myTeams;
    }
  }

  void _scrollListener() async {
    int offset = curPage * rowsPerPage;
    if (controller.position.extentAfter < 100 &&
        !bIsAllTeamsRequestInProgress &&
        offset < widget.contest.joined) {
      final teams = await _getContestTeams(offset, rowsPerPage);
      setState(() {
        _allTeams.addAll(teams);
      });
    }
  }

  _startPolling() {
    if (pollTime != null) {
      pollTimer = Timer(
        pollTime,
        () async {
          await _getContestMyTeams();
          final teams = await _getContestTeams(0, curPage * rowsPerPage);
          if (teams != null && teams.length != 0) {
            setState(() {
              _allTeams = teams;
            });
          }
          _startPolling();
        },
      );
    }
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

  _getContestMyTeams() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
    req.body = json.encode([widget.contest.id]);
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

        _mapContestTeams = _mapContestMyTeams[widget.contest.id] == null
            ? []
            : _mapContestMyTeams[widget.contest.id];
        setState(() {
          _mapContestTeams.forEach((MyTeam team) {
            myTeamsId.add(team.id);
          });
        });
      }
    });
  }

  _onWsMsg(data) {
    if ((data["iType"] == RequestType.GET_ALL_L1 ||
            data["iType"] == RequestType.REQ_L1_INNINGS_ALL_DATA) &&
        data["bSuccessful"] == true) {
      if (waitToLoadL1ForViewTeam) {
        _l1Data = L1.fromJson(data["data"]["l1"]);
        _myTeams = (data["data"]["myteams"] as List)
            .map((i) => MyTeam.fromJson(i))
            .toList();
        _onViewTeam(teamToView);
      } else {
        setState(() {
          _l1Data = L1.fromJson(data["data"]["l1"]);
          _myTeams = (data["data"]["myteams"] as List)
              .map((i) => MyTeam.fromJson(i))
              .toList();
        });
      }
    } else if (data["iType"] == RequestType.L1_DATA_REFRESHED &&
        data["bSuccessful"] == true) {
      _applyL1DataUpdate(data["diffData"]["ld"]);
    } else if (data["iType"] == RequestType.MY_TEAMS_ADDED &&
        data["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(data["data"]);
      setState(() {
        bool bFound = false;
        for (MyTeam _myTeam in _myTeams) {
          if (_myTeam.id == teamAdded.id) {
            bFound = true;
          }
        }
        if (!bFound) {
          _myTeams.add(teamAdded);
        }

        if (bShowJoinContest) {
          _onJoinContest(widget.contest);
        }
        bWaitingForTeamCreation = false;
      });
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _updateJoinCount(data["data"]);
      _updateContestTeams(data["data"]);
    }
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    if (widget.contest.id == _data["cId"]) {
      setState(() {
        widget.contest.joined = _data["iJC"];
      });
    }
  }

  showLoader(bool bShow) {
    AppConfig.of(context).store.dispatch(
          bShow ? LoaderShowAction() : LoaderHideAction(),
        );
  }

  _updateContestTeams(Map<String, dynamic> _data) {
    Map<String, dynamic> _mapContestTeamsUpdate = _data["teamsByContest"];
    _mapContestTeamsUpdate.forEach((String key, dynamic _contestTeams) {
      List<MyTeam> _teams = (_mapContestTeamsUpdate[key] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      setState(() {
        _mapContestTeams = _teams;
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
          for (Contest _curContest in _l1Data.contests) {
            if (_curContest.id == _contest.id) {
              bFound = true;
            }
          }
          if (!bFound && _l1Data.league.id == _contest.leagueId) {
            _l1Data.contests.add(_contest);
          }
        }
      });
    }
    if (_data["lstModified"] != null && _data["lstModified"].length > 0) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in _l1Data.contests) {
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

  _onJoinContest(Contest contest) async {
    if (squadStatus()) {
      bShowJoinContest = false;
      ActionUtil().launchJoinContest(
        l1Data: _l1Data,
        contest: contest,
        myTeams: _myTeams,
        league: widget.league,
        scaffoldKey: _scaffoldKey,
      );
    }
  }

  void _onViewTeam(MyTeam _team) {
    if (_l1Data == null) {
      teamToView = _team;
      waitToLoadL1ForViewTeam = true;
    } else {
      teamToView = null;
      waitToLoadL1ForViewTeam = false;
      Navigator.of(context).push(
        FantasyPageRoute(
            pageBuilder: (context) => ViewTeam(
                  team: _team,
                  l1Data: _l1Data,
                  myTeam: _myTeams,
                  league: widget.league,
                  contest: widget.contest,
                ),
            fullscreenDialog: true),
      );
    }
  }

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;

    bWaitingForTeamCreation = true;

    if (AppConfig.of(context).channelId != "10") {
      Navigator.pop(context);
    }
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: _l1Data,
            ),
      ),
    );

    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
      if (curContest != null) {
        if (bWaitingForTeamCreation) {
          bShowJoinContest = true;
        } else {
          _onJoinContest(curContest);
        }
      }
    }
    bWaitingForTeamCreation = false;
  }

  _onJoinContestError(Contest contest, Map<String, dynamic> errorResponse) {
    JoinContestError error;
    if (errorResponse["error"] == true) {
      error = JoinContestError([errorResponse["resultCode"]]);
    } else {
      error = JoinContestError(errorResponse["reasons"]);
    }

    Navigator.of(context).pop();
    if (error.isBlockedUser()) {
      _showJoinContestError(
        title: error.getTitle(),
        message: error.getErrorMessage(),
      );
    } else {
      int errorCode = error.getErrorCode();
      switch (errorCode) {
        case 3:
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StateDob();
            },
          );
          break;
        case 12:
          _showAddCashConfirmation(contest);
          break;
        case 6:
          _showJoinContestError(
            message: strings.get("ALERT"),
            title: strings.get("NOT_VERIFIED"),
          );
          break;
      }
    }
  }

  _showJoinContestError({String title, String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                strings.get("OK").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }

  _showAddCashConfirmation(Contest contest) {
    final curContest = contest;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            strings.get("INSUFFICIENT_FUND").toUpperCase(),
          ),
          content: Text(
            strings.get("INSUFFICIENT_FUND_MSG"),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                strings.get("CANCEL").toUpperCase(),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchDepositJourneyForJoinContest(curContest);
              },
              child: Text(
                strings.get("DEPOSIT").toUpperCase(),
              ),
            )
          ],
        );
      },
    );
  }

  _launchDepositJourneyForJoinContest(Contest contest) async {
    final curContest = contest;
    showLoader(true);
    routeLauncher.launchAddCash(context, onSuccess: (result) {
      if (result != null) {
        _onJoinContest(curContest);
      }
    }, onComplete: () {
      showLoader(false);
    });
  }

  _shareContestDialog(BuildContext context) {
    String contestVisibility =
        widget.contest.visibilityId == 1 ? "PUBLIC" : "PRIVATE";
    String contestCode = widget.contest.contestJoinCode;
    String contestShareUrl = BaseUrl().contestShareUrl;
    String inviteMsg = AppConfig.of(context).channelId == "10"
        ? "Join my HOWZAT $contestVisibility League I've created a Contest for us to play. Use the contest code *$contestCode* in Howzat to join! \n $contestShareUrl"
        : AppConfig.of(context).appName.toUpperCase() +
            " - $contestVisibility LEAGUE \nHey! I created a Contest for our folks to play. Use this contest code *$contestCode* and join us. \n $contestShareUrl";

    FlutterShareMe().shareToSystem(msg: inviteMsg);
  }

  _getContestTeams(int offset, int limit) async {
    bIsAllTeamsRequestInProgress = true;
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl +
            ApiUtil.GET_CONTEST_TEAMS +
            widget.contest.id.toString() +
            "/teams/" +
            offset.toString() +
            "/" +
            limit.toString(),
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        bIsAllTeamsRequestInProgress = false;
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          List<dynamic> response = json.decode(res.body);
          List<MyTeam> _myTeams =
              response.map((i) => MyTeam.fromJson(i)).toList();
          curPage = offset == 0 ? 1 : (offset ~/ rowsPerPage) + 1;
          _mapContestTeams.forEach(
            (team) {
              _myTeams.forEach((myTeam) {
                if (team.id == myTeam.id) {
                  team.rank = myTeam.rank;
                  team.score = myTeam.score;
                  team.prize = myTeam.prize;
                }
              });
            },
          );

          return _myTeams;
        } else {
          return [];
        }
      },
    );
  }

  squadStatus() {
    if (_l1Data.league.rounds[0].matches[0].squad == 0) {
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

  void _showPrizeStructure(BuildContext context) async {
    List<dynamic> prizeStructure = await _getPrizeStructure(widget.contest);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PrizeStructure(
          contest: widget.contest,
          prizeStructure: prizeStructure,
        );
      },
    );
  }

  _getPrizeStructure(Contest contest) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(BaseUrl().apiUrl +
          ApiUtil.GET_PRIZESTRUCTURE +
          contest.id.toString() +
          "/prizestructure"),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          return json.decode(res.body);
        }
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    if (pollTimer != null) {
      pollTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("CONTEST_DETAILS").toUpperCase(),
        ),
        elevation: 0.0,
      ),
      body: NestedScrollView(
        controller: controller,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverPadding(
              padding: new EdgeInsets.all(0.0),
              sliver: new SliverList(
                delegate: new SliverChildListDelegate(
                  [
                    LeagueTitle(
                      league: widget.league,
                    ),
                    ContestDetailsCard(
                      league: widget.league,
                      contest: widget.contest,
                      contestTeams: _mapContestTeams,
                      onJoinContest: (Contest contest) {
                        _onJoinContest(contest);
                      },
                      onPrizeStructure: () {
                        _showPrizeStructure(context);
                      },
                      onShareContest: () {
                        _shareContestDialog(context);
                      },
                    ),
                    Container(
                      height: 40.0,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 1.0,
                            spreadRadius: 1.0,
                            offset: Offset(0, -2),
                            color: Colors.grey.shade300,
                          )
                        ],
                        color: Colors.grey.shade200,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.contest.joined.toString() +
                                  " Teams".toUpperCase(),
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .body1
                                  .copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          widget.league.status == LeagueStatus.COMPLETED
                              ? Container(
                                  width: 60.0,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "POINTS",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .body1
                                        .copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                )
                              : Container(),
                          Container(
                            width: 80.0,
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Rank".toUpperCase(),
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .body1
                                  .copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  int myTeamsCount = _mapContestTeams.length;
                  bool bIsMyTeam = index < _mapContestTeams.length;
                  MyTeam team = !bIsMyTeam
                      ? _allTeams[index - myTeamsCount]
                      : _mapContestTeams[index];
                  if (!bIsMyTeam && myTeamsId.indexOf(team.id) != -1) {
                    return Container();
                  }
                  return FlatButton(
                    padding: EdgeInsets.all(0.0),
                    onPressed: ((widget.league.status ==
                                    LeagueStatus.UPCOMING &&
                                bIsMyTeam) ||
                            (widget.league.status == LeagueStatus.LIVE ||
                                widget.league.status == LeagueStatus.COMPLETED))
                        ? () async {
                            MyTeam myTeam;
                            showLoader(true);
                            myTeam = await routeLauncher.getTeamPlayers(
                                contestId: widget.contest.id, teamId: team.id);
                            if (bIsMyTeam) {
                              _myTeams.forEach((curTeam) {
                                if (team.id == curTeam.id) {
                                  myTeam.players.forEach((Player player) {
                                    curTeam.players.forEach((Player curPlayer) {
                                      curPlayer.playingStyleId =
                                          player.playingStyleId;
                                      curPlayer.playingStyleDesc =
                                          player.playingStyleDesc;
                                    });
                                  });
                                }
                              });
                            }
                            showLoader(false);
                            Navigator.of(context).push(
                              FantasyPageRoute(
                                pageBuilder: (BuildContext context) =>
                                    TeamPreview(
                                      myTeam: myTeam,
                                      league: widget.league,
                                      l1Data: widget.l1Data,
                                      allowEditTeam: bIsMyTeam,
                                      fanTeamRules:
                                          widget.l1Data.league.fanTeamRules,
                                    ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      color: bIsMyTeam ? Colors.orange.shade50 : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black12,
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(8.0, 4.0, 16.0, 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      radius: 24.0,
                                      child: Image.asset(
                                        "images/person-icon.png",
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        team.name,
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .subhead
                                            .copyWith(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      widget.league.status ==
                                              LeagueStatus.COMPLETED
                                          ? Padding(
                                              padding:
                                                  EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                children: <Widget>[
                                                  Text(
                                                    bIsMyTeam
                                                        ? "YOU WON "
                                                        : "WON ",
                                                    style: Theme.of(context)
                                                        .primaryTextTheme
                                                        .subhead
                                                        .copyWith(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 2.0),
                                                    child: widget.contest
                                                                .prizeType ==
                                                            1
                                                        ? Image.asset(
                                                            strings.chips,
                                                            width: 12.0,
                                                            height: 12.0,
                                                            fit: BoxFit.contain,
                                                          )
                                                        : Container(),
                                                  ),
                                                  Text(
                                                    team.prize.toString(),
                                                    style: Theme.of(context)
                                                        .primaryTextTheme
                                                        .subhead
                                                        .copyWith(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  )
                                                ],
                                              ),
                                            )
                                          : Padding(
                                              padding:
                                                  EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                children: <Widget>[
                                                  Text(
                                                    team.score.toString(),
                                                    style: Theme.of(context)
                                                        .primaryTextTheme
                                                        .subhead
                                                        .copyWith(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  Text(
                                                    " Points",
                                                    style: Theme.of(context)
                                                        .primaryTextTheme
                                                        .body2
                                                        .copyWith(
                                                          color: Colors.black45,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            widget.league.status == LeagueStatus.COMPLETED
                                ? Container(
                                    width: 60.0,
                                    child: Text(
                                      team.score.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Container(),
                            Container(
                              alignment: Alignment.centerRight,
                              width: 80.0,
                              child: Text(
                                team.rank == null || team.rank == 0
                                    ? "-"
                                    : "#" + team.rank.toString(),
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                itemCount: _allTeams.length + _mapContestTeams.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
