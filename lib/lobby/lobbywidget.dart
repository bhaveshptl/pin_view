import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:playfantasy/lobby/tabs/statustab.dart';
import 'package:web_socket_channel/io.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class LobbyWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LobbyWidgetState();
}

List<League> liveLeagues = [];
List<League> upcomingLeagues = [];
List<League> completedLeagues = [];
Map<String, dynamic> lobbyUpdatePackate = {};

class LobbyWidgetState extends State<LobbyWidget> {
  IOWebSocketChannel _channel;

  setWebsocketCookie() async {
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getWSCookie();
    await futureCookie.then((value) {
      setState(() {
        if (value != null) {
          _channel = IOWebSocketChannel.connect(ApiUtil.WEBSOCKET_URL + value);
        }
      });
    });

    _setOnWsMsg();
  }

  _setOnWsMsg() {
    lobbyUpdatePackate["iType"] = 1;
    lobbyUpdatePackate["sportsId"] = 1;
    _channel.stream.listen((onData) {
      Map<String, dynamic> _response = json.decode(onData);

      if (_response["bReady"] == 1) {
        _channel.sink.add(json.encode(lobbyUpdatePackate));
      } else if (_response["iType"] == 1 && _response["bSuccessful"] == true) {
        List<League> _leagues = [];
        List<dynamic> _mapLeagues = json.decode(_response["data"]);

        for (dynamic league in _mapLeagues) {
          _leagues.add(League.fromJson(league));
        }

        _seperateLeaguesByRunningStatus(_leagues);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setWebsocketCookie();
  }

  _seperateLeaguesByRunningStatus(List<League> leagues) {
    List<League> _upcomingLeagues = [];
    List<League> _liveLeagues = [];
    List<League> _completedLeagues = [];
    for (League league in leagues) {
      switch (league.status) {
        case LeagueStatus.UPCOMING:
          _upcomingLeagues.add(league);
          break;
        case LeagueStatus.LIVE:
          _liveLeagues.add(league);
          break;
        case LeagueStatus.COMPLETED:
          _completedLeagues.add(league);
          break;
      }
    }
    setState(() {
      liveLeagues = _liveLeagues;
      upcomingLeagues = _upcomingLeagues;
      completedLeagues = _completedLeagues;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          new Container(
            constraints: BoxConstraints(maxHeight: 150.0),
            child: new Material(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                tabs: <Widget>[
                  Tooltip(
                    message: "Upcoming matches",
                    child: Tab(
                      text: "UPCOMING",
                    ),
                  ),
                  Tooltip(
                    message: "Live matches",
                    child: Tab(text: "LIVE"),
                  ),
                  Tooltip(
                    message: "Completed matches",
                    child: Tab(text: "RESULT"),
                  ),
                ],
              ),
            ),
          ),
          new Expanded(
            flex: 1,
            child: TabBarView(
              children: <Widget>[
                StatusTab(
                  leagues: upcomingLeagues,
                  leagueStatus: LeagueStatus.UPCOMING,
                ),
                StatusTab(
                  leagues: liveLeagues,
                  leagueStatus: LeagueStatus.LIVE,
                ),
                StatusTab(
                  leagues: completedLeagues,
                  leagueStatus: LeagueStatus.COMPLETED,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
