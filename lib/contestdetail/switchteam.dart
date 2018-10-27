import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class SwitchTeam extends StatefulWidget {
  final L1 l1Data;
  final MyTeam oldTeam;
  final Contest contest;
  final List<MyTeam> myTeams;
  final List<MyTeam> contestMyTeams;

  SwitchTeam({
    this.l1Data,
    this.oldTeam,
    this.contest,
    this.myTeams,
    this.contestMyTeams,
  });

  @override
  State<StatefulWidget> createState() => SwitchTeamState();
}

class SwitchTeamState extends State<SwitchTeam> {
  String cookie = "";
  int _selectedTeamId = -1;
  List<MyTeam> _myUniqueTeams = [];

  _switchTeam(BuildContext context) async {
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    Map<String, dynamic> payload = {
      "leagueId": widget.l1Data.league.id,
      "inningsId": widget.l1Data.league.inningsId,
      "contestId": widget.contest.id,
      "oldTeamId": widget.oldTeam.id,
      "newTeamId": _selectedTeamId.toString(),
      "matchId": widget.l1Data.league.rounds[0].matches[0].id,
      "channelId": 3,
    };

    await http.Client()
        .post(
      ApiUtil.SWITCH_CONTEST_TEAM,
      headers: {'Content-type': 'application/json', "cookie": cookie},
      body: json.encode(payload),
    )
        .then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"] == false) {
            Navigator.of(context).pop(
              json.encode({
                "error": false,
                "msg": response["message"],
                "oldTeam": widget.oldTeam.id,
                "newTeam": _selectedTeamId,
              }),
            );
          } else if (response["error"] == true) {
            Navigator.of(context).pop(
              json.encode({
                "error": true,
                "msg": response["message"],
              }),
            );
          }
        } else if (res.statusCode == 401) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response["error"]["reasons"].length > 0) {}
        }
      },
    );
  }

  setUniqueTeams(List<dynamic> contestMyTeams) {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in widget.myTeams) {
      bool bIsTeamUsed = false;
      for (MyTeam contestTeam in contestMyTeams) {
        if (team.id == contestTeam.id) {
          bIsTeamUsed = true;
          break;
        }
      }
      if (!bIsTeamUsed) {
        myUniqueTeams.add(team);
      }
    }
    if (myUniqueTeams.length > 0) {
      setState(() {
        _selectedTeamId = myUniqueTeams[0].id;
        _myUniqueTeams = myUniqueTeams;
      });
    }
  }

  List<DropdownMenuItem> _getTeamList() {
    List<DropdownMenuItem> listTeams = [];
    if (_myUniqueTeams != null && _myUniqueTeams.length > 0) {
      for (MyTeam team in _myUniqueTeams) {
        listTeams.add(
          DropdownMenuItem(
            child: Container(
              // width: 110.0,
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            value: team.id,
          ),
        );
      }
    }
    return listTeams;
  }

  @override
  void initState() {
    super.initState();
    setUniqueTeams(widget.contestMyTeams);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(strings.get("SWITCH_TEAM").toUpperCase()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: new TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: strings.get("SWITCH_FROM")),
                      TextSpan(
                        text: " " + widget.oldTeam.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text(
                strings.get("TO"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    DropdownButton(
                      value: _selectedTeamId,
                      items: _getTeamList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTeamId = value;
                        });
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(strings.get("CANCEL").toUpperCase()),
        ),
        FlatButton(
          onPressed: () {
            _switchTeam(context);
          },
          child: Text(strings.get("SWITCH").toUpperCase()),
        ),
      ],
    );
  }
}
