import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/leaguecard.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';

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
  int _selectedItemIndex = -1;
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

  void _onEditTeam(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              selectedTeam: widget.myTeams[_selectedItemIndex],
              mode: TeamCreationMode.EDIT_TEAM,
            ),
      ),
    );

    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  void _onCloneTeam(BuildContext context) async {
    final result = await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              selectedTeam: MyTeam.fromJson(
                json.decode(
                  json.encode(widget.myTeams[_selectedItemIndex]),
                ),
              ),
              mode: TeamCreationMode.CLONE_TEAM,
            ),
      ),
    );
    if (result != null) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result")));
    }
    setState(() {
      _selectedItemIndex = -1;
    });
  }

  Widget _getEmptyMyTeamsWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          strings.get("TEAMS_NOT_AVAILABLE"),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).errorColor,
              fontSize: Theme.of(context).primaryTextTheme.title.fontSize),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    OutlineButton(
                      onPressed: () {
                        _onCreateTeam(context);
                      },
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColorDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.add),
                          Text(
                            strings.get("CREATE_TEAM"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createMyTeamsWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 72.0),
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          if (index == _selectedItemIndex) {
                            _selectedItemIndex = -1;
                          } else {
                            _selectedItemIndex = index;
                          }
                        });
                      },
                      children: getExpansionPanel(context),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<ExpansionPanel> getExpansionPanel(BuildContext context) {
    int index = 0;
    List<ExpansionPanel> items = [];
    for (MyTeam myTeam in widget.myTeams) {
      items.add(
        ExpansionPanel(
          isExpanded: index == _selectedItemIndex,
          headerBuilder: (context, isExpanded) {
            return FlatButton(
              onPressed: () {
                setState(() {
                  int curIndex = widget.myTeams.indexOf(myTeam);
                  if (curIndex == _selectedItemIndex) {
                    _selectedItemIndex = -1;
                  } else {
                    _selectedItemIndex = curIndex;
                  }
                });
              },
              child: Row(
                children: <Widget>[
                  getExpansionHeader(context, isExpanded, myTeam),
                ],
              ),
            );
          },
          body: _getExpansionBody(myTeam),
        ),
      );
      index++;
    }

    return items;
  }

  Player getPlayer(int playerId, MyTeam myTeam) {
    for (Player player in myTeam.players) {
      if (player.id == playerId) {
        return player;
      }
    }
    return null;
  }

  Widget getExpansionHeader(
      BuildContext context, bool isExpanded, MyTeam myTeam) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 24.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(myTeam.name),
                isExpanded
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          IconButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              _onEditTeam(context);
                            },
                            icon: Column(
                              children: <Widget>[
                                Icon(Icons.edit),
                                Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "EDIT",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              _onCloneTeam(context);
                            },
                            icon: Column(
                              children: <Widget>[
                                Icon(Icons.content_copy),
                                Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "CLONE",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    : Container(),
              ],
            )
          ],
        ),
      ),
    );
  }

  _getPlayerStyle(Player player) {
    PlayingStyle _style;
    widget.l1Data.league.fanTeamRules.styles.forEach((PlayingStyle style) {
      if (player.playingStyleId == style.id ||
          player.playingStyleDesc.toLowerCase().replaceAll(" ", "") ==
              style.label.toLowerCase().replaceAll(" ", "")) {
        _style = style;
      }
    });
    return _style;
  }

  Widget _getExpansionBody(MyTeam myTeam) {
    List<ListTile> items = [];
    Player captain = getPlayer(myTeam.captain, myTeam);
    Player vCaptain = getPlayer(myTeam.viceCaptain, myTeam);

    for (Player player in myTeam.players) {
      final style = _getPlayerStyle(player);
      items.add(
        ListTile(
          leading: Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: player.jerseyUrl == null
                      ? Container()
                      : CircleAvatar(
                          backgroundColor: Colors.black12,
                          child: CachedNetworkImage(
                            imageUrl: player.jerseyUrl,
                            placeholder: Container(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              ),
                              width: TEAM_LOGO_HEIGHT,
                              height: TEAM_LOGO_HEIGHT,
                            ),
                            height: TEAM_LOGO_HEIGHT,
                          ),
                        ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(player.name),
                      captain == player
                          ? Text(widget.l1Data.league.fanTeamRules.captainMult
                                  .toString() +
                              "X")
                          : (vCaptain == player
                              ? Text(widget.l1Data.league.fanTeamRules.vcMult
                                      .toString() +
                                  "X")
                              : Container()),
                      style == null
                          ? Container()
                          : Container(
                              height: 18.0,
                              width: 18.0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      ('images/' +
                                              style.label +
                                              " " +
                                              player.sportsId.toString() +
                                              "-black"
                                              ".png")
                                          .toLowerCase()
                                          .replaceAll(" ", "-"),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    player.score.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Divider(height: 1.0),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        strings.get("PLAYERS").toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        strings.get("SCORE").toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: items,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          strings.get("MY_TEAMS"),
        ),
      ),
      body: Container(
        decoration: AppConfig.of(context).showBackground
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("images/norwegian_rose.png"),
                    repeat: ImageRepeat.repeat),
              )
            : null,
        child: Column(
          children: <Widget>[
            LeagueCard(
              widget.league,
              clickable: false,
            ),
            Divider(
              height: 2.0,
            ),
            Expanded(
              child: widget.myTeams.length > 0
                  ? _createMyTeamsWidget(context)
                  : _getEmptyMyTeamsWidget(context),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              _onCreateTeam(context);
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
