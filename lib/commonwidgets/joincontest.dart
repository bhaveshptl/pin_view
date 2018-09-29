import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/myteam.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class JoinContest extends StatefulWidget {
  final int matchId;
  final Contest contest;
  final Function onError;
  final List<MyTeam> myTeams;

  JoinContest({
    this.matchId,
    this.contest,
    this.myTeams,
    this.onError,
  });

  @override
  State<StatefulWidget> createState() => JoinContestState();
}

class JoinContestState extends State<JoinContest> {
  double userBonus = 0.0;
  double userCashBalance = 0.0;
  int _selectedTeamId = -1;
  List<MyTeam> _myUniqueTeams = [];

  _joinContest(BuildContext context) async {
    if (_selectedTeamId == null || _selectedTeamId == -1) {
    } else {
      String cookie = "";

      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });

      await http.Client()
          .post(
        ApiUtil.JOIN_CONTEST,
        headers: {'Content-type': 'application/json', "cookie": cookie},
        body: json.encoder.convert({
          "contestId": widget.contest.id,
          "teamId": _selectedTeamId,
          "matchId": widget.matchId,
          "prizeType": widget.contest.prizeType,
          "contestCode": widget.contest.contestJoinCode,
          "context": {"channel_id": 3},
          "leagueId": widget.contest.leagueId,
          "entryFee": widget.contest.entryFee,
          "sportsId": 1
        }),
      )
          .then(
        (http.Response res) {
          if (res.statusCode >= 200 && res.statusCode <= 299) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"] == false) {
              Navigator.of(context).pop(response["message"]);
            } else if(response["error"] == true){
              Navigator.of(context).pop(response["message"]);
            }
          } else if (res.statusCode == 401) {
            Map<String, dynamic> response = json.decode(res.body);
            if (response["error"]["reasons"].length > 0) {
              widget.onError(widget.contest, response["error"]);
            }
          }
        },
      );
    }
  }

  setUniqueTeams(List<dynamic> contestMyTeams) {
    List<MyTeam> myUniqueTeams = [];
    for (MyTeam team in widget.myTeams) {
      bool bIsTeamUsed = false;
      for (dynamic contestTeam in contestMyTeams) {
        if (team.id == contestTeam["id"]) {
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

  getMyContestTeams() async {
    String cookie = "";

    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    await http.Client()
        .post(
      ApiUtil.GET_MY_CONTEST_MY_TEAMS,
      headers: {'Content-type': 'application/json', "cookie": cookie},
      body: json.encoder.convert([widget.contest.id]),
    )
        .then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          if (response[widget.contest.id.toString()] != null) {
            List<dynamic> contestMyTeams =
                (response[widget.contest.id.toString()] as List);
            setUniqueTeams(contestMyTeams);
          } else {
            setState(() {
              setUniqueTeams([]);
            });
          }
        }
      },
    );
  }

  List<DropdownMenuItem> _getTeamList() {
    List<DropdownMenuItem> listTeams = [];
    if (_myUniqueTeams != null && _myUniqueTeams.length > 0) {
      for (MyTeam team in _myUniqueTeams) {
        listTeams.add(
          DropdownMenuItem(
            child: Container(
              width: 110.0,
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            value: team.id,
          ),
        );
      }
    } else {
      listTeams.add(
        DropdownMenuItem(
          child: Container(
            width: 110.0,
            child: Text(""),
          ),
          value: -1,
        ),
      );
    }
    return listTeams;
  }

  @override
  void initState() {
    super.initState();
    getMyContestTeams();
  }

  @override
  Widget build(BuildContext context) {
    double bonusUsable =
        (widget.contest.entryFee * widget.contest.bonusAllowed) / 100;
    double usableBonus = userBonus > bonusUsable ? bonusUsable : userBonus;

    return AlertDialog(
      title: Text(strings.get("CONFIRMATION").toUpperCase()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    strings.get("ENTRY_FEE"),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(strings.rupee),
                      Text(
                        widget.contest.entryFee.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    "- " + strings.get("BONUS_USABLE"),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(strings.rupee),
                      Text(
                        usableBonus.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.black12,
          ),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(
                  strings.get("CASH_TO_PAY"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(strings.rupee),
                    Text(
                      (widget.contest.entryFee - usableBonus)
                          .toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(
            color: Colors.black12,
          ),
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Text(
                  strings.get("SELECT_TEAM"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    DropdownButton(
                      value: _selectedTeamId,
                      isDense: false,
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
            _joinContest(context);
          },
          child: Text(strings.get("JOIN").toUpperCase()),
        ),
      ],
    );
  }
}
