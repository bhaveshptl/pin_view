import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/createcontest.dart';
import 'package:playfantasy/leaguedetail/contests.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';

class LeagueDetail extends StatefulWidget {
  final League _league;
  LeagueDetail(this._league);

  @override
  State<StatefulWidget> createState() => LeagueDetailState();
}

class LeagueDetailState extends State<LeagueDetail> {
  L1 l1Data;
  String title = "Match";
  Map<String, dynamic> lobbyUpdatePackate = {};

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      _getL1Data();
    } else if (_response["iType"] == 5 && _response["bSuccessful"] == true) {
      setState(() {
        l1Data = L1.fromJson(_response["data"]["l1"]);
      });
    }
  }

  _createL1WSObject() {
    lobbyUpdatePackate["iType"] = 5;
    lobbyUpdatePackate["sportsId"] = 1;
    lobbyUpdatePackate["bResAvail"] = true;
    lobbyUpdatePackate["id"] = widget._league.leagueId;
  }

  _getL1Data() {
    sockets.sendMessage(lobbyUpdatePackate);
  }

  @override
  initState() {
    super.initState();
    sockets.register(_onWsMsg);
    _createL1WSObject();
    _getL1Data();
  }

  _onNavigationSelectionChange(BuildContext context, int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CreateTeam(widget._league, l1Data)));
          break;
        case 2:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MyContests(),
          ));
          break;
        case 3:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CreateContest(widget._league),
          ));
          break;
        case 4:
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddCash(), fullscreenDialog: true));
          break;
      }
    });
  }

  _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                    child: Text(
                      "Coming Soon!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
              Text(
                  "We are currently working on this feature and will launch soon.")
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    sockets.unRegister(_onWsMsg);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Tooltip(
            message: "Contest filter",
            child: IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog();
              },
            ),
          )
        ],
      ),
      body: l1Data == null ? Container() : Contests(widget._league, l1Data),
      bottomNavigationBar:
          LobbyBottomNavigation(_onNavigationSelectionChange, 1),
    );
  }
}
