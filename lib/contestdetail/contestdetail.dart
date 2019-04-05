import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/contestdetail/viewteam.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/contestdetail/switchteam.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/prizestructure.dart';
import 'package:playfantasy/commonwidgets/gradientbutton.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

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
  int _curPageOffset = 0;

  bool bShowLoader = false;
  final int rowsPerPage = 25;
  TeamsDataSource _teamsDataSource;
  bool bDownloadTeamEnabled = false;
  List<MyTeam> _mapContestTeams = [];
  Map<String, dynamic> l1UpdatePackate = {};
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MyTeam teamToView;
  bool bShowJoinContest = false;
  bool bWaitingForTeamCreation = false;
  bool waitToLoadL1ForViewTeam = false;

  StreamSubscription _streamSubscription;

  Duration pollTime;

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
    _teamsDataSource = TeamsDataSource(widget.league, widget.contest,
        widget.myTeams, _onViewTeam, _onSwitchTeam);
    _teamsDataSource.setMyContestTeams(widget.contest, _mapContestTeams);
    _teamsDataSource.changeLeagueStatus(widget.league.status);
    _getContestTeams(0);
    _getInitData();
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

    if (widget.contest != null && widget.contest.realTeamId != null) {
      l1UpdatePackate["sportsId"] = _sportType;
      l1UpdatePackate["id"] = widget.contest.leagueId;
      l1UpdatePackate["teamId"] = widget.contest.realTeamId;
      l1UpdatePackate["inningsId"] = widget.contest.inningsId;
      l1UpdatePackate["iType"] = RequestType.REQ_L1_INNINGS_ALL_DATA;
    } else {
      l1UpdatePackate["iType"] = RequestType.GET_ALL_L1;
      l1UpdatePackate["bResAvail"] = true;
      l1UpdatePackate["withPrediction"] = true;
      l1UpdatePackate["sportsId"] = _sportType;
      l1UpdatePackate["id"] = widget.league.leagueId;
    }

    if (widget.myTeams == null || widget.l1Data == null) {
      _getL1Data();
    } else {
      _l1Data = widget.l1Data;
      _myTeams = widget.myTeams;
    }
  }

  _startPolling() {
    if (pollTime != null) {
      pollTimer = Timer(
        pollTime,
        () async {
          await _getContestMyTeams();
          await _getContestTeams(_curPageOffset);
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

        setState(() {
          _mapContestTeams = _mapContestMyTeams[widget.contest.id] == null
              ? []
              : _mapContestMyTeams[widget.contest.id];
          _teamsDataSource.updateMyContestTeam(
              widget.contest, _mapContestTeams);
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
        _teamsDataSource.updateMyAllTeams(_myTeams);
        _onViewTeam(teamToView);
      } else {
        setState(() {
          _l1Data = L1.fromJson(data["data"]["l1"]);
          _myTeams = (data["data"]["myteams"] as List)
              .map((i) => MyTeam.fromJson(i))
              .toList();
          _teamsDataSource.updateMyAllTeams(_myTeams);
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
        _teamsDataSource.updateMyAllTeams(_myTeams);
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
    setState(() {
      bShowLoader = bShow;
    });
  }

  _updateContestTeams(Map<String, dynamic> _data) {
    Map<String, dynamic> _mapContestTeamsUpdate = _data["teamsByContest"];
    _mapContestTeamsUpdate.forEach((String key, dynamic _contestTeams) {
      List<MyTeam> _teams = (_mapContestTeamsUpdate[key] as List)
          .map((i) => MyTeam.fromJson(i))
          .toList();
      setState(() {
        _mapContestTeams = _teams;
        _teamsDataSource.updateMyContestTeam(widget.contest, _mapContestTeams);
        if (_curPageOffset > (widget.contest.joined - rowsPerPage)) {
          _getContestTeams(_curPageOffset);
        }
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
      if (_myTeams != null && _myTeams.length > 0) {
        final result = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return JoinContest(
              sportsType: _sportType,
              contest: contest,
              myTeams: _myTeams,
              onCreateTeam: _onCreateTeam,
              l1Data: _l1Data,
              onError: _onJoinContestError,
            );
          },
        );

        if (result != null) {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text("$result")));
        }
      } else {
        if (AppConfig.of(context).channelId == "10") {
          _onCreateTeam(context, contest);
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(strings.get("ALERT").toUpperCase()),
                content: Text(
                  strings.get("CREATE_TEAM_WARNING"),
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
                      _onCreateTeam(context, contest);
                    },
                    child: Text(strings.get("CREATE").toUpperCase()),
                  )
                ],
              );
            },
          );
        }
      }
    }
  }

  void _onSwitchTeam(MyTeam _team, List<MyTeam> myUniqueTeams) async {
    if (myUniqueTeams.length > 0) {
      final String result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SwitchTeam(
            myTeams: _myTeams,
            oldTeam: _team,
            l1Data: _l1Data,
            contest: widget.contest,
            contestMyTeams: _mapContestTeams,
          );
        },
      );

      if (result != null) {
        Map<String, dynamic> res = json.decode(result);
        String message = res["msg"];
        if (!res["error"]) {
          updateTeams(res["oldTeam"], res["newTeam"]);
        }
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text("$message")));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(
            strings.get("SWITCH_TEAM_NOT_AVAIL"),
          ),
        ),
      );
    }
  }

  updateTeams(int oldTeam, int newTeam) {
    MyTeam teamToReplace;
    _myTeams.forEach((MyTeam team) {
      if (team.id == newTeam) {
        teamToReplace = team;
      }
    });
    for (int i = 0; i < _mapContestTeams.length; i++) {
      if (_mapContestTeams[i].id == oldTeam) {
        _mapContestTeams[i] = teamToReplace;
      }
    }

    _teamsDataSource.updateMyContestTeam(widget.contest, _mapContestTeams);
    _getContestTeams(_curPageOffset);
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

    Share.share(inviteMsg);
  }

  _getContestTeams(int offset) async {
    _curPageOffset = offset;
    int teamListOffset = offset;
    if (offset == 0) {
      _teamsDataSource.setTeams(offset, _mapContestTeams);
    } else {
      teamListOffset = offset - _mapContestTeams.length;
    }

    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl +
            ApiUtil.GET_CONTEST_TEAMS +
            widget.contest.id.toString() +
            "/teams/" +
            teamListOffset.toString() +
            "/" +
            (offset == 0
                ? (rowsPerPage + _mapContestTeams.length).toString()
                : rowsPerPage.toString()),
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          List<dynamic> response = json.decode(res.body);
          List<MyTeam> _myTeams = [];
          List<MyTeam> _teams =
              response.map((i) => MyTeam.fromJson(i)).toList();
          List<MyTeam> uniqueTeams = [];
          _teams.forEach((MyTeam team) {
            bool bTeamFound = false;
            _mapContestTeams.forEach((MyTeam myTeam) {
              if (team.id == myTeam.id) {
                bTeamFound = true;
              }
            });
            if (!bTeamFound) {
              uniqueTeams.add(team);
            } else {
              _myTeams.add(team);
            }
          });
          _mapContestTeams.forEach((team) {
            _myTeams.forEach((myTeam) {
              if (team.id == myTeam.id) {
                team.rank = myTeam.rank;
                team.score = myTeam.score;
                team.prize = myTeam.prize;
              }
            });
          });

          _teamsDataSource.updateMyContestTeam(
              widget.contest, _mapContestTeams);

          _teamsDataSource.setTeams(
              offset == 0 ? (offset + _mapContestTeams.length) : offset,
              uniqueTeams);
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

  // onDownload() async {
  //   final tasks = await FlutterDownloader.loadTasks();
  // }

  List<DataColumn> _getDataTableHeader() {
    double width = MediaQuery.of(context).size.width - 20.0;
    List<DataColumn> _header = [
      DataColumn(
        onSort: (int index, bool bIsAscending) {},
        label: Container(
          padding: EdgeInsets.only(right: 4.0),
          width: width - (TABLE_COLUMN_PADDING * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: Text(
                  strings.get("TEAMS"),
                ),
              ),
              widget.league.status == LeagueStatus.COMPLETED ||
                      widget.league.status == LeagueStatus.LIVE
                  ? Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 50.0,
                            child: Text(
                              strings.get("SCORE").toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50.0,
                            child: Text(
                              strings.get("RANK").toUpperCase(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          widget.league.status == LeagueStatus.COMPLETED
                              ? Container(
                                  width: 60.0,
                                  child: Text(
                                    strings.get("PRIZE").toUpperCase(),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    ];

    return _header;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool bIsContestFull = (_mapContestTeams != null &&
            widget.contest.teamsAllowed <= _mapContestTeams.length) ||
        widget.contest.size == widget.contest.joined ||
        widget.league.status == LeagueStatus.LIVE ||
        widget.league.status == LeagueStatus.COMPLETED;
    final formatCurrency =
        NumberFormat.currency(locale: "hi_IN", symbol: "", decimalDigits: 0);

    _teamsDataSource.setWidth(width);
    _teamsDataSource.setContext(context);

    return Stack(
      children: <Widget>[
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              strings.get("CONTEST_DETAILS"),
            ),
          ),
          body: Container(
            decoration: AppConfig.of(context).showBackground
                ? BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/background.png"),
                        repeat: ImageRepeat.repeat),
                  )
                : null,
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverPadding(
                    padding: new EdgeInsets.all(0.0),
                    sliver: new SliverList(
                      delegate: new SliverChildListDelegate(
                        [
                          Row(
                            children: <Widget>[
                              Expanded(
                                child:
                                    LeagueCard(widget.league, clickable: false),
                              ),
                            ],
                          ),
                          Divider(
                            height: 2.0,
                            color: Colors.black12,
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 8.0),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Container(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Row(
                                                    children: <Widget>[
                                                      Text(
                                                        "Prize pool",
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .caption
                                                              .fontSize,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: <Widget>[
                                                      widget.contest
                                                                  .prizeType ==
                                                              1
                                                          ? Image.asset(
                                                              strings.chips,
                                                              width: 12.0,
                                                              height: 12.0,
                                                              fit: BoxFit
                                                                  .contain,
                                                            )
                                                          : Text(
                                                              strings.rupee,
                                                              style: TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColorDark,
                                                                  fontSize: Theme.of(
                                                                          context)
                                                                      .primaryTextTheme
                                                                      .headline
                                                                      .fontSize),
                                                            ),
                                                      Text(
                                                        (widget.contest
                                                                    .prizeDetails !=
                                                                null
                                                            ? formatCurrency
                                                                .format(widget
                                                                        .contest
                                                                        .prizeDetails[0]
                                                                    [
                                                                    "totalPrizeAmount"])
                                                            : 0.toString()),
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColorDark,
                                                            fontSize: Theme.of(
                                                                    context)
                                                                .primaryTextTheme
                                                                .headline
                                                                .fontSize),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              child: Tooltip(
                                                message: strings
                                                    .get("NO_OF_WINNERS"),
                                                child: InkWell(
                                                  // padding: EdgeInsets.all(0.0),
                                                  onTap: () {
                                                    _showPrizeStructure(
                                                        context);
                                                  },
                                                  child: Column(
                                                    children: <Widget>[
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 16.0),
                                                            child: Text(
                                                              strings
                                                                  .get(
                                                                      "WINNERS")
                                                                  .toUpperCase(),
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black45,
                                                                fontSize: Theme.of(
                                                                        context)
                                                                    .primaryTextTheme
                                                                    .caption
                                                                    .fontSize,
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.chevron_right,
                                                            size: 16.0,
                                                            color:
                                                                Colors.black26,
                                                          )
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Text(widget.contest
                                                                      .prizeDetails ==
                                                                  null
                                                              ? 0.toString()
                                                              : widget
                                                                  .contest
                                                                  .prizeDetails[
                                                                          0][
                                                                      "noOfPrizes"]
                                                                  .toString())
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                AppConfig.of(context)
                                                            .channelId ==
                                                        "10"
                                                    ? Text("Entry")
                                                    : Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 4.0,
                                                                left: 16.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      right:
                                                                          4.0),
                                                              child: Text(
                                                                "Entry",
                                                                style: Theme.of(
                                                                        context)
                                                                    .primaryTextTheme
                                                                    .caption
                                                                    .copyWith(
                                                                      color: Colors
                                                                          .black87,
                                                                    ),
                                                              ),
                                                            ),
                                                            widget.contest
                                                                        .prizeType ==
                                                                    1
                                                                ? Padding(
                                                                    padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            2.0),
                                                                    child: Image
                                                                        .asset(
                                                                      strings
                                                                          .chips,
                                                                      width:
                                                                          10.0,
                                                                      height:
                                                                          10.0,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ))
                                                                : Text(
                                                                    strings
                                                                        .rupee,
                                                                    style: Theme.of(
                                                                            context)
                                                                        .primaryTextTheme
                                                                        .caption
                                                                        .copyWith(
                                                                          color:
                                                                              Colors.black87,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                  ),
                                                            Text(
                                                              widget.contest
                                                                  .entryFee
                                                                  .toString(),
                                                              style: Theme.of(
                                                                      context)
                                                                  .primaryTextTheme
                                                                  .caption
                                                                  .copyWith(
                                                                    color: Colors
                                                                        .black87,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                Container(
                                                  child: Tooltip(
                                                    message:
                                                        "Join contest with ₹" +
                                                            widget.contest
                                                                .entryFee
                                                                .toString() +
                                                            " entry fee.",
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 16.0),
                                                      child: AppConfig.of(
                                                                      context)
                                                                  .channelId ==
                                                              "10"
                                                          ? RaisedButton(
                                                              onPressed:
                                                                  (bIsContestFull ||
                                                                          _onJoinContest ==
                                                                              null)
                                                                      ? null
                                                                      : () {
                                                                          _onJoinContest(
                                                                              widget.contest);
                                                                        },
                                                              elevation: 0.0,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5.0),
                                                              ),
                                                              color:
                                                                  Colors.green,
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(0.0),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: <
                                                                    Widget>[
                                                                  _mapContestTeams !=
                                                                              null &&
                                                                          _mapContestTeams.length >
                                                                              0
                                                                      ? Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.white70,
                                                                          size: Theme.of(context)
                                                                              .primaryTextTheme
                                                                              .subhead
                                                                              .fontSize,
                                                                        )
                                                                      : Container(),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: <
                                                                        Widget>[
                                                                      Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: <
                                                                            Widget>[
                                                                          widget.contest.prizeType == 1
                                                                              ? Padding(
                                                                                  padding: EdgeInsets.symmetric(horizontal: 2.0),
                                                                                  child: Image.asset(
                                                                                    strings.chips,
                                                                                    width: 10.0,
                                                                                    height: 10.0,
                                                                                    fit: BoxFit.contain,
                                                                                  ))
                                                                              : Text(
                                                                                  strings.rupee,
                                                                                  style: Theme.of(context).primaryTextTheme.button.copyWith(
                                                                                        color: Colors.white70,
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                ),
                                                                          Text(
                                                                            formatCurrency.format(widget.contest.entryFee),
                                                                            style: Theme.of(context).primaryTextTheme.button.copyWith(
                                                                                  color: Colors.white70,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                          ),
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : GradientButton(
                                                              disabled:
                                                                  bIsContestFull,
                                                              button:
                                                                  RaisedButton(
                                                                onPressed: () {
                                                                  if (!bIsContestFull) {
                                                                    _onJoinContest(
                                                                        widget
                                                                            .contest);
                                                                  }
                                                                },
                                                                color: Colors
                                                                    .transparent,
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            0.0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: <
                                                                      Widget>[
                                                                    _mapContestTeams !=
                                                                                null &&
                                                                            _mapContestTeams.length >
                                                                                0
                                                                        ? Icon(
                                                                            Icons.add,
                                                                            color:
                                                                                Colors.white70,
                                                                            size:
                                                                                Theme.of(context).primaryTextTheme.subhead.fontSize,
                                                                          )
                                                                        : Container(),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: <
                                                                          Widget>[
                                                                        Text(
                                                                          "JOIN",
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.white70,
                                                                            fontSize:
                                                                                Theme.of(context).primaryTextTheme.subhead.fontSize,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: 5.0),
                                                      child: widget.contest
                                                                  .bonusAllowed >
                                                              0
                                                          ? Row(
                                                              children: <
                                                                  Widget>[
                                                                Tooltip(
                                                                  message: strings
                                                                      .get(
                                                                          "USE_BONUS")
                                                                      .replaceAll(
                                                                          "\$bonusPercent",
                                                                          widget
                                                                              .contest
                                                                              .bonusAllowed
                                                                              .toString()),
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            4.0),
                                                                    child:
                                                                        CircleAvatar(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green,
                                                                      maxRadius:
                                                                          10.0,
                                                                      child:
                                                                          Text(
                                                                        "B",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white70,
                                                                            fontSize: Theme.of(context).primaryTextTheme.caption.fontSize),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  strings.get("PERCENT_BONUS_ALLOWED").replaceAll(
                                                                      "\$percent",
                                                                      widget
                                                                          .contest
                                                                          .bonusAllowed
                                                                          .toString()),
                                                                  style: TextStyle(
                                                                      fontSize: Theme.of(
                                                                              context)
                                                                          .primaryTextTheme
                                                                          .caption
                                                                          .fontSize),
                                                                ),
                                                              ],
                                                            )
                                                          : Container(),
                                                    ),
                                                    Container(
                                                      child: widget.contest
                                                                  .teamsAllowed >
                                                              1
                                                          ? Row(
                                                              children: <
                                                                  Widget>[
                                                                Tooltip(
                                                                  message: strings
                                                                      .get(
                                                                          "PARTICIPATE_WITH")
                                                                      .replaceAll(
                                                                          "\$count",
                                                                          widget
                                                                              .contest
                                                                              .teamsAllowed
                                                                              .toString()),
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            4.0),
                                                                    child:
                                                                        CircleAvatar(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .indigo,
                                                                      maxRadius:
                                                                          10.0,
                                                                      child:
                                                                          Text(
                                                                        "M",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white70,
                                                                            fontSize: Theme.of(context).primaryTextTheme.caption.fontSize),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  strings.get("MAXIMUM_ENTRY").replaceAll(
                                                                      "\$count",
                                                                      widget
                                                                          .contest
                                                                          .teamsAllowed
                                                                          .toString()),
                                                                  style: TextStyle(
                                                                      fontSize: Theme.of(
                                                                              context)
                                                                          .primaryTextTheme
                                                                          .caption
                                                                          .fontSize),
                                                                )
                                                              ],
                                                            )
                                                          : Container(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                child: InkWell(
                                                  child: Column(
                                                    children: <Widget>[
                                                      Row(
                                                        children: <Widget>[
                                                          Icon(
                                                            Icons.share,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: <Widget>[
                                                          Text(
                                                            "Share"
                                                                .toUpperCase(),
                                                            style: Theme.of(
                                                                    context)
                                                                .primaryTextTheme
                                                                .button
                                                                .copyWith(
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    _shareContestDialog(
                                                        context);
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  widget.contest.joined
                                                          .toString() +
                                                      "/" +
                                                      widget.contest.size
                                                          .toString() +
                                                      " joined",
                                                  textAlign: TextAlign.right,
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.white,
                            padding: EdgeInsets.only(
                                right: 16.0, left: 16.0, bottom: 4.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: widget.contest.joined,
                                  child: ClipRRect(
                                    borderRadius: widget.contest.joined ==
                                            widget.contest.size
                                        ? BorderRadius.all(
                                            Radius.circular(15.0))
                                        : BorderRadius.only(
                                            topLeft: Radius.circular(15.0),
                                            bottomLeft: Radius.circular(15.0),
                                          ),
                                    child: Container(
                                      height: 3.0,
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: widget.contest.size -
                                      widget.contest.joined,
                                  child: ClipRRect(
                                    borderRadius: widget.contest.joined == 0
                                        ? BorderRadius.all(
                                            Radius.circular(15.0))
                                        : BorderRadius.only(
                                            topRight: Radius.circular(15.0),
                                            bottomRight: Radius.circular(15.0),
                                          ),
                                    child: Container(
                                      height: 3.0,
                                      color: Colors.black12.withAlpha(10),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Divider(
                            height: 2.0,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          widget.contest.joined == 0
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 64.0, 16.0, 64.0),
                                  child: Center(
                                    child: Text(
                                      strings.get("NO_JOINED"),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Theme.of(context).errorColor,
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .title
                                              .fontSize),
                                    ),
                                  ),
                                )
                              : PaginatedDataTable(
                                  header: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        strings.get("LEADERBOARD"),
                                      ),
                                      bDownloadTeamEnabled
                                          ? IconButton(
                                              icon: Icon(Icons.file_download),
                                              onPressed: () {
                                                // onDownload();
                                              },
                                            )
                                          : Container(),
                                    ],
                                  ),
                                  rowsPerPage:
                                      widget.contest.joined < rowsPerPage
                                          ? (widget.contest.joined == 0
                                              ? 1
                                              : widget.contest.joined)
                                          : rowsPerPage,
                                  onPageChanged: (int firstVisibleIndex) {
                                    if (firstVisibleIndex == 0) {
                                      _getContestMyTeams();
                                    }
                                    _getContestTeams(firstVisibleIndex);
                                  },
                                  columns: _getDataTableHeader(),
                                  source: _teamsDataSource,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bShowLoader ? Loader() : Container(),
      ],
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

  void _showPrizeStructure(BuildContext context) async {
    List<dynamic> prizeStructure = await _getPrizeStructure(widget.contest);
    showBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PrizeStructure(
          contest: widget.contest,
          prizeStructure: prizeStructure,
        );
      },
    );
  }
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

class TeamsDataSource extends DataTableSource {
  int size;
  double width;
  League league;
  Contest contest;
  int _leagueStatus;
  Function onViewTeam;
  BuildContext context;
  Function onSwitchTeam;
  List<MyTeam> _teams = [];
  List<MyTeam> myContestTeams;
  List<MyTeam> _myAllTeams = [];
  List<MyTeam> _myUniqueTeams = [];

  bool bShowSwitchTeam = false;

  TeamsDataSource(League _league, Contest _contest, List<MyTeam> myAllTeams,
      Function _onViewTeam, Function _onSwitchTeam) {
    league = _league;
    this.contest = _contest;
    onViewTeam = _onViewTeam;
    this.size = _contest.size;
    onSwitchTeam = _onSwitchTeam;
    this._myAllTeams = myAllTeams;
    _leagueStatus = _league.status;

    if (myAllTeams != null && myAllTeams.length > 0) {
      bShowSwitchTeam = true;
    }
  }

  setMyContestTeams(Contest contest, List<MyTeam> _myContestTeams) {
    this.size = contest.joined;
    myContestTeams = _myContestTeams;
    for (int i = 0; i < size; i++) {
      if (i < _myContestTeams.length) {
        _teams.add(_myContestTeams[i]);
      } else {
        _teams.add(MyTeam());
      }
    }

    setUniqueTeams();
  }

  updateMyContestTeam(Contest contest, List<MyTeam> _myContestTeams) {
    this.size = contest.joined;
    myContestTeams = _myContestTeams;

    for (int i = 0; i < myContestTeams.length; i++) {
      if (i >= _teams.length) {
        _teams.add(myContestTeams[i]);
      } else {
        _teams[i] = myContestTeams[i];
      }
    }

    setUniqueTeams();
    this.notifyListeners();
  }

  updateMyAllTeams(List<MyTeam> _teams) {
    _myAllTeams = _teams;

    setUniqueTeams();
    notifyListeners();

    bShowSwitchTeam = true;
  }

  changeLeagueStatus(int _status) {
    _leagueStatus = _status;
  }

  setUniqueTeams() {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in (_myAllTeams == null ? [] : _myAllTeams)) {
      bool bIsTeamUsed = false;
      for (MyTeam contestTeam in myContestTeams) {
        if (team.id == contestTeam.id) {
          bIsTeamUsed = true;
          break;
        }
      }
      if (!bIsTeamUsed) {
        myUniqueTeams.add(team);
      }
    }
    _myUniqueTeams = myUniqueTeams;
  }

  setContext(BuildContext context) {
    this.context = context;
  }

  setWidth(double width) {
    this.width = width;
  }

  setTeams(int offset, List<MyTeam> _teams) {
    int curIndex = 0;
    int length = offset + _teams.length;
    for (int i = offset; i < length; i++) {
      if (this._teams.length <= i) {
        this._teams.add(MyTeam());
      }
      this._teams[i] = _teams[curIndex];
      curIndex++;
    }
    this.notifyListeners();
  }

  void updateTeams(int oldTeam, int newTeam) {
    _teams.forEach((MyTeam team) {
      if (team.id == oldTeam) {}
    });
  }

  @override
  DataRow getRow(int index) {
    assert(index >= 0);
    if (index >= _teams.length) return null;
    final MyTeam _team = _teams[index];

    return DataRow.byIndex(
      index: index,
      cells: _getBody(_team, index < myContestTeams.length),
    );
  }

  List<DataCell> _getBody(MyTeam _team, bool bIsMyJoinedTeam) {
    List<DataCell> _header = [
      DataCell(
        Container(
          width: width - (TABLE_COLUMN_PADDING * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      _team.name == null
                          ? ""
                          : _team.name.length >= 15
                              ? _team.name.substring(0, 14) + "..."
                              : _team.name,
                    ),
                    bIsMyJoinedTeam
                        ? Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.people,
                              color: Colors.black26,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              _leagueStatus == LeagueStatus.UPCOMING
                  ? Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        bIsMyJoinedTeam && bShowSwitchTeam
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  width: 72.0,
                                  child: OutlineButton(
                                    padding: EdgeInsets.all(0.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                    color: Theme.of(context).primaryColorDark,
                                    onPressed: () {
                                      onSwitchTeam(_team, _myUniqueTeams);
                                    },
                                    child: Text(
                                      strings.get("SWITCH").toUpperCase(),
                                      style: TextStyle(fontSize: 10.0),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        bIsMyJoinedTeam
                            ? Icon(Icons.chevron_right)
                            : Container(),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Container(
                          width: 50.0,
                          child: Text(
                            _team.score != null ? _team.score.toString() : "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 50.0,
                          child: Text(
                            _team.score != null ? _team.rank.toString() : "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _leagueStatus == LeagueStatus.COMPLETED
                            ? Container(
                                width: 60.0,
                                child: Text(
                                  _team.score != null
                                      ? _team.prize.toString()
                                      : "-",
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(),
                        _team.score != null
                            ? Icon(Icons.chevron_right)
                            : Container(
                                width: 20.0,
                              )
                      ],
                    ),
            ],
          ),
        ),
        onTap: () {
          if (_team != null &&
              _team.id != null &&
              ((bIsMyJoinedTeam && _leagueStatus == LeagueStatus.UPCOMING) ||
                  _leagueStatus != LeagueStatus.UPCOMING)) {
            onViewTeam(_team);
          }
        },
      ),
    ];

    return _header;
  }

  @override
  int get rowCount => size;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
