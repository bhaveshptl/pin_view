import 'package:flutter/material.dart';
import 'package:playfantasy/modal/l1.dart';

class ChooseCaptain extends StatefulWidget {
  final FanTeamRule _fanTeamRules;
  final List<Player> _selectedPlayers;
  final Function _onSave;

  ChooseCaptain(this._fanTeamRules, this._selectedPlayers, this._onSave);

  @override
  State<StatefulWidget> createState() => ChooseCaptainState();
}

class ChooseCaptainState extends State<ChooseCaptain> {
  Player _captain;
  Player _vCaptain;

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
                    child: Text("CANCEL"),
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
                            "Captain and vice captain selection is necessary to save team.");
                      } else {
                        widget._onSave(_captain, _vCaptain);
                      }
                    },
                    child: Text("SAVE TEAM"),
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
                          "CAPTAIN (" +
                              widget._fanTeamRules.captainMult.toString() +
                              "X)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "VICE CAPTAIN (" +
                              widget._fanTeamRules.vcMult.toString() +
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
                    itemCount: widget._selectedPlayers.length,
                    itemBuilder: (context, index) {
                      final _player = widget._selectedPlayers[index];
                      final _firstName = _player.name.split(" ")[0];
                      final _lastName = _player.name.split(" ").length > 0
                          ? _player.name.split(" ")[1]
                          : "";
                      final String _playerInitials = (_firstName.length > 0
                                  ? _firstName.substring(0, 1)
                                  : "")
                              .toUpperCase() +
                          (_lastName.length > 0
                                  ? _lastName.substring(0, 1)
                                  : "")
                              .toUpperCase();

                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
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
                              child: Checkbox(
                                value: _captain == null
                                    ? false
                                    : _captain.id == _player.id,
                                onChanged: (bool value) {
                                  setState(() {
                                    if (!(_vCaptain != null &&
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
                                    if (!(_captain != null &&
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
