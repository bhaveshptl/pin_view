import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/utils/stringtable.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class PlayingStyleTab extends StatelessWidget {
  final L1 l1Data;
  final Function onSort;
  final String sortedBy;
  final PlayingStyle style;
  final List<Player> allPlayers;
  final Function onPlayerSelect;
  final List<Player> selectedPlayers;

  PlayingStyleTab({
    this.style,
    this.l1Data,
    this.onSort,
    this.sortedBy,
    this.allPlayers,
    this.onPlayerSelect,
    this.selectedPlayers,
  });

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
    List<Player> tabPlayers = [];

    for (Player player in allPlayers) {
      if (player.playingStyleId == style.id) {
        tabPlayers.add(player);
      }
    }

    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 28.0,
                      ),
                    ),
                    Expanded(
                      flex: 9,
                      child: InkWell(
                        onTap: () {
                          if (onSort != null) {
                            onSort("NAME");
                          }
                        },
                        child: Container(
                          height: 28.0,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: <Widget>[
                              Text(
                                strings.get("NAME").toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: sortedBy == "NAME"
                                    ? Icon(
                                        Icons.sort,
                                        size: 16.0,
                                      )
                                    : Container(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () {
                          if (onSort != null) {
                            onSort("SCORE");
                          }
                        },
                        child: Container(
                          height: 28.0,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 50.0,
                                child: Text(
                                  strings.get("SERIES_SCORE"),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              sortedBy == "SCORE"
                                  ? Icon(
                                      Icons.sort,
                                      size: 16.0,
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () {
                          if (onSort != null) {
                            onSort("CREDITS");
                          }
                        },
                        child: Container(
                          height: 28.0,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  strings.get("CREDITS"),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              sortedBy == "CREDITS"
                                  ? Icon(
                                      Icons.sort,
                                      size: 16.0,
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                        flex: 4,
                        child: Text(
                          _player.seriesScore.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 4,
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
