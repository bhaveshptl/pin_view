import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/tabs/statustab.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';

class LobbyWidget extends StatefulWidget {
  final int sportType;
  final Function onLeagues;
  final Function showLoader;
  final Function onSportChange;

  LobbyWidget(
      {this.sportType = 1,
      this.showLoader,
      this.onLeagues,
      this.onSportChange});

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
      widget.showLoader(true);
    } else if (_response["iType"] == 1 && _response["bSuccessful"] == true) {
      List<League> _leagues = [];
      List<dynamic> _mapLeagues = json.decode(_response["data"]);

      for (dynamic league in _mapLeagues) {
        _leagues.add(League.fromJson(league));
      }

      if (widget.onLeagues != null) {
        widget.onLeagues(_leagues);
      }
      _seperateLeaguesByRunningStatus(_leagues);
      widget.showLoader(false);
    } else if (_response["iType"] == 2 && _response["bSuccessful"] == true) {
      if (_response["data"]["bDataModified"] == true &&
          (_response["data"]["lstAdded"] as List).length > 0) {
        List<League> _addedLeagues = (_response["data"]["lstAdded"] as List)
            .map((i) => League.fromJson(i))
            .toList();
        setState(() {
          for (League _league in _addedLeagues) {
            if (_league.status == LeagueStatus.UPCOMING) {
              upcomingLeagues.add(_league);
            } else if (_league.status == LeagueStatus.LIVE) {
              liveLeagues.add(_league);
            } else if (_league.status == LeagueStatus.COMPLETED) {
              completedLeagues.add(_league);
            }
          }
        });
      } else if (_response["data"]["bDataModified"] == true &&
          (_response["data"]["lstRemoved"] as List).length > 0) {
        List<League> _removedLeagues = (_response["data"]["lstRemoved"] as List)
            .map((i) => League.fromJson(i))
            .toList();
        setState(() {
          for (League _league in _removedLeagues) {
            if (_league.status == LeagueStatus.UPCOMING) {
              int index = getLeagueIndex(upcomingLeagues, _league);
              if (index != -1) {
                upcomingLeagues.removeAt(index);
              }
            } else if (_league.status == LeagueStatus.LIVE) {
              int index = getLeagueIndex(liveLeagues, _league);
              if (index != -1) {
                liveLeagues.removeAt(index);
              }
            } else if (_league.status == LeagueStatus.COMPLETED) {
              int index = getLeagueIndex(completedLeagues, _league);
              if (index != -1) {
                completedLeagues.removeAt(index);
              }
            }
          }
        });
      } else if (_response["data"]["bDataModified"] == true &&
          (_response["data"]["lstModified"] as List).length > 0) {
        List<League> _modifiedLeagues =
            (_response["data"]["lstModified"] as List)
                .map((i) => League.fromJson(i))
                .toList();

        List<League> _allLeagues = [];

        _allLeagues.addAll(liveLeagues);
        _allLeagues.addAll(upcomingLeagues);
        _allLeagues.addAll(completedLeagues);

        for (League _league in _modifiedLeagues) {
          int index = getLeagueIndex(_allLeagues, _league);
          if (index != -1) {
            _allLeagues[index] = _league;
            _seperateLeaguesByRunningStatus(_allLeagues);
          }
        }
      }
    }
  }

  int getLeagueIndex(List<League> _leagues, League _league) {
    int index = 0;
    for (League _curLeague in _leagues) {
      if (_curLeague.leagueId == _league.leagueId) {
        return index;
      }
      index++;
    }
    return -1;
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
                        text: strings.get("UPCOMING").toUpperCase(),
                      ),
                    ),
                    Tooltip(
                      message: "Live matches",
                      child: Tab(
                        text: strings.get("LIVE").toUpperCase(),
                      ),
                    ),
                    Tooltip(
                      message: "Completed matches",
                      child: Tab(
                        text: strings.get("RESULT").toUpperCase(),
                      ),
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
                    onSportChange: widget.onSportChange,
                    leagueStatus: LeagueStatus.UPCOMING,
                  ),
                  StatusTab(
                    leagues: liveLeagues,
                    onSportChange: widget.onSportChange,
                    leagueStatus: LeagueStatus.LIVE,
                  ),
                  StatusTab(
                    leagues: completedLeagues,
                    onSportChange: widget.onSportChange,
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
    sockets.reset();
    super.dispose();
  }
}
