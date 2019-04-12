import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class JoinContest extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final int sportsType;
  final Contest contest;
  final Function onError;
  final List<MyTeam> myTeams;
  final Function onCreateTeam;
  final Map<String, dynamic> createContestPayload;

  JoinContest({
    this.l1Data,
    this.league,
    this.contest,
    this.myTeams,
    this.onError,
    this.sportsType,
    this.onCreateTeam,
    this.createContestPayload,
  });

  @override
  State<StatefulWidget> createState() => JoinContestState();
}

class JoinContestState extends State<JoinContest> {
  MyTeam _teamToJoin;
  String cookie = "";
  List<MyTeam> _myTeams;
  List<MyTeam> _myUniqueTeams = [];
  List<dynamic> contestMyTeams = [];
  GlobalKey<ScaffoldState> scaffoldKey;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.contest != null) {
      getMyContestTeams();
    } else {
      setUniqueTeams([]);
    }
    _myTeams = widget.myTeams;
    scaffoldKey = GlobalKey<ScaffoldState>();
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.MY_TEAMS_ADDED &&
        data["bSuccessful"] == true) {
      MyTeam teamAdded = MyTeam.fromJson(data["data"]);
      bool bFound = false;
      for (MyTeam _myTeam in _myTeams) {
        if (_myTeam.id == teamAdded.id) {
          bFound = true;
        }
      }
      if (!bFound) {
        _myTeams.add(teamAdded);
      }
      setUniqueTeams(contestMyTeams);
    } else if (data["iType"] == RequestType.MY_TEAM_MODIFIED &&
        data["bSuccessful"] == true) {
      MyTeam teamUpdated = MyTeam.fromJson(data["data"]);
      int i = 0;
      for (MyTeam _team in _myTeams) {
        if (_team.id == teamUpdated.id) {
          _myTeams[i] = teamUpdated;
        }
        i++;
      }
      setUniqueTeams(contestMyTeams);
    }
  }

  _joinContest(BuildContext context) async {
    if (_teamToJoin == null) {
      widget.onCreateTeam(
        context,
        widget.contest,
      );
    } else {
      http.Request req = http.Request(
          "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.JOIN_CONTEST));
      req.body = json.encode({
        "teamId": _teamToJoin.id,
        "context": {"channel_id": HttpManager.channelId},
        "sportsId": widget.sportsType,
        "contestId": widget.contest.id,
        "leagueId": widget.contest.leagueId,
        "entryFee": widget.contest.entryFee,
        "prizeType": widget.contest.prizeType,
        "inningsId": widget.contest.inningsId,
        "realTeamId": widget.contest.realTeamId,
        "visibilityId": widget.contest.visibilityId,
        "bonusAllowed": widget.contest.bonusAllowed,
        "contestCode": widget.contest.contestJoinCode,
        "matchId": widget.l1Data.league.rounds[0].matches[0].id,
      });
      await HttpManager(http.Client()).sendRequest(req).then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"] == false) {
              Navigator.of(context).pop(response["message"]);
            } else if (response["error"] == true) {
              Navigator.of(context).pop(response["message"]);
            }
          } else if (res.statusCode == 401) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"]["reasons"].length > 0) {
              widget.onError(widget.contest, response["error"]);
            }
          }
        },
      );
    }
  }

  _createAndJoinContest(BuildContext context) async {
    if (_teamToJoin == null) {
      widget.onCreateTeam(context, widget.contest,
          createContestPayload: widget.createContestPayload);
    } else {
      Map<String, dynamic> payload = widget.createContestPayload;
      payload["fanTeamId"] = _teamToJoin;

      http.Request req = http.Request("POST",
          Uri.parse(BaseUrl().apiUrl + ApiUtil.CREATE_AND_JOIN_CONTEST));
      req.body = json.encode(payload);
      await HttpManager(http.Client()).sendRequest(req).then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"] == false) {
              Navigator.of(context).pop(res.body);
            } else if (response["error"] == true) {
              Navigator.of(context).pop(json.encode(response));
            }
          } else if (res.statusCode == 401) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"]["reasons"].length > 0) {
              widget.onError(widget.contest, response["error"]);
            }
          }
        },
      );
    }
  }

  setUniqueTeams(List<dynamic> contestMyTeams) {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in widget.myTeams) {
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
    if (myUniqueTeams.length > 0) {
      setState(() {
        _teamToJoin = myUniqueTeams[0];
        _myUniqueTeams = myUniqueTeams;
      });
    }
  }

  getMyContestTeams() async {
    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.GET_MY_CONTEST_MY_TEAMS));
    req.body = json.encode([widget.contest.id]);
    await HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response[widget.contest.id.toString()] != null) {
            contestMyTeams = (response[widget.contest.id.toString()] as List);
            setUniqueTeams(contestMyTeams);
          } else {
            setUniqueTeams([]);
          }
        }
      },
    );
  }

  void _onCreateTeam(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
            ),
      ),
    );

    if (result != null) {
      scaffoldKey.currentState.showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: scaffoldKey,
      appBar: AppBar(
        title: Text("MY TEAMS"),
        elevation: 0.0,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LeagueTitle(
            league: widget.league,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Choose team to join the contest".toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.body1.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _myUniqueTeams.map((MyTeam team) {
                  Player captain;
                  Player vCaptain;

                  team.players.forEach((Player player) {
                    if (team.captain == player.id) {
                      captain = player;
                    } else if (team.viceCaptain == player.id) {
                      vCaptain = player;
                    }
                  });

                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: FlatButton(
                              onPressed: () {
                                setState(() {
                                  _teamToJoin = team;
                                });
                              },
                              padding: EdgeInsets.all(0.0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    height: 40.0,
                                    color: Colors.grey.shade100,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: (_teamToJoin ==
                                                                null ||
                                                            _teamToJoin.id !=
                                                                team.id)
                                                        ? Colors.black
                                                        : Colors.green,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(2.0),
                                                child: (_teamToJoin == null ||
                                                        _teamToJoin.id !=
                                                            team.id)
                                                    ? CircleAvatar(
                                                        radius: 6.0,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      )
                                                    : CircleAvatar(
                                                        radius: 6.0,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: CircleAvatar(
                                                          radius: 6.0,
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Text(
                                              team.name,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          child: Container(
                                            height: 40.0,
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Preview",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .button
                                                  .copyWith(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                            ),
                                          ),
                                          onTap: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                width: 1.0,
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  "Captain",
                                                  style: Theme.of(context)
                                                      .primaryTextTheme
                                                      .body1
                                                      .copyWith(
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    captain.name,
                                                    style: Theme.of(context)
                                                        .primaryTextTheme
                                                        .body1
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                width: 1.0,
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  "Vice Captain",
                                                  style: Theme.of(context)
                                                      .primaryTextTheme
                                                      .body1
                                                      .copyWith(
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 4.0),
                                                  child: Text(
                                                    vCaptain.name,
                                                    style: Theme.of(context)
                                                        .primaryTextTheme
                                                        .body1
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            height: 72.0,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  spreadRadius: 1.0,
                  blurRadius: 2.0,
                  color: Colors.grey.shade300,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 48.0,
                    padding: EdgeInsets.only(right: 8.0, left: 40.0),
                    child: ColorButton(
                      onPressed: () {
                        _onCreateTeam(context);
                      },
                      color: Colors.orange,
                      child: Text(
                        "Create Team".toUpperCase(),
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 48.0,
                    padding: EdgeInsets.only(left: 8.0, right: 40.0),
                    child: ColorButton(
                      onPressed: _teamToJoin == null
                          ? null
                          : () {
                              if (widget.contest != null) {
                                _joinContest(context);
                              } else if (widget.createContestPayload != null) {
                                _createAndJoinContest(context);
                              }
                            },
                      child: Text(
                        "Join now".toUpperCase(),
                        style:
                            Theme.of(context).primaryTextTheme.title.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
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