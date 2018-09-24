import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/tabs/statustab.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';

class LobbyWidget extends StatefulWidget {
  final int sportType;

  LobbyWidget({this.sportType = 1});

  @override
  State<StatefulWidget> createState() => LobbyWidgetState();
}

class LobbyWidgetState extends State<LobbyWidget> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int registeredSportType;
  List<League> liveLeagues = [];
  List<League> upcomingLeagues = [];
  List<League> completedLeagues = [];
  Map<String, dynamic> lobbyUpdatePackate = {};

  ///
  /// Reconnect websocket after resumed from lock screen or inactive state.
  ///
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sockets.sendMessage(lobbyUpdatePackate);
    }
  }

  ///
  /// Register ws message on pop next page of navigator.
  /// Workaround for now. Need to find better solution.
  ///
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context).isCurrent) {
      sockets.sendMessage(lobbyUpdatePackate);
    }
  }

  _createLobbyObject() {
    lobbyUpdatePackate["iType"] = 1;
    registeredSportType = widget.sportType;
    lobbyUpdatePackate["sportsId"] = widget.sportType;
  }

  _createWSConnection() {
    sockets.connect();
    sockets.register(_onWsMsg);
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      sockets.sendMessage(lobbyUpdatePackate);
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
    if (registeredSportType != widget.sportType) {
      _createLobbyObject();
      sockets.sendMessage(lobbyUpdatePackate);
    }
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
}
