import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/createteam/sports.dart';
import 'package:playfantasy/createteam/createteam.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/createteam/teampreview.dart';
import 'package:playfantasy/commonwidgets/leaguetitle.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class MyTeams extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final List<MyTeam> myTeams;

  MyTeams({this.league, this.l1Data, this.myTeams});

  @override
  State<StatefulWidget> createState() => MyTeamsState();
}

class MyTeamsState extends State<MyTeams> {
  List<MyTeam> _myTeams;
  final double teamLogoHeight = 40.0;
  StreamSubscription _streamSubscription;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _myTeams = widget.myTeams;
    _streamSubscription =
        FantasyWebSocket().subscriber().stream.listen(_onWsMsg);
  }

  _onWsMsg(data) {
    if (data["iType"] == RequestType.MY_TEAM_MODIFIED &&
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
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  void _onEditTeam(BuildContext context, MyTeam team) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              selectedTeam: team,
              mode: TeamCreationMode.EDIT_TEAM,
            ),
      ),
    );

    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  void _onCloneTeam(BuildContext context, MyTeam team) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              selectedTeam: MyTeam.fromJson(
                json.decode(
                  json.encode(team),
                ),
              ),
              mode: TeamCreationMode.CLONE_TEAM,
            ),
      ),
    );
    if (result != null) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("$result"),
        ),
      );
    }
  }

  Player getPlayer(int playerId, MyTeam myTeam) {
    for (Player player in myTeam.players) {
      if (player.id == playerId) {
        return player;
      }
    }
    return null;
  }

  getPlayingStyleCountWidget(List<Player> players) {
    List<int> sortedStyle = [];
    List<Widget> styleCount = [];
    Map<int, List<Player>> mapTeams = {};
    players.forEach((player) {
      if (mapTeams[player.playingStyleId] == null) {
        mapTeams[player.playingStyleId] = [];
      }
      mapTeams[player.playingStyleId].add(player);
    });

    FanTeamRule rules = widget.l1Data.league.fanTeamRules;

    rules.styles.forEach((PlayingStyle style) {
      styleCount.add(
        Text(
          Sports.styles[style.id] +
              " : " +
              mapTeams[style.id].length.toString(),
          style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      );
    });

    sortedStyle.forEach((styleId) {});

    return styleCount;
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("MY_TEAMS").toUpperCase(),
        ),
        elevation: 0.0,
      ),
      body: Column(
        children: <Widget>[
          LeagueTitle(
            league: widget.league,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: widget.myTeams.map((MyTeam team) {
                  Player captain;
                  Player vCaptain;
                  int teamAPlayerCount = 0;
                  int teamBPlayerCount = 0;

                  team.players.forEach((Player player) {
                    if (player.id == team.captain) {
                      captain = player;
                    } else if (player.id == team.viceCaptain) {
                      vCaptain = player;
                    }

                    if (player.teamId == widget.league.teamA.id) {
                      teamAPlayerCount++;
                    } else {
                      teamBPlayerCount++;
                    }
                  });

                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: FlatButton(
                      padding: EdgeInsets.all(0.0),
                      onPressed: () {
                        Navigator.of(context).push(
                          FantasyPageRoute(
                            pageBuilder: (BuildContext context) => TeamPreview(
                                  myTeam: team,
                                  allowEditTeam: true,
                                  league: widget.league,
                                  l1Data: widget.l1Data,
                                  fanTeamRules:
                                      widget.l1Data.league.fanTeamRules,
                                ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          children: <Widget>[
                            Container(
                              color: Colors.grey.shade100,
                              height: 40.0,
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    team.name,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .subhead
                                        .copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.grey.shade800,
                                        ),
                                        onPressed: () {
                                          _onEditTeam(context, team);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.content_copy,
                                          color: Colors.grey.shade800,
                                        ),
                                        onPressed: () {
                                          _onCloneTeam(context, team);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 6.0, top: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.only(left: 16.0),
                                    height: 80.0,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              widget.league.teamA.name + " : ",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.grey.shade600,
                                                  ),
                                            ),
                                            Text(
                                              teamAPlayerCount.toString(),
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              widget.league.teamB.name + " : ",
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .subhead
                                                  .copyWith(
                                                    color: Colors.grey.shade600,
                                                  ),
                                            ),
                                            Text(
                                              teamBPlayerCount.toString(),
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    child: Row(
                                      children: <Widget>[
                                        Stack(
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(top: 6.0),
                                              child: Column(
                                                children: <Widget>[
                                                  CircleAvatar(
                                                    minRadius: 24.0,
                                                    backgroundColor:
                                                        Colors.black12,
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          captain.jerseyUrl,
                                                      placeholder: Container(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.0,
                                                        ),
                                                        width: teamLogoHeight,
                                                        height: teamLogoHeight,
                                                      ),
                                                      height: teamLogoHeight,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 4.0,
                                                      vertical: 4.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade800,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2.0),
                                                    ),
                                                    child: Text(
                                                      captain.name,
                                                      style: Theme.of(context)
                                                          .primaryTextTheme
                                                          .caption
                                                          .copyWith(
                                                            color: Colors.white,
                                                            fontSize: 10.0,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.orange,
                                              ),
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                "C",
                                                style: Theme.of(context)
                                                    .primaryTextTheme
                                                    .body2
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Stack(
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 6.0),
                                                child: Column(
                                                  children: <Widget>[
                                                    CircleAvatar(
                                                      minRadius: 24.0,
                                                      backgroundColor:
                                                          Colors.black12,
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            vCaptain.jerseyUrl,
                                                        placeholder: Container(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2.0,
                                                          ),
                                                          width: teamLogoHeight,
                                                          height:
                                                              teamLogoHeight,
                                                        ),
                                                        height: teamLogoHeight,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: 4.0,
                                                        vertical: 4.0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade800,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2.0),
                                                      ),
                                                      child: Text(
                                                        vCaptain.name,
                                                        style: Theme.of(context)
                                                            .primaryTextTheme
                                                            .caption
                                                            .copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors
                                                      .blueAccent.shade400,
                                                ),
                                                padding: EdgeInsets.all(4.0),
                                                child: Text(
                                                  "VC",
                                                  style: Theme.of(context)
                                                      .primaryTextTheme
                                                      .body2
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              color: Colors.grey.shade100,
                              height: 40.0,
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children:
                                    getPlayingStyleCountWidget(team.players),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 1.0,
                  spreadRadius: 2.0,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    height: 56.0,
                    width: MediaQuery.of(context).size.width / 2,
                    child: ColorButton(
                      color: Colors.orange,
                      child: Text(
                        "Create Team".toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      onPressed: () {
                        _onCreateTeam(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
