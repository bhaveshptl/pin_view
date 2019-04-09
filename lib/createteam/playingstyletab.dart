import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/stringtable.dart';

class PlayingStyleTab extends StatelessWidget {
  final L1 l1Data;
  final League league;
  final Function onSort;
  final String sortedBy;
  final PlayingStyle style;
  final List<Player> allPlayers;
  final Function onPlayerSelect;
  final List<Player> selectedPlayers;
  final Map<int, String> mapSportLabel;

  final double teamLogoHeight = 32.0;

  PlayingStyleTab({
    this.style,
    this.league,
    this.l1Data,
    this.onSort,
    this.sortedBy,
    this.allPlayers,
    this.mapSportLabel,
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
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withAlpha(30),
                        width: 1.0,
                      ),
                    ),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
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
                                  "Players".toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black54,
                                  ),
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
                                    "Points".toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black54,
                                    ),
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
                                    "Credits".toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black54,
                                    ),
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
                      Container(
                        width: 40.0,
                      ),
                    ],
                  ),
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

                bool bIsPlayerSelected = _getPlayerIndex(_player) != -1;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withAlpha(30),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: FlatButton(
                    onPressed: () {
                      _doPlayerSelection(_player);
                    },
                    color: bIsPlayerSelected
                        ? Theme.of(context).primaryColor.withAlpha(30)
                        : Colors.transparent,
                    padding:
                        EdgeInsets.only(bottom: 12.0, top: 12.0, right: 8.0),
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
                                width: teamLogoHeight,
                                height: teamLogoHeight,
                              ),
                              height: teamLogoHeight,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _player.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      _player.teamId == league.teamA.id
                                          ? league.teamA.name
                                          : league.teamB.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      " - " +
                                          mapSportLabel[_player.playingStyleId],
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                        ),
                        Container(
                          width: 40.0,
                          height: 32.0,
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.black.withAlpha(20),
                              ),
                            ),
                          ),
                          child: Image.asset(
                            bIsPlayerSelected
                                ? "images/remove-player.png"
                                : "images/add-player.png",
                            height: 32.0,
                          ),
                        ),
                      ],
                    ),
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
          color: Colors.black12,
          height: kToolbarHeight,
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
                style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _playerListView(),
        )
      ],
    );
  }
}
