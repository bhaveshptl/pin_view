import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/modal/createteamresponse.dart';
import 'package:playfantasy/leaguedetail/choosecaptain.dart';
import 'package:playfantasy/leaguedetail/playingstyletab.dart';

class TeamCreationMode {
  static const int CREATE_TEAM = 1;
  static const int EDIT_TEAM = 2;
  static const int CLONE_TEAM = 3;
}

class CreateTeam extends StatefulWidget {
  final int mode;
  final L1 l1Data;
  final League league;
  final MyTeam selectedTeam;

  CreateTeam({this.league, this.l1Data, this.mode, this.selectedTeam});

  @override
  State<StatefulWidget> createState() => CreateTeamState();
}

class CreateTeamState extends State<CreateTeam> {
  int _sportType = 1;
  double _usedCredits = 0.0;
  int _selectedPlayersCount = 0;
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  Player _captain;
  Player _vCaptain;
  String _avgCredits = "0";
  FanTeamRule _fanTeamRules;
  List<Player> _selectedPlayers = [];
  Map<String, dynamic> _playerCountByStyle = {};
  Map<int, List<Player>> _selectedPlayersByStyleId = {};

  @override
  void initState() {
    super.initState();
    _addPlayerTeamId();
    _getSportsType();

    _selectedPlayers =
        widget.selectedTeam != null ? widget.selectedTeam.players : [];

    _fanTeamRules = widget.l1Data.league.fanTeamRules;
    _avgCredits = (widget.l1Data.league.fanTeamRules.credits /
            widget.l1Data.league.fanTeamRules.playersTotal)
        .toStringAsFixed(2);

    if (widget.mode == TeamCreationMode.CLONE_TEAM ||
        widget.mode == TeamCreationMode.EDIT_TEAM) {
      _editOrCloneTeam();
    }
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        setState(() {
          _sportType = int.parse(value);
        });
      }
    });
  }

  _addPlayerTeamId() {
    List<Player> teamAPlayers =
        widget.l1Data.league.rounds[0].matches[0].teamA.players;
    List<Player> teamBPlayers =
        widget.l1Data.league.rounds[0].matches[0].teamB.players;

    for (Player player in teamAPlayers) {
      player.teamId = widget.l1Data.league.rounds[0].matches[0].teamA.id;
      player.jerseyUrl =
          widget.l1Data.league.rounds[0].matches[0].teamA.jerseyUrl;
      if (widget.mode == TeamCreationMode.EDIT_TEAM ||
          widget.mode == TeamCreationMode.CLONE_TEAM) {
        if (widget.selectedTeam.viceCaptain == player.id) {
          _vCaptain = player;
        } else if (widget.selectedTeam.captain == player.id) {
          _captain = player;
        }
      }
    }

    for (Player player in teamBPlayers) {
      player.teamId = widget.l1Data.league.rounds[0].matches[0].teamB.id;
      player.jerseyUrl =
          widget.l1Data.league.rounds[0].matches[0].teamB.jerseyUrl;
      if (widget.mode == TeamCreationMode.EDIT_TEAM ||
          widget.mode == TeamCreationMode.CLONE_TEAM) {
        if (widget.selectedTeam.viceCaptain == player.id) {
          _vCaptain = player;
        } else if (widget.selectedTeam.captain == player.id) {
          _captain = player;
        }
      }
    }
  }

  ///
  /// Iterate selected players and calculate player credits
  /// to edit or clone team.
  ///
  _editOrCloneTeam() {
    _seperatePlayersByPlayingStyle();
    calculatePlayerCredits(_selectedPlayers);
  }

  ///
  /// Iterate selected players and create map by [playingStyleId] -> List[players].
  ///
  _seperatePlayersByPlayingStyle() {
    _selectedPlayersByStyleId = {};
    for (Player player in _selectedPlayers) {
      if (_selectedPlayersByStyleId[player.playingStyleId] == null) {
        _selectedPlayersByStyleId[player.playingStyleId] = [];
      }
      _selectedPlayersByStyleId[player.playingStyleId].add(player);
    }
  }

  ///
  /// returns player index in selected player lisr.
  ///
  int _getPlayerIndex(Player player) {
    int selectedPlayerIndex = -1;
    int currentIndex = 0;
    for (Player selectedPlayer in _selectedPlayers) {
      if (player.id == selectedPlayer.id) {
        selectedPlayerIndex = currentIndex;
      }
      currentIndex++;
    }
    return selectedPlayerIndex;
  }

  ///
  /// Returns selected player count of give [style].
  ///
  _getSelectedPlayerCountForStyle(PlayingStyle style) {
    int _playerCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.playingStyleId == style.id) {
        _playerCount++;
      }
    }
    return _playerCount;
  }

  ///
  /// It will toggle player selection after validating player selection
  /// and re-calculate player credits.
  /// It will also re-create tabs which is currently active.
  ///
  void _selectPlayer(PlayingStyle style, Player player) {
    final _selectedPlayerIndex = _getPlayerIndex(player);

    setState(() {
      if (_selectedPlayerIndex == -1) {
        if (!_isValidPlayerSelection(style, player)) {
          return;
        }
        _selectedPlayers.add(player);
      } else {
        _selectedPlayers.removeAt(_selectedPlayerIndex);
      }

      _seperatePlayersByPlayingStyle();
      calculatePlayerCredits(_selectedPlayers);
    });
  }

  ///
  /// It will check if player to be selected is according to team selection
  /// or not. it will return true if its valid else false and show message
  /// accordingly.
  ///
  /// [style] Playing style object of [player] to validate.
  ///
  bool _isValidPlayerSelection(PlayingStyle style, Player player) {
    final int _stylePlayerCount = _getSelectedPlayerCountForStyle(style);

    if (_selectedPlayers.length >= _fanTeamRules.playersTotal) {
      _showErrorMessage(
        strings.get("PLAYER_SELECTION_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.playersTotal.toString(),
            ),
      );
      return false;
    }

    if ((_usedCredits + player.credit) > _fanTeamRules.credits) {
      _showErrorMessage(
        strings.get("PLAYER_CREDITS_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.credits.toString(),
            ),
      );
      return false;
    }

    if (_stylePlayerCount >= style.rule[1]) {
      _showErrorMessage(
        strings
            .get("PLAYER_STYLE_LIMIT")
            .replaceAll(
              "\$limit",
              style.rule[1].toString(),
            )
            .replaceAll("\$label", style.label),
      );
      return false;
    }

    if (player.countryId !=
            widget.l1Data.league.rounds[0].matches[0].series.countryId &&
        _getForeignPlayerCount() >= _fanTeamRules.playersForeign) {
      _showErrorMessage(
        strings.get("PLAYER_CREDITS_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.playersForeign.toString(),
            ),
      );
      return false;
    }

    if (_getPlayerCountPerTeam(player.teamId) >= _fanTeamRules.playersPerTeam) {
      _showErrorMessage(
        strings.get("SINGLE_TEAM_PLAYER_LIMIT").replaceAll(
              "\$limit",
              _fanTeamRules.playersPerTeam.toString(),
            ),
      );
      return false;
    }

    for (PlayingStyle style in _fanTeamRules.styles) {
      int playerCountForStyle = _selectedPlayersByStyleId[style.id] == null
          ? 0
          : _selectedPlayersByStyleId[style.id].length;
      if ((_fanTeamRules.playersTotal - (_selectedPlayersCount + 1) <
              style.rule[0] - playerCountForStyle) &&
          player.playingStyleId != style.id) {
        _showErrorMessage(
          strings
              .get("PLAYER_STYLE_MIN_LIMIT")
              .replaceAll(
                "\$limit",
                style.rule[0].toString(),
              )
              .replaceAll("\$label", style.label),
        );
        return false;
      }
    }

    return true;
  }

  ///
  /// It will return selected players count for team
  /// with given [teamId].
  ///
  _getPlayerCountPerTeam(int teamId) {
    int _playersPerTeamCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.teamId == teamId) {
        _playersPerTeamCount++;
      }
    }
    return _playersPerTeamCount;
  }

  ///
  /// It will calculate selected team used credits, number of players selected,
  /// and average credits user can use for next playera selection.
  /// [selectedPlayers] is List of players selected for which calculations should
  /// done.
  ///
  void calculatePlayerCredits(List<Player> selectedPlayers) {
    double usedCredits = 0.0;
    _selectedPlayersCount = selectedPlayers.length;
    for (Player player in selectedPlayers) {
      usedCredits += player.credit;
      if (_playerCountByStyle[player.playingStyleId] == null) {
        _playerCountByStyle[player.playingStyleId.toString()] = 0;
      }
      _playerCountByStyle[player.playingStyleId.toString()]++;
    }
    _usedCredits = usedCredits;
    _avgCredits = _selectedPlayersCount != _fanTeamRules.playersTotal
        ? ((_fanTeamRules.credits - usedCredits) /
                (_fanTeamRules.playersTotal - _selectedPlayersCount))
            .toStringAsFixed(2)
        : "-";
  }

  ///
  /// Check for team validation based on team creation rules.
  /// Use this method when user click on choose captain/next.
  ///
  bool _isValidTeam() {
    if (_selectedPlayers.length != _fanTeamRules.playersTotal) {
      _showErrorMessage(
        strings.get("DREAM_TEAM_MSG").replaceAll(
              "\$count",
              (_fanTeamRules.playersTotal - _selectedPlayers.length).toString(),
            ),
      );
      return false;
    }
    if (!isPlayerStyleCriteriaMatch()) {
      return false;
    }
    if (_getForeignPlayerCount() > _fanTeamRules.playersForeign) {
      return false;
    }
    return true;
  }

  ///
  /// It will return foreign players count.
  ///
  _getForeignPlayerCount() {
    int _foreignPlayerCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.countryId !=
          widget.l1Data.league.rounds[0].matches[0].series.countryId) {
        _foreignPlayerCount++;
      }
    }
    return _foreignPlayerCount;
  }

  ///
  /// It will check if all playing style player selection is matched
  /// according to team creation rules or not.
  ///
  bool isPlayerStyleCriteriaMatch() {
    for (PlayingStyle style in _fanTeamRules.styles) {
      int playingStyleCount = _getSelectedPlayerCountForStyle(style);
      if (!(playingStyleCount >= style.rule[0] &&
          playingStyleCount <= style.rule[1])) {
        if (playingStyleCount < style.rule[0]) {
          _showErrorMessage(
            strings
                .get("STYLE_MIN_COUNT")
                .replaceAll(
                  "\$count",
                  style.rule[0].toString(),
                )
                .replaceAll(
                  "\$style",
                  style.label.toLowerCase(),
                ),
          );
        } else if (playingStyleCount > style.rule[1]) {
          _showErrorMessage(
            strings
                .get("STYLE_MAX_COUNT")
                .replaceAll(
                  "\$count",
                  style.rule[1].toString(),
                )
                .replaceAll(
                  "\$style",
                  style.label.toLowerCase(),
                ),
          );
        }
        return false;
      }
    }
    return true;
  }

  ///
  /// It will show bottom panel popup for captain
  /// and vice captain selection.
  ///
  void _showChooseCaptain() {
    _scaffoldKey.currentState.showBottomSheet((context) {
      return Container(
        decoration: new BoxDecoration(
          color: Colors.white,
          boxShadow: [
            new BoxShadow(
              color: Colors.black,
              blurRadius: 20.0,
            ),
          ],
        ),
        height: 550.0,
        child: ChooseCaptain(
          fanTeamRules: _fanTeamRules,
          selectedPlayers: _selectedPlayers,
          onSave: _onSaveCaptains,
          captain: _captain,
          viceCaptain: _vCaptain,
        ),
      );
    });
  }

  ///
  /// Iterate playing style array get from team creation rules
  /// and create tabs for each playing style and returns tab
  /// object which includes tab icon and other UI.
  ///
  _createTabsBasedOnPlayingStyle() {
    final List<PlayingStyle> _playingStyles =
        _fanTeamRules != null ? _fanTeamRules.styles : [];
    List<Widget> tabs = [];
    for (PlayingStyle style in _playingStyles) {
      tabs.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          child: Tab(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                height: 24.0,
                                width: 24.0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        ('images/' +
                                                style.label +
                                                " " +
                                                _sportType.toString() +
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(top: 6.0),
                                child: Text(
                                  strings.get("PICK") +
                                      " " +
                                      (style.rule.length > 0 &&
                                              style.rule[0] == style.rule[1]
                                          ? style.rule[0].toString()
                                          : style.rule[0].toString() +
                                              "-" +
                                              style.rule[1].toString()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              CircleAvatar(
                                maxRadius: 8.0,
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                                child:
                                    _selectedPlayersByStyleId[style.id] == null
                                        ? Text(
                                            0.toString(),
                                            style: TextStyle(
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .caption
                                                    .fontSize),
                                          )
                                        : Text(
                                            _selectedPlayersByStyleId[style.id]
                                                .length
                                                .toString(),
                                            style: TextStyle(
                                                fontSize: Theme.of(context)
                                                    .primaryTextTheme
                                                    .caption
                                                    .fontSize),
                                          ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black12,
      child: TabBar(
        tabs: tabs,
        labelColor: Theme.of(context).primaryColorDark,
        unselectedLabelColor: Theme.of(context).primaryColorDark,
      ),
    );
  }

  _getTabsBodyBasedOnPlayingStyle() {
    List<PlayingStyleTab> tabsBody = [];
    for (PlayingStyle style in _fanTeamRules.styles) {
      tabsBody.add(
        PlayingStyleTab(
          style: style,
          l1Data: widget.l1Data,
          onPlayerSelect: _selectPlayer,
          selectedPlayers: _selectedPlayersByStyleId[style.id],
        ),
      );
    }
    return tabsBody;
  }

  ///
  /// It will show [message] in bottom sheet.
  ///
  void _showErrorMessage(String message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).accentColor, fontSize: 24.0),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title:
            Text(widget.league.teamA.name + " vs " + widget.league.teamB.name),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            strings.get("PLAYERS").toUpperCase(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Text(
                              _selectedPlayersCount.toString() +
                                  "/" +
                                  (widget.l1Data != null
                                      ? widget.l1Data.league.fanTeamRules
                                          .playersTotal
                                          .toString()
                                      : ""),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .fontSize),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            strings.get("CREDITS").toUpperCase(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Text(
                              _usedCredits.toString() +
                                  "/" +
                                  (widget.l1Data != null
                                      ? widget
                                          .l1Data.league.fanTeamRules.credits
                                          .toString()
                                      : ""),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .fontSize),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            strings.get("AVG_CREDITS"),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Text(
                              _avgCredits.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
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
          ),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Scaffold(
                body: TabBarView(
                  children: _getTabsBodyBasedOnPlayingStyle(),
                ),
                bottomNavigationBar: _createTabsBasedOnPlayingStyle(),
                floatingActionButton: FloatingActionButton(
                  tooltip: strings.get("CHOOSE_CAPTAIN"),
                  child: Icon(Icons.navigate_next),
                  onPressed: () {
                    if (_isValidTeam()) {
                      _showChooseCaptain();
                    }
                  },
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _getTeamToSave() {
    Map<String, dynamic> team = {
      "matchId": widget.league.matchId,
      "leagueId": widget.l1Data.league.id,
      "seriesId": widget.league.series.id,
      "captain": _captain == null ? -1 : _captain.id,
      "viceCaptain": _vCaptain == null ? -1 : _vCaptain.id,
      "players": _selectedPlayers,
      "name": "",
    };

    if (widget.l1Data.league.inningsId != null) {
      team["inningsId"] = widget.l1Data.league.inningsId;
    }

    if (widget.mode == TeamCreationMode.EDIT_TEAM) {
      team["fanTeamId"] = widget.selectedTeam.id;
      team["name"] = widget.selectedTeam.name;
    }

    return team;
  }

  void _onSaveCaptains(Player captain, Player viceCaptain) {
    Navigator.of(context).pop();

    _captain = captain;
    _vCaptain = viceCaptain;

    if (widget.mode == TeamCreationMode.EDIT_TEAM) {
      _updateTeam(_getTeamToSave());
    } else {
      createTeam(_getTeamToSave());
    }
  }

  void createTeam(Map<String, dynamic> team) async {
    String cookie;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    return new http.Client()
        .post(
      ApiUtil.CREATE_TEAM,
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
        "channelId": "3"
      },
      body: json.encoder.convert(team),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 300) {
        CreateTeamResponse response =
            CreateTeamResponse.fromJson(json.decode(res.body));
        Navigator.pop(context, response.message);
      } else {
        _showErrorMessage(
          strings.get("SAVE_TEAM_ERROR"),
        );
      }
    });
  }

  void _updateTeam(Map<String, dynamic> team) async {
    String cookie;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    return new http.Client()
        .put(
      ApiUtil.EDIT_TEAM + widget.selectedTeam.id.toString(),
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
        "channelId": "3"
      },
      body: json.encoder.convert(team),
    )
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 300) {
        Map<String, dynamic> response = json.decode(res.body);
        Navigator.of(context).pop(response["message"]);
      } else {
        _showErrorMessage(
          strings.get("UPDATE_TEAM_ERROR"),
        );
      }
    });
  }
}
