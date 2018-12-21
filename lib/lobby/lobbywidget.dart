import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/tabs/statustab.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';

class LobbyWidget extends StatefulWidget {
  final int sportType;
  final Function onLeagues;
  final Function onSportChange;

  LobbyWidget({
    this.sportType = 1,
    this.onLeagues,
    this.onSportChange,
  });

  @override
  State<StatefulWidget> createState() => LobbyWidgetState();
}

class LobbyWidgetState extends State<LobbyWidget> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool bShowLoader = true;
  int registeredSportType;
  List<League> _allLeagues;
  List<League> liveLeagues = [];
  List<League> upcomingLeagues = [];
  List<League> completedLeagues = [];
  Map<String, dynamic> lobbyUpdatePackate = {};

  @override
  void initState() {
    super.initState();
    _createLobbyObject();
    _createWSConnection();
    sockets.sendMessage(lobbyUpdatePackate);
  }

  _createLobbyObject() {
    lobbyUpdatePackate["iType"] = RequestType.GET_ALL_SERIES;
    registeredSportType = widget.sportType;
    lobbyUpdatePackate["sportsId"] = widget.sportType;
  }

  _createWSConnection() {
    sockets.register(_onWsMsg);
  }

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      sockets.sendMessage(lobbyUpdatePackate);
    } else if (_response["sportsId"] == widget.sportType) {
      if (_response["iType"] == RequestType.GET_ALL_SERIES &&
          _response["bSuccessful"] == true) {
        List<League> _leagues = [];
        List<dynamic> _mapLeagues = json.decode(_response["data"]);

        for (dynamic league in _mapLeagues) {
          _leagues.add(League.fromJson(league));
        }

        if (widget.onLeagues != null) {
          widget.onLeagues(_leagues);
        }
        _seperateLeaguesByRunningStatus(_leagues);
        setState(() {
          bShowLoader = false;
        });
      } else if (_response["iType"] == RequestType.LOBBY_REFRESH_DATA &&
          _response["bSuccessful"] == true) {
        if (_response["data"]["bDataModified"] == true &&
            (_response["data"]["lstAdded"] as List).length > 0) {
          List<League> _addedLeagues = (_response["data"]["lstAdded"] as List)
              .map((i) => League.fromJson(i))
              .toList();

          _allLeagues.addAll(_addedLeagues);
          if (widget.onLeagues != null) {
            widget.onLeagues(_allLeagues);
          }

          setState(() {
            _seperateLeaguesByRunningStatus(_allLeagues);
          });
        } else if (_response["data"]["bDataModified"] == true &&
            (_response["data"]["lstRemoved"] as List).length > 0) {
          List<League> _removedLeagues =
              (_response["data"]["lstRemoved"] as List)
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

          _allLeagues = [];

          _allLeagues.addAll(liveLeagues);
          _allLeagues.addAll(upcomingLeagues);
          _allLeagues.addAll(completedLeagues);

          for (League _league in _modifiedLeagues) {
            int index = getLeagueIndex(_allLeagues, _league);
            if (index != -1) {
              _allLeagues[index] = _league;
            }
          }
          _seperateLeaguesByRunningStatus(_allLeagues);
          if (widget.onLeagues != null) {
            widget.onLeagues(_allLeagues);
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
    _liveLeagues.sort((a, b) {
      return b.matchStartTime - a.matchStartTime;
    });

    _upcomingLeagues.sort((a, b) {
      return a.matchStartTime - b.matchStartTime;
    });

    _completedLeagues.sort((a, b) {
      return b.matchEndTime - a.matchEndTime;
    });

    setState(() {
      _allLeagues = leagues;
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
      backgroundColor: Colors.transparent,
      key: _scaffoldKey,
      body: Stack(
        children: <Widget>[
          bShowLoader
              ? Container(
                  color: Colors.black12.withAlpha(10),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              "Loading...",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .copyWith(
                                      color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "To me, cricket is a simple game.  Keep it simple and just go out and play - Shane Warne",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(
                                        color: Colors.black87,                                        
                                      ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: StatusTab(
                          allLeagues: _allLeagues,
                          sportType: widget.sportType,
                          statusLeagues: upcomingLeagues,
                          onSportChange: widget.onSportChange,
                          leagueStatus: LeagueStatus.UPCOMING,
                        ),
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
    super.dispose();
    sockets.unRegister(_onWsMsg);
  }
}
