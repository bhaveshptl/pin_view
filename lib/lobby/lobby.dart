import 'dart:io';
import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/loader.dart';

import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/lobby/earncash.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/searchcontest.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class Lobby extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby> {
  String cookie;
  int _sportType = 1;
  bool _bShowLoader = false;

  _showLoader(bool bShow) {
    setState(() {
      _bShowLoader = bShow;
    });
  }

  _launchAddCash() async {
    if (cookie == null) {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        setState(() {
          cookie = value;
        });
      });
    }

    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => AddCash(
              cookie: cookie,
            ),
        fullscreenDialog: true));
  }

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
          _launchAddCash();
          break;
      }
    });
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
            title: new Text(strings.get("APP_CLOSE_TITLE")),
            content: new Text(strings.get("DO_U_W_EXIT")),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text(
                  strings.get("NO").toUpperCase(),
                ),
              ),
              new FlatButton(
                onPressed: () => exit(0),
                child: new Text(
                  strings.get("YES").toUpperCase(),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: <Widget>[
          Scaffold(
            appBar: AppBar(
              elevation: 0.0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DropdownButton(
                    style: TextStyle(
                        color: Colors.black45,
                        fontSize:
                            Theme.of(context).primaryTextTheme.title.fontSize),
                    onChanged: (value) {
                      setState(() {
                        _sportType = value;
                      });
                    },
                    value: _sportType,
                    items: [
                      DropdownMenuItem(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 24.0),
                          child: Text(strings.get("CRICKET")),
                        ),
                        value: 1,
                      ),
                      DropdownMenuItem(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 24.0),
                          child: Text(strings.get("FOOTBALL")),
                        ),
                        value: 2,
                      ),
                      DropdownMenuItem(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 24.0),
                          child: Text(strings.get("KABADDI")),
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
              showLoader: _showLoader,
            ),
            bottomNavigationBar:
                LobbyBottomNavigation(_onNavigationSelectionChange, 0),
          ),
          _bShowLoader
              ? Center(
                  child: Container(
                    color: Colors.black54,
                    child: Loader(),
                    constraints: BoxConstraints.expand(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
