import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/modal/account.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/leaguedetail/contestcard.dart';
import 'package:playfantasy/contestdetail/contestdetail.dart';
import 'package:playfantasy/prizestructure/prizestructure.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class Contests extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final Function showLoader;
  final int sportsType;
  final List<MyTeam> myTeams;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Map<int, List<MyTeam>> mapContestTeams;
  final Function onContestTeamsUpdated;
  final Account accountDetails;

  Contests(
      {this.league,
      this.l1Data,
      this.myTeams,
      this.sportsType,
      this.showLoader,
      this.scaffoldKey,
      this.mapContestTeams,
      this.onContestTeamsUpdated,
      this.accountDetails});

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
  int contestsCountOfBrands = 1;
  int maxContestForEachBrand = 3;
  String showMoreContestBrandName = "";
  bool showMoreContestsButton = false;
  Map moreContestBrandsShowMap;
  Map sortedContestsListMap;

  @override
  void initState() {
    super.initState();
    sortedContestsListMap = new Map<String, List<Contest>>();
    _l1Data = widget.l1Data;
    _myTeams = widget.myTeams;
    setContestsByCategory(widget.l1Data.contests);
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  setContestsByCategory(List<Contest> contests) async {
    contests.sort(
      (Contest a, Contest b) {
        if ((a.brand["info"] as String) == (b.brand["info"] as String)) {
          if (a.brandPriority) {
            return -1;
          } else if (b.brandPriority) {
            return 1;
          } else {
            return (a.prizeDetails[0]["totalPrizeAmount"] ==
                    b.prizeDetails[0]["totalPrizeAmount"]
                ? ((a.entryFee - b.entryFee) * 100).toInt()
                : ((b.prizeDetails[0]["totalPrizeAmount"] -
                            a.prizeDetails[0]["totalPrizeAmount"]) *
                        100)
                    .toInt());
          }
        } else {
          return (a.brand["info"] as String)
              .compareTo(b.brand["info"] as String);
        }
      },
    );

    int loopIndex = 0;
    List<Contest> brandContests = [];
    List<Contest> sortedContests = [];
    int userBalance = 0;
    moreContestBrandsShowMap = new Map();
    if (widget.accountDetails != null) {
      userBalance = (widget.accountDetails.totalBalance * 100).toInt();
    }
    contests.forEach((Contest contest) {
      bool bShowBrandInfo = (loopIndex + 1 < contests.length)
          ? !((contests[loopIndex + 1]).brand["info"] ==
              contests[loopIndex].brand["info"])
          : true;

      if (bShowBrandInfo) {
        brandContests.add(contest);
        moreContestBrandsShowMap[contests[loopIndex].brand["info"]] = false;
        var brandContestsLength = brandContests.length;
        var entryFeeList = new List(brandContestsLength);
        int upperEntryFee = -1;
        int lowerEntryFee = -1;
        int lowerButOneEntryFee = -1;
        int upperNBDContestId = 0;
        int lowerNBDContestId = 0;
        int equalEntryFeeContestId = 0;
        int lowerButOneNBDContestId = 0;

        for (var i = 0; i < brandContestsLength; i++) {
          entryFeeList[i] = brandContests[i].entryFee;
          int entryFee = (brandContests[i].entryFee * 100).toInt();
          if (entryFee > userBalance &&
              (entryFee < upperEntryFee || upperEntryFee == -1)) {
            upperEntryFee = entryFee;
            upperNBDContestId = brandContests[i].id;
          }
          if (entryFee == userBalance) {
            equalEntryFeeContestId = brandContests[i].id;
          }
          if (entryFee < userBalance &&
              (entryFee > lowerEntryFee || lowerEntryFee == -1)) {
            lowerEntryFee = entryFee;
            lowerNBDContestId = brandContests[i].id;
          }
        }

        for (var i = 0; i < brandContestsLength; i++) {
          entryFeeList[i] = brandContests[i].entryFee;
          int entryFee = (brandContests[i].entryFee * 100).toInt();
          if ((entryFee < lowerEntryFee) &&
              (entryFee < userBalance) &&
              (entryFee > lowerButOneEntryFee || lowerButOneEntryFee == -1)) {
            lowerButOneEntryFee = entryFee;
            lowerButOneNBDContestId = brandContests[i].id;
          }
        }

        brandContests.sort(
          (Contest a, Contest b) {
            if ((a.brand["info"] as String) == (b.brand["info"] as String)) {
              if (a.brandPriority) {
                return -1;
              } else if (b.brandPriority) {
                return 1;
              } else if (a.id == upperNBDContestId && userBalance > 0) {
                return -1;
              } else if (b.id == upperNBDContestId && userBalance > 0) {
                return 1;
              } else if (a.id == equalEntryFeeContestId) {
                return -1;
              } else if (b.id == equalEntryFeeContestId) {
                return 1;
              } else if (a.id == lowerNBDContestId && userBalance > 0) {
                return -1;
              } else if (b.id == lowerNBDContestId && userBalance > 0) {
                return 1;
              } else if (a.id == lowerButOneNBDContestId && userBalance > 0) {
                return -1;
              } else if (b.id == lowerButOneNBDContestId && userBalance > 0) {
                return 1;
              } else {
                return (a.entryFee == b.entryFee
                    ? ((b.prizeDetails[0]["totalPrizeAmount"] -
                                a.prizeDetails[0]["totalPrizeAmount"]) *
                            100)
                        .toInt()
                    : ((a.entryFee - b.entryFee) * 100).toInt());
              }
            } else {
              return (a.brand["info"] as String)
                  .compareTo(b.brand["info"] as String);
            }
          },
        );
        brandContests[0].bisFirstContestOfBrand = true;
        brandContests[brandContests.length - 1].bisLastContestOfBrand = true;
        if (brandContests.length > maxContestForEachBrand) {
          brandContests[maxContestForEachBrand].showMore = true;
        }
        sortedContests.addAll(brandContests);
        brandContests = [];
      } else {
        brandContests.add(contest);
      }
      loopIndex++;
    });

    List<Contest> cashRecomendedContests = [];
    List<Contest> cashNonRecomendedContests = [];
    List<Contest> practiseContests = [];
    sortedContests.forEach((Contest contest) {
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
      // setState(() {
      //   setContestsByCategory(_l1Data.contests);
      // });
    }
    if (_data["lstRemoved"] != null && _data["lstRemoved"].length > 0) {
      List<Contest> _lstRemovedContests = (_data["lstRemoved"] as List)
          .map((i) => Contest.fromJson(i))
          .toList();
      List<Contest> updatedContests = [];
      for (Contest _contest in _l1Data.contests) {
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
      _l1Data.contests = updatedContests;
    }

    if (_data["lstModified"] != null && _data["lstModified"].length >= 1) {
      List<dynamic> _modifiedContests = _data["lstModified"];
      for (Map<String, dynamic> _changedContest in _modifiedContests) {
        for (Contest _contest in _l1Data.contests) {
          if (_contest.id == _changedContest["id"]) {
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
                _contest.visibilityInfo != _changedContest["visibilityInfo"]) {
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
          }
        }
      }
    }

    setState(() {
      setContestsByCategory(_l1Data.contests);
    });
  }

  _onContestClick(Contest contest, League league) async {
    final result = await Navigator.of(context).push(
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
    /* These methods are called to update unique teams*/
    await widget.onContestTeamsUpdated();
    await getMyContestTeams(contest);
    /* End of  unique teams update*/
  }

  squadStatus() {
    if (widget.l1Data.league.rounds[0].matches[0].squad == 0) {
      ActionUtil().showMsgOnTop(
          "Squad is not yet announced. Please try again later.", context);
      return false;
    }
    return true;
  }

  onJoinContest(Contest contest) async {
    if (squadStatus()) {
      List<dynamic> teams = await getMyContestTeams(contest);
      if (teams != null && teams.length > 0) {
        bShowJoinContest = false;
        ActionUtil().launchJoinContest(
            l1Data: _l1Data,
            contest: contest,
            sportsType: widget.sportsType,
            myTeams: _myTeams,
            league: widget.league,
            scaffoldKey: widget.scaffoldKey,
            launchPageSource: "l1");
      } else {
        var result = await Navigator.of(context).push(
          FantasyPageRoute(
            pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              mode: TeamCreationMode.CREATE_TEAM,
            ),
          ),
        );

        if (result != null) {
          bShowJoinContest = false;
          ActionUtil().launchJoinContest(
              l1Data: _l1Data,
              contest: contest,
              myTeams: _myTeams,
              sportsType: widget.sportsType,
              league: widget.league,
              scaffoldKey: widget.scaffoldKey,
              launchPageSource: "l1");
        }
      }
    }
  }

  getMyContestTeams(Contest contest) async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
    req.body = json.encode([contest.id]);
    return await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response[contest.id.toString()] != null) {
            List<dynamic> contestMyTeams =
                (response[contest.id.toString()] as List);
            return getUniqueTeams(contestMyTeams);
          } else {
            return widget.myTeams;
          }
        } else {
          return widget.myTeams;
        }
      },
    ).whenComplete(() {
      ActionUtil().showLoader(context, false);
    });
  }

  getUniqueTeams(List<dynamic> contestMyTeams) {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in _myTeams) {
      bool bIsTeamUsed = false;
      for (dynamic contestTeam in contestMyTeams) {
        if (team.id == contestTeam["id"]) {
          bIsTeamUsed = true;
          break;
        }
      }
      if (!bIsTeamUsed) {
        myUniqueTeams.add(team);
      }
    }
    return myUniqueTeams;
  }

  void _showPrizeStructure(Contest contest) async {
    widget.showLoader(true);
    List<dynamic> prizeStructure =
        await routeLauncher.getPrizeStructure(contest);
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

  // _getPrizeStructure(Contest contest) async {
  //   http.Request req = http.Request(
  //     "GET",
  //     Uri.parse(BaseUrl().apiUrl +
  //         ApiUtil.GET_PRIZESTRUCTURE +
  //         contest.id.toString() +
  //         "/prizestructure"),
  //   );
  //   return HttpManager(http.Client()).sendRequest(req).then(
  //     (http.Response res) {
  //       if (res.statusCode >= 200 && res.statusCode <= 299) {
  //         return json.decode(res.body);
  //       } else {
  //         return Future.value(null);
  //       }
  //     },
  //   );
  // }

  onStateDobUpdate(String msg) {
    ActionUtil().showMsgOnTop(msg, context);
    // widget.scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(msg)));
  }

  Container getContestCards(int index, bool bShowBrandInfo) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: 4.0, right: 16.0, left: 16.0),
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
      ),
    );
  }

  _buildMainContent() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            Column(
              children: getBrandContestsWidgetList(),
            )
          ]),
        )
      ],
    );
  }

  getBrandContestsWidgetList() {
    List<Widget> list = [];
    list.add(getContestsListWidget(_contests));
    return list;
  }

  getContestsListWidget(List<Contest> brandContestList) {
    return Container(
      child: ListView.builder(
        itemCount: brandContestList.length,
        padding: EdgeInsets.only(bottom: 16.0),
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          /*When bShowBrandInfo is true at some index, then new brand starts */
          bool bShowBrandInfo = index > 0
              ? !((brandContestList[index - 1]).brand["info"] ==
                  brandContestList[index].brand["info"])
              : true;
          if (brandContestList[index].bisFirstContestOfBrand) {
            showMoreContestsButton = false;
            contestsCountOfBrands = 1;
          } else {
            contestsCountOfBrands++;
          }
          if (brandContestList[index].showMore) {
            showMoreContestsButton = true;
          }
          return Column(
            children: <Widget>[
              !showMoreContestsButton
                  ? getContestCards(index, bShowBrandInfo)
                  : Container(),
              showMoreContestsButton &&
                      showMoreContestBrandName == _contests[index].brand["info"]
                  ? getContestCards(index, bShowBrandInfo)
                  : Container(),
              _contests[index].bisLastContestOfBrand && showMoreContestsButton
                  ? Container(
                      padding: EdgeInsets.only(right: 20),
                      width: MediaQuery.of(context).size.width,
                      child: InkWell(
                        child: Text(
                          showMoreContestBrandName !=
                                  _contests[index].brand["info"]
                              ? "View " +
                                  (contestsCountOfBrands -
                                          maxContestForEachBrand)
                                      .toString() +
                                  " more"
                              : "View Less ",
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                        onTap: () {
                          setState(() {
                            if (showMoreContestBrandName !=
                                _contests[index].brand["info"]) {
                              showMoreContestBrandName =
                                  _contests[index].brand["info"];
                            } else {
                              showMoreContestBrandName = " ";
                            }
                          });
                        },
                      ))
                  : Container()
            ],
          );
        },
      ),
    );
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
          : _buildMainContent(),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
