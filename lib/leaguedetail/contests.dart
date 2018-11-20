import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/statedob.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/commonwidgets/joincontest.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/commonwidgets/prizestructure.dart';

class Contests extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final List<MyTeam> myTeams;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<int, List<MyTeam>> mapContestTeams;

  Contests({
    this.league,
    this.l1Data,
    this.myTeams,
    this.scaffoldKey,
    this.mapContestTeams,
  });

  @override
  State<StatefulWidget> createState() => ContestsState();
}

class ContestsState extends State<Contests> {
  L1 _l1Data;
  String cookie;
  List<MyTeam> _myTeams;
  List<Contest> _contests = [];

  Contest _curContest;
  bool bCashContestsAvailable;
  bool bShowJoinContest = false;
  bool bPractiseContestsAvailable;
  bool bWaitingForTeamCreation = false;

  @override
  void initState() {
    super.initState();
    _l1Data = widget.l1Data;
    _myTeams = widget.myTeams;
    setContestsByCategory(widget.l1Data.contests);
    sockets.register(_onWsMsg);
  }

  setContestsByCategory(List<Contest> contests) {
    List<Contest> sortedContests = [];
    List<Contest> normalContests = [];
    List<Contest> recommendedContests = [];
    try {
      contests.forEach((Contest contest) {
        if (contest.recommended) {
          recommendedContests.add(contest);
        } else {
          normalContests.add(contest);
        }
      });

      normalContests.sort((a, b) {
        return a.size == b.size ? a.entryFee - b.entryFee : a.size - b.size;
      });

      recommendedContests.sort((a, b) {
        return a.prizeDetails[0]["totalPrizeAmount"] ==
                b.prizeDetails[0]["totalPrizeAmount"]
            ? a.entryFee - b.entryFee
            : b.prizeDetails[0]["totalPrizeAmount"] -
                a.prizeDetails[0]["totalPrizeAmount"];
      });
      sortedContests.addAll(recommendedContests);
      sortedContests.addAll(normalContests);

      List<Contest> cashContests = [];
      List<Contest> practiseContests = [];
      sortedContests.forEach((Contest contest) {
        if (contest.prizeType == 1) {
          practiseContests.add(contest);
        } else {
          cashContests.add(contest);
        }
      });

      _contests = [];
      _contests.add(Contest());
      _contests.addAll(cashContests);
      _contests.add(Contest());
      _contests.addAll(practiseContests);

      bCashContestsAvailable = cashContests.length > 0;
      bPractiseContestsAvailable = practiseContests.length > 0;
    } on Exception {
      _contests = contests;
    }
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["iType"] == RequestType.MY_TEAMS_ADDED &&
        _response["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(_response["data"]);
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
          onJoinContest(_curContest);
        }
        bWaitingForTeamCreation = false;
      });
    } else if (_response["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        _response["bSuccessful"] == true) {
      _updateJoinCount(_response["data"]);
    } else if (_response["iType"] == RequestType.L1_DATA_REFRESHED &&
        _response["bSuccessful"] == true) {
      _applyL1DataUpdate(_response["diffData"]["ld"]);
    }
  }

  _updateJoinCount(Map<String, dynamic> _data) {
    for (Contest _contest in _contests) {
      if (_contest.id == _data["cId"]) {
        setState(() {
          _contest.joined = _data["iJC"];
        });
      }
    }
  }

  _applyL1DataUpdate(Map<String, dynamic> _data) {
    if (_data["lstAdded"] != null && _data["lstAdded"].length > 0) {
      List<Contest> _addedContests =
          (_data["lstAdded"] as List).map((i) => Contest.fromJson(i)).toList();
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
      setState(() {
        setContestsByCategory(_l1Data.contests);
      });
    }
    if (_data["lstRemoved"] != null && _data["lstRemoved"].length > 0) {
      List<int> _removedContestIndexes = [];
      List<Contest> _lstRemovedContests = (_data["lstRemoved"] as List)
          .map((i) => Contest.fromJson(i))
          .toList();
      for (Contest _removedContest in _lstRemovedContests) {
        int index = 0;
        for (Contest _contest in _l1Data.contests) {
          if (_removedContest.id == _contest.id) {
            _removedContestIndexes.add(index);
          }
          index++;
        }
      }
      for (int i = _removedContestIndexes.length - 1; i >= 0; i--) {
        _l1Data.contests.removeAt(_removedContestIndexes[i]);
      }
      setState(() {
        setContestsByCategory(_l1Data.contests);
      });
    }
    if (_data["lstModified"] != null && _data["lstModified"].length >= 1) {
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

  _onContestClick(Contest contest, League league) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContestDetail(
              contest: contest,
              league: league,
              l1Data: _l1Data,
              myTeams: _myTeams,
              mapContestTeams: widget.mapContestTeams != null
                  ? widget.mapContestTeams[contest.id]
                  : null,
            ),
      ),
    );
  }

  onJoinContest(Contest contest) async {
    bShowJoinContest = false;
    if (_myTeams.length > 0) {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return JoinContest(
            l1Data: _l1Data,
            contest: contest,
            myTeams: _myTeams,
            onCreateTeam: _onCreateTeam,
            onError: onJoinContestError,
          );
        },
      );

      if (result != null) {
        widget.scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text("$result")));
      }
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

  void _onCreateTeam(BuildContext context, Contest contest) async {
    final curContest = contest;

    bWaitingForTeamCreation = true;
    Navigator.of(context).pop();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: _l1Data,
            ),
      ),
    );

    if (result != null) {
      if (curContest != null) {
        if (bWaitingForTeamCreation) {
          _curContest = curContest;
          bShowJoinContest = true;
        } else {
          onJoinContest(curContest);
        }
      }
      widget.scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
      Navigator.of(context).pop();
    }
    bWaitingForTeamCreation = false;
  }

  void _showPrizeStructure(Contest contest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PrizeStructure(
          contest: contest,
        );
      },
    );
  }

  onStateDobUpdate(String msg) {
    widget.scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
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
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCash(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      onJoinContest(curContest);
    }
  }

  onJoinContestError(
      Contest contest, Map<String, dynamic> errorResponse) async {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: widget.l1Data.contests.length == 0
          ? Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  strings.get("CONTESTS_NOT_AVAILABLE"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).errorColor,
                    fontSize:
                        Theme.of(context).primaryTextTheme.headline.fontSize,
                  ),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _contests.length,
              itemBuilder: (context, index) {
                if (index == 0 || _contests[index].id == null) {
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              color: Colors.black12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    index == 0 ? "CASH" : "PRACTISE",
                                    style: TextStyle(
                                        color: Colors.black38,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .fontSize),
                                  ),
                                ],
                              ),
                            ),
                            (index == 0 && !bCashContestsAvailable) ||
                                    (index != 0 &&
                                        _contests[index].id == null &&
                                        !bPractiseContestsAvailable)
                                ? Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Contests not available",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: Theme.of(context)
                                              .primaryTextTheme
                                              .subhead
                                              .fontSize),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: ContestCard(
                      l1Data: widget.l1Data,
                      league: widget.league,
                      onJoin: onJoinContest,
                      onClick: _onContestClick,
                      contest: _contests[index],
                      onPrizeStructure: _showPrizeStructure,
                      myJoinedTeams: widget.mapContestTeams != null
                          ? widget.mapContestTeams[_contests[index].id]
                          : null,
                    ),
                  );
                }
              },
            ),
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }
}
