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
  final bool isAscending;
  final bool showSquadAnnouncedPlayersStatus;
  final PlayingStyle style;
  final List<Player> allPlayers;
  final Function onPlayerSelect;
  final List<Player> selectedPlayers;
  final Map<int, String> mapSportLabel;

  final double teamLogoHeight = 36.0;

  PlayingStyleTab(
      {this.style,
      this.league,
      this.l1Data,
      this.onSort,
      this.sortedBy,
      this.allPlayers,
      this.isAscending,
      this.mapSportLabel,
      this.onPlayerSelect,
      this.selectedPlayers,
      this.showSquadAnnouncedPlayersStatus});

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

  bool checkThePlayerPlayingStatus(int playerId) {
    /*To check if the player is playing in the Squad*/
    print(playerId);
    List<int> initialSquadList = l1Data.initialSquad;
   
    
    return initialSquadList.contains(playerId);
  }

  Widget _playerListView(BuildContext context) {
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
                        color: Colors.grey.shade100,
                        width: 1.0,
                      ),
                    ),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        height: 0.0,
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: CircleAvatar(
                          minRadius: 24.0,
                          backgroundColor: Colors.transparent,
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
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                sortedBy == "NAME"
                                    ? Icon(
                                        isAscending
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 14.0,
                                        color: Colors.grey.shade600,
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
                              onSort("SCORE");
                            }
                          },
                          child: Container(
                            height: 28.0,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "Points".toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                sortedBy == "SCORE"
                                    ? Icon(
                                        isAscending
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 14.0,
                                        color: Colors.grey.shade600,
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "Credits".toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                sortedBy == "CREDITS"
                                    ? Icon(
                                        isAscending
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 14.0,
                                        color: Colors.grey.shade600,
                                      )
                                    : Container(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 48.0,
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
                        color: Colors.grey.shade100,
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
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: <Widget>[
                              CircleAvatar(
                                minRadius: 24.0,
                                backgroundColor: Colors.black12,
                                child: CachedNetworkImage(
                                  imageUrl: _player.jerseyUrl,
                                  placeholder: (context, string) {
                                    return Container(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                      width: teamLogoHeight,
                                      height: teamLogoHeight,
                                    );
                                  },
                                  height: teamLogoHeight,
                                ),
                              ),
                              Image.asset(
                                "images/style-" +
                                    _player.playingStyleId.toString() +
                                    ".png",
                                height: 16.0,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _player.name,
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .subhead
                                    .copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
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
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .subhead
                                          .copyWith(
                                            color: Colors.black,
                                          ),
                                    ),
                                    Text(
                                      " - " +
                                          mapSportLabel[_player.playingStyleId],
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .subhead
                                          .copyWith(
                                            color: Colors.grey.shade500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              showSquadAnnouncedPlayersStatus
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: <Widget>[
                                          RichText(
                                            text: new TextSpan(
                                              text: checkThePlayerPlayingStatus(
                                                      _player.id)
                                                  ? "•"
                                                  : null,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .body1
                                                  .copyWith(
                                                    color: Colors.green,
                                                  ),
                                              children: <TextSpan>[
                                                new TextSpan(
                                                  text:
                                                      checkThePlayerPlayingStatus(
                                                              _player.id)
                                                          ? "Playing"
                                                          : null,
                                                  style: Theme.of(context)
                                                      .primaryTextTheme
                                                      .subtitle
                                                      .copyWith(
                                                        color: Colors.green,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            _player.seriesScore.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
                                  color: Colors.black,
                                ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            _player.credit.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
                                  color: Colors.black,
                                ),
                          ),
                        ),
                        Container(
                          width: 48.0,
                          height: 40.0,
                          padding: EdgeInsets.only(left: 8.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey.shade200,
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

  getPlayingStyleLabel(String label) {
    switch (label) {
      case "Batsman":
        return "batsmen".toUpperCase();
      case "Bowler":
        return "Bowlers".toUpperCase();
      case "All Rounder":
        return "All Rounders".toUpperCase();
      case "Raider":
        return "Raiders".toUpperCase();
      case "Defender":
        return "Defenders".toUpperCase();
      case "All-Rounder":
        return "All Rounders".toUpperCase();
      default:
        return label.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.grey.shade300,
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
                    getPlayingStyleLabel(style.label),
                style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _playerListView(context),
        )
      ],
    );
  }
}
