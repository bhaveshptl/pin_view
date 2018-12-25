import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class ViewTeam extends StatefulWidget {
  final L1 l1Data;
  final MyTeam team;
  final League league;
  final Contest contest;
  final List<MyTeam> myTeam;

  ViewTeam({this.team, this.myTeam, this.contest, this.league, this.l1Data});

  @override
  _ViewTeamState createState() => _ViewTeamState();
}

class _ViewTeamState extends State<ViewTeam> {
  int _sportsType;
  FanTeamRule _fanTeamRules;
  MyTeam _myTeamWithPlayers = MyTeam.fromJson({});
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    sockets.register(_onWsMsg);
    _getTeamPlayers();

    _fanTeamRules = widget.l1Data.league.fanTeamRules;
    _sportsType = widget.l1Data.league.rounds[0].matches[0].sportType;
  }

  _getTeamPlayers() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl +
            ApiUtil.GET_TEAM_INFO +
            widget.contest.id.toString() +
            "/teams/" +
            widget.team.id.toString(),
      ),
    );
    HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> respose = json.decode(res.body);
        setState(() {
          _myTeamWithPlayers = MyTeam.fromJson(respose);
        });
      }
    });
  }

  getTeam() {
    MyTeam _team;
    widget.myTeam.forEach((MyTeam myTeam) {
      if (myTeam.id == _myTeamWithPlayers.id) {
        _team = myTeam;
      }
    });

    return _team;
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["iType"] == RequestType.MY_TEAM_MODIFIED &&
        _response["bSuccessful"] == true) {
      MyTeam teamUpdated = MyTeam.fromJson(_response["data"]);

      if (widget.team.id == teamUpdated.id) {
        setState(() {
          _myTeamWithPlayers = teamUpdated;
        });
      }
    }
  }

  squadStatus() {
    if (widget.l1Data.league.rounds[0].matches[0].squad == 0) {
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

  void _onEditTeam(BuildContext context) async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              selectedTeam: getTeam(),
              mode: TeamCreationMode.EDIT_TEAM,
            ),
      ),
    );

    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  void _onCloneTeam(BuildContext context) async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CreateTeam(
              league: widget.league,
              l1Data: widget.l1Data,
              selectedTeam: MyTeam.fromJson(
                json.decode(
                  json.encode(getTeam()),
                ),
              ),
              mode: TeamCreationMode.CLONE_TEAM,
            ),
      ),
    );
    if (result != null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("$result")));
    }
  }

  _getPlayerStyle(Player player) {
    PlayingStyle _style;
    _fanTeamRules.styles.forEach((PlayingStyle style) {
      if (player.playingStyleId == style.id ||
          player.playingStyleDesc.toLowerCase().replaceAll(" ", "") ==
              style.label.toLowerCase().replaceAll(" ", "")) {
        _style = style;
      }
    });
    return _style;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: <Widget>[
          widget.league.status == LeagueStatus.UPCOMING
              ? IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () {
                    _onCloneTeam(context);
                  },
                )
              : Container(),
          widget.league.status == LeagueStatus.UPCOMING
              ? IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _onEditTeam(context);
                  },
                )
              : Container(),
        ],
      ),
      body: Padding(
        padding: widget.league.status != LeagueStatus.UPCOMING
            ? EdgeInsets.only(bottom: 64.0)
            : EdgeInsets.only(),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Text(""),
                        ),
                        Expanded(
                          flex: 9,
                          child: Text(
                            "NAME",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Score",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _myTeamWithPlayers.players.length,
                      itemBuilder: (context, index) {
                        final _player = _myTeamWithPlayers.players[index];
                        final style = _getPlayerStyle(_player);

                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 3,
                                child: CircleAvatar(
                                  minRadius: 20.0,
                                  backgroundColor: Colors.black12,
                                  child: CachedNetworkImage(
                                    imageUrl: _player.jerseyUrl,
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
                                flex: 9,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(_player.name),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 8.0),
                                            child: _myTeamWithPlayers.captain ==
                                                    _player.id
                                                ? Text(
                                                    _fanTeamRules.captainMult
                                                            .toString() +
                                                        "X",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                : _myTeamWithPlayers
                                                            .viceCaptain ==
                                                        _player.id
                                                    ? Text(
                                                        _fanTeamRules.vcMult
                                                                .toString() +
                                                            "X",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      )
                                                    : Container(),
                                          ),
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
                                                                  _sportsType
                                                                      .toString() +
                                                                  "-black"
                                                                  ".png")
                                                              .toLowerCase()
                                                              .replaceAll(
                                                                  " ", "-"),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _player.score.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: widget.league.status == LeagueStatus.LIVE
          ? Container(
              height: 64.0,
              color: Theme.of(context).primaryColorDark,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "Rank",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Score",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _myTeamWithPlayers.rank.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _myTeamWithPlayers.score.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .fontSize),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : widget.league.status == LeagueStatus.COMPLETED
              ? Container(
                  height: 64.0,
                  color: Theme.of(context).primaryColorDark,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "WINNINGS - ",
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize),
                      ),
                      widget.contest.prizeType == 1
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Text(
                              strings.rupee,
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .title
                                      .fontSize),
                            ),
                      Text(
                        _myTeamWithPlayers.prize.toStringAsFixed(2),
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize),
                      )
                    ],
                  ),
                )
              : Container(
                  height: 0.0,
                ),
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }
}
