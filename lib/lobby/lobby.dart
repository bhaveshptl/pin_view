import 'package:flutter/material.dart';

import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/earncash.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/lobby/createcontest.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';

class Lobby extends StatefulWidget {
  final List<Widget> widgets = [
    LobbyWidget(),
    CreateContest(),
    MyContests(),
    EarnCash(),
    AddCash(),
  ];

  @override
  State<StatefulWidget> createState() => LobbyState();
}

int _currentIndex = 0;

class LobbyState extends State<Lobby> {
  onNavigationSelectionChange(int index) {
    setState(() {
      if (index == 4) {
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (context) => AddCash(), fullscreenDialog: true));
      } else {
        _currentIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("LOBBY"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {},
          )
        ],
      ),
      drawer: AppDrawer(),
      body: widget.widgets[_currentIndex],
      bottomNavigationBar:
          LobbyBottomNavigation(_currentIndex, onNavigationSelectionChange),
    );
  }
}
