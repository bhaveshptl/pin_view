import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/utils/stringtable.dart';

const double TEAM_LOGO_HEIGHT = 24.0;

class ChooseCaptain extends StatefulWidget {
  final FanTeamRule fanTeamRules;
  final List<Player> selectedPlayers;
  final Function onSave;
  final Player captain;
  final Player viceCaptain;

  ChooseCaptain(
      {this.fanTeamRules,
      this.selectedPlayers,
      this.onSave,
      this.captain,
      this.viceCaptain});

  @override
  State<StatefulWidget> createState() => ChooseCaptainState();
}

class ChooseCaptainState extends State<ChooseCaptain> {
  Player _captain;
  Player _vCaptain;

  @override
  void initState() {
    super.initState();
    _captain = widget.captain;
    _vCaptain = widget.viceCaptain;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: OutlineButton(
                    padding: EdgeInsets.all(0.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      strings.get("CANCEL").toUpperCase(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: RaisedButton(
                    color: Colors.teal,
                    textColor: Colors.white70,
                    padding: EdgeInsets.all(0.0),
                    onPressed: () {
                      if (_captain == null || _vCaptain == null) {
                        _showErrorMessage(
                          strings.get("CAPTAIN_VCAPTAIN_SELECTION"),
                        );
                      } else {
                        widget.onSave(_captain, _vCaptain);
                      }
                    },
                    child: Text(
                      strings.get("SAVE_TEAM").toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 12.0,
            color: Colors.black45,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
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
                          "NAME",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          strings.get("CAPTAIN").toUpperCase() +
                              " (" +
                              widget.fanTeamRules.captainMult.toString() +
                              "X)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          strings.get("V_CAPTAIN") +
                              " (" +
                              widget.fanTeamRules.vcMult.toString() +
                              "X)",
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
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.selectedPlayers.length,
                    itemBuilder: (context, index) {
                      final _player = widget.selectedPlayers[index];

                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
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
                              flex: 8,
                              child: Text(_player.name),
                            ),
                            Expanded(
                              flex: 2,
                              child: Checkbox(
                                value: _captain == null
                                    ? false
                                    : _captain.id == _player.id,
                                onChanged: (bool value) {
                                  setState(() {
                                    if (_captain == _player) {
                                      _captain = null;
                                    } else if (!(_vCaptain != null &&
                                        _vCaptain.id == _player.id)) {
                                      _captain = _player;
                                    }
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Checkbox(
                                value: _vCaptain == null
                                    ? false
                                    : _vCaptain.id == _player.id,
                                onChanged: (bool value) {
                                  setState(() {
                                    if (_vCaptain == _player) {
                                      _vCaptain = null;
                                    } else if (!(_captain != null &&
                                        _captain.id == _player.id)) {
                                      _vCaptain = _player;
                                    }
                                  });
                                },
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
          ),
        ],
      ),
    );
  }
}
