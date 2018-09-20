import 'package:flutter/material.dart';
import 'package:playfantasy/leaguedetail/choosecaptain.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/leaguedetail/playingstyletab.dart';

class CreateTeam extends StatefulWidget {
  final L1 _l1Data;
  final League _league;  

  CreateTeam(this._league, this._l1Data);

  @override
  State<StatefulWidget> createState() => CreateTeamState();
}

class CreateTeamState extends State<CreateTeam> {
  String _avgCredits = "0";
  FanTeamRule _fanTeamRules;
  double _usedCredits = 0.0;
  int _selectedPlayersCount = 0;
  List<Player> _selectedPlayers = [];
  Map<String, dynamic> _playerCountByStyle = {};
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fanTeamRules = widget._l1Data.league.fanTeamRules;
    _avgCredits = (widget._l1Data.league.fanTeamRules.credits /
            widget._l1Data.league.fanTeamRules.playersTotal)
        .toStringAsFixed(2);
  }

  _createTabsBasedOnPlayingStyle() {
    final List<PlayingStyle> _playingStyles =
        _fanTeamRules != null ? _fanTeamRules.styles : [];
    List<Widget> tabs = [];
    for (PlayingStyle style in _playingStyles) {
      tabs.add(
        Tab(
          icon: new Icon(Icons.home),
          text: "PICK " +
              (style.rule.length > 0 && style.rule[0] == style.rule[1]
                  ? style.rule[0].toString()
                  : style.rule[0].toString() + "-" + style.rule[1].toString()),
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

  int _getPlayerIndex(Player _player) {
    int selectedPlayerIndex = -1;
    int currentIndex = 0;
    for (Player player in _selectedPlayers) {
      if (_player.id == player.id) {
        selectedPlayerIndex = currentIndex;
      }
      currentIndex++;
    }
    return selectedPlayerIndex;
  }

  _getSelectedPlayerCountForStyle(int _styleIndex) {
    int _playerCount = 0;
    final PlayingStyle style = _fanTeamRules.styles[_styleIndex];
    for (Player player in _selectedPlayers) {
      if (player.playingStyleId == style.id) {
        _playerCount++;
      }
    }
    return _playerCount;
  }

  _getForeignPlayerCount() {
    int _foreignPlayerCount = 0;
    for (Player player in _selectedPlayers) {
      if (player.countryId !=
          widget._l1Data.league.rounds[0].matches[0].series.countryId) {
        _foreignPlayerCount++;
      }
    }
    return _foreignPlayerCount;
  }

  int _getPlayerTeamId(Player _player) {
    bool _bIsPlayerFound = false;
    List<Player> _teamAPlayers =
        widget._l1Data.league.rounds[0].matches[0].teamA.players;

    for (Player player in _teamAPlayers) {
      if (player.id == _player.id) {
        _bIsPlayerFound = true;
      }
    }

    return _bIsPlayerFound
        ? widget._l1Data.league.rounds[0].matches[0].teamA.id
        : widget._l1Data.league.rounds[0].matches[0].teamB.id;
  }

  _getPlayerCountPerTeam(int teamId) {
    int _playersPerTeamCount = 0;
    for (Player player in _selectedPlayers) {
      if (_getPlayerTeamId(player) != teamId) {
        _playersPerTeamCount++;
      }
    }
    return _playersPerTeamCount;
  }

  bool _isValidPlayerSelection(int _styleIndex, Player _player) {
    final PlayingStyle style = _fanTeamRules.styles[_styleIndex];
    final int _stylePlayerCount = _getSelectedPlayerCountForStyle(_styleIndex);

    if (_selectedPlayers.length >= _fanTeamRules.playersTotal) {
      _showErrorMessage("You can't choose more than " +
          _fanTeamRules.playersTotal.toString() +
          " players.");
      return false;
    }

    if ((_usedCredits + _player.credit) > _fanTeamRules.credits) {
      _showErrorMessage("You can't use more than " +
          _fanTeamRules.credits.toString() +
          " credits.");
      return false;
    }

    if (_stylePlayerCount >= style.rule[1]) {
      _showErrorMessage("You can't choose more than " +
          style.rule[1].toString() +
          " " +
          style.label +
          ".");
      return false;
    }

    if (_player.countryId !=
            widget._l1Data.league.rounds[0].matches[0].series.countryId &&
        _getForeignPlayerCount() >= _fanTeamRules.playersForeign) {
      _showErrorMessage("You can't choose more than " +
          _fanTeamRules.playersForeign.toString() +
          " foreign players.");
      return false;
    }

    if (_getPlayerCountPerTeam(_getPlayerTeamId(_player)) >=
        _fanTeamRules.playersPerTeam) {
      _showErrorMessage("You can't choose more than " +
          _fanTeamRules.playersPerTeam.toString() +
          " players from one team.");
      return false;
    }

    return true;
  }

  bool _selectPlayer(int _styleIndex, Player _player) {
    final _selectedPlayerIndex = _getPlayerIndex(_player);

    if (_selectedPlayerIndex == -1) {
      if (!_isValidPlayerSelection(_styleIndex, _player)) {
        return false;
      }

      _selectedPlayers.add(_player);
    } else {
      _selectedPlayers.removeAt(_selectedPlayerIndex);
    }

    setState(() {
      double usedCredits = 0.0;
      _selectedPlayersCount = _selectedPlayers.length;
      for (Player player in _selectedPlayers) {
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
    });

    return true;
  }

  void _showErrorMessage(String _message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).accentColor, fontSize: 24.0),
            ),
          ),
        );
      },
    );
  }

  bool isPlayerStyleCriteriaMatch() {
    int i = 0;
    for (PlayingStyle style in _fanTeamRules.styles) {
      int playingStyleCount = _getSelectedPlayerCountForStyle(i);
      if (!(playingStyleCount >= style.rule[0] &&
          playingStyleCount <= style.rule[1])) {
        if (playingStyleCount > style.rule[1]) {
          _showErrorMessage("Only " +
              style.rule[1].toString() +
              " " +
              style.label.toLowerCase() +
              " allowed.");
        } else if (playingStyleCount < style.rule[0]) {
          _showErrorMessage("Minimum " +
              style.rule[0].toString() +
              " " +
              style.label.toLowerCase() +
              " should be selected.");
        }
        return false;
      }
      i++;
    }
    return true;
  }

  bool _isValidTeam() {
    if (!isPlayerStyleCriteriaMatch()) {
      return false;
    }
    if (_getForeignPlayerCount() > _fanTeamRules.playersForeign) {
      return false;
    }
    if (_selectedPlayers.length != _fanTeamRules.playersTotal) {
      _showErrorMessage("Plese select " +
          (_fanTeamRules.playersTotal - _selectedPlayers.length).toString() +
          " more players to create your dream team.");
      return false;
    }
    return true;
  }

  void _onSaveCaptains(Player captain, Player viceCaptain) {
    Navigator.of(context).pop();
    //  TODO
    //  Add logic to save team and pop current page.
    Navigator.of(context).pop();
  }

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
        // color: Colors.blueGrey,
        height: 550.0,
        child: ChooseCaptain(_fanTeamRules, _selectedPlayers, _onSaveCaptains),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
            widget._league.teamA.name + " vs " + widget._league.teamB.name),
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
                            "PLAYERS",
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
                                  (widget._l1Data != null
                                      ? widget._l1Data.league.fanTeamRules
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
                            "CREDITS",
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
                                  (widget._l1Data != null
                                      ? widget
                                          ._l1Data.league.fanTeamRules.credits
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
                            "AVG. CREDITS",
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
                  children: [
                    PlayingStyleTab(0, widget._l1Data, _selectPlayer),
                    PlayingStyleTab(1, widget._l1Data, _selectPlayer),
                    PlayingStyleTab(2, widget._l1Data, _selectPlayer),
                    PlayingStyleTab(3, widget._l1Data, _selectPlayer),
                  ],
                ),
                bottomNavigationBar: _createTabsBasedOnPlayingStyle(),
                floatingActionButton: FloatingActionButton(
                  tooltip: "Choose captain",
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
}
