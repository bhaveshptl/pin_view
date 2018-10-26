import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';

import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/utils/stringtable.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class ViewTeam extends StatefulWidget {
  final League league;
  final MyTeam team;
  final Contest contest;

  ViewTeam({this.team, this.contest, this.league});

  @override
  _ViewTeamState createState() => _ViewTeamState();
}

class _ViewTeamState extends State<ViewTeam> {
  MyTeam _myTeamWithPlayers = MyTeam.fromJson({});

  _getTeamPlayers() async {
    String cookie;

    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    http.Client().get(
      ApiUtil.GET_TEAM_INFO +
          widget.contest.id.toString() +
          "/teams/" +
          widget.team.id.toString(),
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> respose = json.decode(res.body);
        setState(() {
          _myTeamWithPlayers = MyTeam.fromJson(respose);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getTeamPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
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
                                    _myTeamWithPlayers.captain == _player.id
                                        ? Text(
                                            "2X",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        : _myTeamWithPlayers.viceCaptain ==
                                                _player.id
                                            ? Text(
                                                "1.5X",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            : Container(),
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
                        "WINNINGS - " +
                            strings.rupee +
                            _myTeamWithPlayers.prize.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize),
                      ),
                    ],
                  ),
                )
              : Container(
                  height: 0.0,
                ),
    );
  }
}
