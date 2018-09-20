import 'package:flutter/material.dart';

import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/earncash.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/lobby/searchcontest.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';

class Lobby extends StatefulWidget {
  final List<Widget> _widgets = [
    LobbyWidget(),
    SearchContest(),
    MyContests(),
    EarnCash(),
    AddCash(),
  ];

  @override
  State<StatefulWidget> createState() => LobbyState();
}

int _currentIndex = 0;

class LobbyState extends State<Lobby> {
  _onNavigationSelectionChange(int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.of(context).push(
              new MaterialPageRoute(builder: (context) => SearchContest()));
          break;
        case 4:
          Navigator.of(context).push(new MaterialPageRoute(
              builder: (context) => AddCash(), fullscreenDialog: true));
          break;
        default:
          _currentIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text("LOBBY"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: "Help - How to play",
            onPressed: () {},
          )
        ],
      ),
      drawer: AppDrawer(),
      body: widget._widgets[_currentIndex],
      bottomNavigationBar:
          LobbyBottomNavigation(_currentIndex, _onNavigationSelectionChange, 0),
    );
  }
}
