import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/tabs/statustab.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';

class LobbyWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LobbyWidgetState();
}

List<League> liveLeagues = [];
List<League> upcomingLeagues = [];
List<League> completedLeagues = [];
Map<String, dynamic> lobbyUpdatePackate = {};

class LobbyWidgetState extends State<LobbyWidget> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FantasyWebSocket().connect(url: ApiUtil.WEBSOCKET_URL, onWSMsg: _onWsMsg);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context).isCurrent) {
      FantasyWebSocket().register(_onWsMsg);
    }
  }

  _createLobbyObject() {
    lobbyUpdatePackate["iType"] = 1;
    lobbyUpdatePackate["sportsId"] = 1;
  }

  _createWSConnection() {
    FantasyWebSocket().connect(
        url: ApiUtil.WEBSOCKET_URL,
        onWSMsg: (onData) {
          _onWsMsg(onData);
        });
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      FantasyWebSocket().sendMessage(lobbyUpdatePackate);
    } else if (_response["iType"] == 1 && _response["bSuccessful"] == true) {
      List<League> _leagues = [];
      List<dynamic> _mapLeagues = json.decode(_response["data"]);

      for (dynamic league in _mapLeagues) {
        _leagues.add(League.fromJson(league));
      }

      _seperateLeaguesByRunningStatus(_leagues);
    }
  }

  @override
  void initState() {
    super.initState();
    _createLobbyObject();
    _createWSConnection();

    WidgetsBinding.instance.addObserver(this);
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
    return Scaffold(
      key: _scaffoldKey,
      body: DefaultTabController(
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
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
