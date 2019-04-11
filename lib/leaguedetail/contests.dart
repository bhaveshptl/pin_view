import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/joincontest/joincontestconfirmation.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/profilepages/statedob.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/joincontesterror.dart';
import 'package:playfantasy/joincontest/joincontest.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class Contests extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final Function showLoader;
  final List<MyTeam> myTeams;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<int, List<MyTeam>> mapContestTeams;

  Contests({
    this.league,
    this.l1Data,
    this.myTeams,
    this.showLoader,
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
  bool bShowJoinContest = false;
  bool bWaitingForTeamCreation = false;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _l1Data = widget.l1Data;
    _myTeams = widget.myTeams;
    setContestsByCategory(widget.l1Data.contests);
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  setContestsByCategory(List<Contest> contests) {
    contests.sort(
      (Contest a, Contest b) {
        if ((a.brand["info"] as String) == (b.brand["info"] as String)) {
          return (a.prizeDetails[0]["totalPrizeAmount"] ==
                  b.prizeDetails[0]["totalPrizeAmount"]
              ? ((a.entryFee - b.entryFee) * 100).toInt()
              : ((b.prizeDetails[0]["totalPrizeAmount"] -
                          a.prizeDetails[0]["totalPrizeAmount"]) *
                      100)
                  .toInt());
        } else {
          return (a.brand["info"] as String)
              .compareTo(b.brand["info"] as String);
        }
      },
    );

    List<Contest> cashRecomendedContests = [];
    List<Contest> cashNonRecomendedContests = [];
    List<Contest> practiseContests = [];
    contests.forEach((Contest contest) {
      if (contest.prizeType == 1) {
        practiseContests.add(contest);
      } else if (contest.recommended) {
        cashRecomendedContests.add(contest);
      } else {
        cashNonRecomendedContests.add(contest);
      }
    });

    _contests = [];
    _contests.addAll(cashRecomendedContests);
    _contests.addAll(cashNonRecomendedContests);
    _contests.addAll(practiseContests);
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.MY_TEAMS_ADDED &&
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
          onJoinContest(_curContest);
        }
        bWaitingForTeamCreation = false;
      });
    } else if (data["iType"] == RequestType.JOIN_COUNT_CHNAGE &&
        data["bSuccessful"] == true) {
      _updateJoinCount(data["data"]);
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
        if (_l1Data.contests.length > _removedContestIndexes[i]) {
          _l1Data.contests.removeAt(_removedContestIndexes[i]);
        }
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
      FantasyPageRoute(
        pageBuilder: (context) => ContestDetail(
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

  squadStatus() {
    if (widget.l1Data.league.rounds[0].matches[0].squad == 0) {
      widget.scaffoldKey.currentState.showSnackBar(
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

  onJoinContest(Contest contest) async {
    if (squadStatus()) {
      bShowJoinContest = false;
      ActionUtil().launchJoinContest(
        l1Data: _l1Data,
        contest: contest,
        myTeams: _myTeams,
        league: widget.league,
        scaffoldKey: widget.scaffoldKey,
      );
    }
  }

  void _showPrizeStructure(Contest contest) async {
    widget.showLoader(true);
    List<dynamic> prizeStructure = await _getPrizeStructure(contest);
    widget.showLoader(false);
    if (prizeStructure != null) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return PrizeStructure(
            contest: contest,
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
        } else {
          return Future.value(null);
        }
      },
    );
  }

  onStateDobUpdate(String msg) {
    widget.scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              padding: EdgeInsets.only(bottom: 16.0),
              itemBuilder: (context, index) {
                bool bShowBrandInfo = index > 0
                    ? !((_contests[index - 1]).brand["info"] ==
                        _contests[index].brand["info"])
                    : true;

                return Padding(
                  padding: EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
                  child: ContestCard(
                    radius: BorderRadius.circular(
                      5.0,
                    ),
                    l1Data: widget.l1Data,
                    league: widget.league,
                    onJoin: onJoinContest,
                    onClick: _onContestClick,
                    contest: _contests[index],
                    bShowBrandInfo: bShowBrandInfo,
                    onPrizeStructure: _showPrizeStructure,
                    myJoinedTeams: widget.mapContestTeams != null
                        ? widget.mapContestTeams[_contests[index].id]
                        : null,
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
