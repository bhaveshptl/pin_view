import 'package:flutter/material.dart';

import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/earncash.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/lobby/searchcontest.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';

class Lobby extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby> {
  int _sportType = 1;

  _onNavigationSelectionChange(BuildContext context, int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.of(context).push(
              new MaterialPageRoute(builder: (context) => SearchContest()));
          break;
        case 2:
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => MyContests()));
          break;
        case 3:
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => EarnCash()));
          break;
        case 4:
          Navigator.of(context).push(new MaterialPageRoute(
              builder: (context) => AddCash(), fullscreenDialog: true));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton(
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: Theme.of(context).primaryTextTheme.title.fontSize),
              onChanged: (value) {
                setState(() {
                  _sportType = value;
                });
              },
              value: _sportType,
              items: [
                DropdownMenuItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 24.0),
                    child: Text("CRICKET"),
                  ),
                  value: 1,
                ),
                DropdownMenuItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 24.0),
                    child: Text("FOOTBALL"),
                  ),
                  value: 2,
                ),
                DropdownMenuItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 24.0),
                    child: Text("KABADDI"),
                  ),
                  value: 3,
                )
              ],
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: "Help - How to play",
            onPressed: () {},
          )
        ],
      ),
      drawer: AppDrawer(),
      body: LobbyWidget(
        sportType: _sportType,
      ),
      bottomNavigationBar:
          LobbyBottomNavigation(_onNavigationSelectionChange, 0),
    );
  }
}
