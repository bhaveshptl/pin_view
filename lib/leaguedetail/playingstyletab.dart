import 'package:flutter/material.dart';
import 'package:playfantasy/modal/l1.dart';

class PlayingStyleTab extends StatefulWidget {
  final L1 _l1Data;
  final int _styleIndex;
  final Function _onPlayerSelect;

  PlayingStyleTab(this._styleIndex, this._l1Data, this._onPlayerSelect);

  @override
  State<StatefulWidget> createState() => PlayingStyleTabState();
}

class PlayingStyleTabState extends State<PlayingStyleTab>
    with AutomaticKeepAliveClientMixin {
  PlayingStyle _style;
  List<Player> _selectedPlayers = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _style = widget._l1Data.league.fanTeamRules.styles[widget._styleIndex];
    });
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

  _doPlayerSelection(Player _player) {
    bool _bSuccess = widget._onPlayerSelect(widget._styleIndex, _player);
    if (_bSuccess) {
      int selectedPlayerIndex = _getPlayerIndex(_player);
      setState(() {
        if (selectedPlayerIndex == -1) {
          _selectedPlayers.add(_player);
        } else {
          _selectedPlayers.removeAt(selectedPlayerIndex);
        }
      });
    }
  }

  Widget _playerListView() {
    List<Player> teamAPlayers =
        widget._l1Data.league.rounds[0].matches[0].teamA.players;
    List<Player> teamBPlayers =
        widget._l1Data.league.rounds[0].matches[0].teamB.players;
    List<Player> tabPlayers = [];

    for (Player player in teamAPlayers) {
      if (player.playingStyleId == _style.id) {
        tabPlayers.add(player);
      }
    }
    for (Player player in teamBPlayers) {
      if (player.playingStyleId == _style.id) {
        tabPlayers.add(player);
      }
    }

    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Text(""),
                      ),
                      Expanded(
                        flex: 8,
                        child: Text(
                          "NAME",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "SERIES SCORE",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "CREDITS",
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
            child: ListView.builder(
              itemCount: tabPlayers.length,
              itemBuilder: (context, index) {
                final _player = tabPlayers[index];
                final _firstName = _player.name.split(" ")[0];
                final _lastName = _player.name.split(" ").length > 0
                    ? _player.name.split(" ")[1]
                    : "";
                final String _playerInitials =
                    (_firstName.length > 0 ? _firstName.substring(0, 1) : "")
                            .toUpperCase() +
                        (_lastName.length > 0 ? _lastName.substring(0, 1) : "")
                            .toUpperCase();

                return FlatButton(
                  onPressed: () {
                    _doPlayerSelection(_player);
                  },
                  color: _getPlayerIndex(_player) != -1
                      ? Colors.black12
                      : Colors.transparent,
                  padding: EdgeInsets.only(bottom: 8.0, top: 8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: CircleAvatar(
                          minRadius: 20.0,
                          child: Text(_playerInitials),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      Expanded(
                        flex: 8,
                        child: Text(_player.name),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _player.seriesScore.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _player.credit.toString(),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.blueGrey,
          child: Padding(
            padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "PICK " +
                      (_style != null && _style.rule.length > 0
                          ? (_style.rule[0] == _style.rule[1]
                              ? _style.rule[0].toString()
                              : _style.rule[0].toString() +
                                  "-" +
                                  _style.rule[1].toString())
                          : "") +
                      " " +
                      _style.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _playerListView(),
        )
      ],
    );
  }
}
