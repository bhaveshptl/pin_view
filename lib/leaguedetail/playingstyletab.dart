import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/utils/stringtable.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class PlayingStyleTab extends StatelessWidget {
  final L1 l1Data;
  final PlayingStyle style;
  final Function onPlayerSelect;
  final List<Player> selectedPlayers;

  PlayingStyleTab(
      {this.style, this.l1Data, this.onPlayerSelect, this.selectedPlayers});

  int _getPlayerIndex(Player _player) {
    int selectedPlayerIndex = -1;
    int currentIndex = 0;
    if (selectedPlayers != null) {
      for (Player player in selectedPlayers) {
        if (_player.id == player.id) {
          selectedPlayerIndex = currentIndex;
        }
        currentIndex++;
      }
    }
    return selectedPlayerIndex;
  }

  _doPlayerSelection(Player _player) {
    onPlayerSelect(style, _player);
  }

  Widget _playerListView() {
    List<Player> teamAPlayers =
        l1Data.league.rounds[0].matches[0].teamA.players;
    List<Player> teamBPlayers =
        l1Data.league.rounds[0].matches[0].teamB.players;
    List<Player> tabPlayers = [];

    for (Player player in teamAPlayers) {
      if (player.playingStyleId == style.id) {
        tabPlayers.add(player);
      }
    }
    for (Player player in teamBPlayers) {
      if (player.playingStyleId == style.id) {
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
                        flex: 3,
                        child: Text(""),
                      ),
                      Expanded(
                        flex: 9,
                        child: Text(
                          strings.get("NAME").toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          strings.get("SERIES_SCORE"),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          strings.get("CREDITS").toUpperCase(),
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
              itemCount: tabPlayers.length + 1,
              itemBuilder: (context, index) {
                final _player =
                    index >= tabPlayers.length ? null : tabPlayers[index];
                if (_player == null) {
                  return Container(
                    height: 64.0,
                  );
                }
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
                        child: Text(_player.name),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _player.seriesScore.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
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

  _shouldShowSelectionWarning() {
    final int _selectedPlayerCount =
        selectedPlayers == null ? 0 : selectedPlayers.length;
    if (style.rule[0] == style.rule[1] &&
        _selectedPlayerCount == style.rule[0]) {
      return false;
    } else if (style.rule[0] != style.rule[1] &&
        _selectedPlayerCount >= style.rule[0] &&
        _selectedPlayerCount <= style.rule[1]) {
      return false;
    }
    return true;
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
                  strings.get("PICK").toUpperCase() +
                      " " +
                      (style != null && style.rule.length > 0
                          ? (style.rule[0] == style.rule[1]
                              ? style.rule[0].toString()
                              : style.rule[0].toString() +
                                  "-" +
                                  style.rule[1].toString())
                          : "") +
                      " " +
                      style.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
                _shouldShowSelectionWarning()
                    ? Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Icon(
                          Icons.warning,
                          color: Colors.white70,
                          size: Theme.of(context)
                              .primaryTextTheme
                              .caption
                              .fontSize,
                        ),
                      )
                    : Container(),
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
