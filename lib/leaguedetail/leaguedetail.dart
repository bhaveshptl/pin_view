import 'dart:convert';
import 'package:playfantasy/utils/fantasywebsocket.dart';

import 'package:flutter/material.dart';
import 'package:playfantasy/modal/l1.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/createcontest.dart';
import 'package:playfantasy/leaguedetail/contests.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/leaguedetail/createteam.dart';

const int DEFAULT_SELECTED_BOTTOM_NAVIGATION_INDEX = 0;

L1 l1Data;
int _currentIndex = DEFAULT_SELECTED_BOTTOM_NAVIGATION_INDEX;
List<Widget> _widgets = [];

class LeagueDetail extends StatefulWidget {
  final League _league;
  LeagueDetail(this._league);

  @override
  State<StatefulWidget> createState() => LeagueDetailState();
}

Map<String, dynamic> lobbyUpdatePackate = {};

class LeagueDetailState extends State<LeagueDetail> {
  String title = "Match";

  _onWsMsg(onData) {
    Map<String, dynamic> _response = json.decode(onData);

    if (_response["bReady"] == 1) {
      _getL1Data();
    } else if (_response["iType"] == 5 && _response["bSuccessful"] == true) {
      setState(() {
        l1Data = L1.fromJson(_response["data"]["l1"]);
        _widgets = [
          Contests(widget._league, l1Data),
          CreateTeam(widget._league, l1Data),
          MyContests(),
          CreateContest(widget._league),
          AddCash(),
        ];
        _currentIndex = _currentIndex;
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
    FantasyWebSocket().sendMessage(lobbyUpdatePackate);
  }

  @override
  initState() {
    super.initState();
    FantasyWebSocket().register(_onWsMsg);
    _createL1WSObject();
    _getL1Data();
  }

  _onNavigationSelectionChange(int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => _widgets[index]));
          break;
        case 3:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CreateContest(widget._league),
          ));
          break;
        case 4:
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => _widgets[index], fullscreenDialog: true));
          break;
        default:
          _currentIndex = index;
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
    super.dispose();
    _widgets = [];
    _currentIndex = DEFAULT_SELECTED_BOTTOM_NAVIGATION_INDEX;
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
      body: _widgets.length > 0 ? _widgets[_currentIndex] : new Container(),
      bottomNavigationBar:
          LobbyBottomNavigation(_currentIndex, _onNavigationSelectionChange, 1),
    );
  }
}
