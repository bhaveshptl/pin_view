import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:playfantasy/createteam/teampreview.dart';
import 'dart:io';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/commonwidgets/epoc.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/stringtable.dart';

class ChooseCaptain extends StatefulWidget {
  final L1 l1Data;
  final League league;
  final Player captain;
  final Function onSave;
  final Player viceCaptain;
  final FanTeamRule fanTeamRules;
  final List<Player> selectedPlayers;
  final Map<int, String> mapSportLabel;

  ChooseCaptain({
    this.l1Data,
    this.league,
    this.onSave,
    this.captain,
    this.viceCaptain,
    this.fanTeamRules,
    this.mapSportLabel,
    this.selectedPlayers,
  });

  @override
  State<StatefulWidget> createState() => ChooseCaptainState();
}

class ChooseCaptainState extends State<ChooseCaptain> {
  Player _captain;
  Player _vCaptain;
  String sortBy = "type";
  List<Player> sortedPlayers;
  double teamLogoHeight = 40.0;
  bool isIos = false;

  @override
  void initState() {
    super.initState();
    _captain = widget.captain;
    _vCaptain = widget.viceCaptain;
    sortedPlayers = getSortedPlayers();
    if (Platform.isIOS) {
      isIos = true;
    }
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

  getSortedPlayers() {
    List<Player> players = [];
    switch (sortBy) {
      case "type":
        players = [];
        widget.l1Data.league.fanTeamRules.styles.forEach((style) {
          widget.selectedPlayers.forEach((player) {
            if (player.playingStyleId == style.id) {
              players.add(player);
            }
          });
        });
        break;
      case "points":
        players = widget.selectedPlayers;
        players.sort((a, b) {
          return (b.seriesScore - a.seriesScore).toInt();
        });
        break;
      default:
    }
    return players;
  }

  _getPlayerStyle(Player player) {
    PlayingStyle _style;
    widget.fanTeamRules.styles.forEach((PlayingStyle style) {
      if (player.playingStyleId == style.id) {
        _style = style;
      }
    });
    return _style;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      appBar: AppBar(
        title: EPOC(
          timeInMiliseconds: widget.league.matchStartTime,
          style: Theme.of(context).primaryTextTheme.title.copyWith(
                color: Colors.white,
              ),
        ),
        elevation: 0.0,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(10),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black26,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "Choose your Captain and Vice Captain",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 32.0,
                            height: 32.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black26,
                              ),
                            ),
                            child: Text(
                              "C",
                              style: TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "Gets 2X Points",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 32.0,
                              height: 32.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black26,
                                ),
                              ),
                              child: Text(
                                "VC",
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Gets 1.5X Points",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1.0,
                  color: Colors.grey.shade400,
                ),
                Container(
                  height: 48.0,
                  padding: EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: <Widget>[
                      Text("Sort By"),
                      Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 8.0),
                        child: InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: Colors.green,
                                width: sortBy == "type" ? 2.0 : 0.0,
                              ),
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.all(8.0),
                            child: Text("Player Type"),
                          ),
                          onTap: () {
                            setState(() {
                              sortBy = "type";
                              sortedPlayers = getSortedPlayers();
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 8.0),
                        child: InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3.0),
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.green,
                                width: sortBy == "points" ? 2.0 : 0.0,
                              ),
                            ),
                            padding: EdgeInsets.all(8.0),
                            child: Text("Player Score"),
                          ),
                          onTap: () {
                            setState(() {
                              sortBy = "points";
                              sortedPlayers = getSortedPlayers();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      final _player = sortedPlayers[index];
                      final _prevPlayer =
                          index == 0 ? _player : sortedPlayers[index - 1];

                      return Padding(
                        padding: _prevPlayer.playingStyleId ==
                                    _player.playingStyleId ||
                                sortBy != "type"
                            ? EdgeInsets.all(0.0)
                            : EdgeInsets.only(top: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 8.0,
                          ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: <Widget>[
                                          Text(
                                            _player.teamId ==
                                                    widget.league.teamA.id
                                                ? widget.league.teamA.name
                                                : widget.league.teamB.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            " - " +
                                                widget.mapSportLabel[
                                                    _player.playingStyleId],
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
                              Row(
                                children: <Widget>[
                                  Text(
                                    _player.seriesScore.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    " Points",
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  child: Container(
                                    width: 32.0,
                                    height: 32.0,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black26,
                                        ),
                                        color: _captain != null &&
                                                _captain.id == _player.id
                                            ? Colors.orange
                                            : Colors.white),
                                    child: Text(
                                      _captain == null
                                          ? "C"
                                          : _captain.id == _player.id
                                              ? "2X"
                                              : "C",
                                      style: TextStyle(
                                        color: _captain != null &&
                                                _captain.id == _player.id
                                            ? Colors.white
                                            : Colors.black45,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (_captain == _player) {
                                        _captain = null;
                                      } else if (_vCaptain == _player) {
                                        _vCaptain = null;
                                        _captain = _player;
                                      } else if (!(_vCaptain != null &&
                                          _vCaptain.id == _player.id)) {
                                        _captain = _player;
                                      }
                                    });
                                  },
                                ),
                              ),
                              widget.fanTeamRules.vcMult != 0.0
                                  ? Expanded(
                                      flex: 3,
                                      child: InkWell(
                                        child: Container(
                                          width: 32.0,
                                          height: 32.0,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.black26,
                                              ),
                                              color: _vCaptain != null &&
                                                      _vCaptain.id == _player.id
                                                  ? Colors.orange
                                                  : Colors.white),
                                          child: Text(
                                            _vCaptain == null
                                                ? "VC"
                                                : _vCaptain.id == _player.id
                                                    ? "1.5X"
                                                    : "VC",
                                            style: TextStyle(
                                              color: _vCaptain != null &&
                                                      _vCaptain.id == _player.id
                                                  ? Colors.white
                                                  : Colors.black45,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            if (_vCaptain == _player) {
                                              _vCaptain = null;
                                            } else if (_captain == _player) {
                                              _captain = null;
                                              _vCaptain = _player;
                                            } else if (!(_captain != null &&
                                                _captain.id == _player.id)) {
                                              _vCaptain = _player;
                                            }
                                          });
                                        },
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 72.0,
            padding:isIos?EdgeInsets.only(bottom: 8.0):null,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10.0,
                  spreadRadius: 3.0,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 40.0, right: 8.0),
                    child: Container(
                      height: 48.0,
                      child: ColorButton(
                        color: Colors.orange,
                        child: Text(
                          "Team Preview".toUpperCase(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            FantasyPageRoute(
                              pageBuilder: (BuildContext context) =>
                                  TeamPreview(
                                    league: widget.league,
                                    l1Data: widget.l1Data,
                                    allowEditTeam: false,
                                    fanTeamRules:
                                        widget.l1Data.league.fanTeamRules,
                                    myTeam: MyTeam(
                                      captain:
                                          _captain == null ? null : _captain.id,
                                      viceCaptain: _vCaptain == null
                                          ? null
                                          : _vCaptain.id,
                                      players: sortedPlayers,
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 40.0, left: 8.0),
                    child: Container(
                      height: 48.0,
                      child: ColorButton(
                        child: Text(
                          "Save Team".toUpperCase(),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        onPressed: () {
                          if ((widget.fanTeamRules.captainMult != 0 &&
                                  _captain == null) ||
                              (widget.fanTeamRules.vcMult != 0.0 &&
                                  _vCaptain == null)) {
                            _showErrorMessage(
                              strings.get("CAPTAIN_VCAPTAIN_SELECTION"),
                            );
                          } else {
                            widget.onSave(_captain, _vCaptain);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
