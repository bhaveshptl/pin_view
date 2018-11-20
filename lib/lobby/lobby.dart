import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:playfantasy/commonwidgets/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/earncash.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/searchcontest.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class Lobby extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby> {
  int _sportType = 1;
  List<League> _leagues;
  bool _bShowLoader = false;
  List<String> _carousel = [];

  _showLoader(bool bShow) {
    setState(() {
      _bShowLoader = bShow;
    });
  }

  @override
  initState() {
    super.initState();

    _getInitData();
    _getSportsType();
  }

  _getInitData() async {
    Future<dynamic> futureInitData =
        SharedPrefHelper().getFromSharedPref(ApiUtil.KEY_INIT_DATA);
    await futureInitData.then((onValue) {
      setState(() {
        _carousel =
            (json.decode(onValue)["carousel"] as List).map((dynamic value) {
          return value.toString();
        }).toList();
      });
    });
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        int _sport = int.parse(value);
        _onSportSelectionChaged(_sport);
      } else {
        SharedPrefHelper().saveSportsType(_sportType.toString());
      }
    });
  }

  _onSportSelectionChaged(int _sport) {
    if (_sportType != _sport) {
      setState(() {
        _sportType = _sport;
      });
      SharedPrefHelper().saveSportsType(_sportType.toString());
    }
  }

  _launchAddCash() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCash(),
      ),
    );
    if (result != null) {
      _showTransactionResult(json.decode(result));
    }
  }

  _showTransactionResult(Map<String, dynamic> transactionResult) {
    if (transactionResult["authStatus"] == "Authorised") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionSuccess(transactionResult, () {
            Navigator.of(context).pop();
          });
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionFailed(transactionResult, () {
            Navigator.of(context).pop();
          }, () {
            Navigator.of(context).pop();
          });
        },
      );
    }
  }

  _onNavigationSelectionChange(BuildContext context, int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SearchContest(
                    leagues: _leagues,
                  )));
          break;
        case 2:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MyContests(
                    leagues: _leagues,
                    onSportChange: _onSportSelectionChaged,
                  ),
            ),
          );
          break;
        case 3:
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => EarnCash()));
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
      builder: (context) => AlertDialog(
            title: Text(strings.get("APP_CLOSE_TITLE")),
            content: Text(strings.get("DO_U_W_EXIT")),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  strings.get("NO").toUpperCase(),
                ),
              ),
              FlatButton(
                onPressed: () => exit(0),
                child: Text(
                  strings.get("YES").toUpperCase(),
                ),
              ),
            ],
          ),
    );
  }

  launchHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => WebviewScaffold(
                url: "https://www.playfantasy.com/assets/help.html?cache=" +
                    DateTime.now().millisecondsSinceEpoch.toString(),
                appBar: AppBar(
                  title: Text("HELP"),
                ),
              ),
          fullscreenDialog: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: <Widget>[
          Scaffold(
            appBar: AppBar(
              // elevation: 0.0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DropdownButton(
                    style: TextStyle(
                        color: Colors.black45,
                        fontSize:
                            Theme.of(context).primaryTextTheme.title.fontSize),
                    onChanged: (value) {
                      _onSportSelectionChaged(value);
                    },
                    value: _sportType,
                    items: [
                      DropdownMenuItem(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 24.0),
                          child: Text(strings.get("CRICKET").toUpperCase()),
                        ),
                        value: 1,
                      ),
                      DropdownMenuItem(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 24.0),
                          child: Text(strings.get("FOOTBALL").toUpperCase()),
                        ),
                        value: 2,
                      ),
                      DropdownMenuItem(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 24.0),
                          child: Text(
                            strings.get("KABADDI").toUpperCase(),
                          ),
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
                  tooltip: strings.get("HOW_TO_PLAY"),
                  onPressed: () {
                    launchHelp();
                  },
                )
              ],
            ),
            drawer: AppDrawer(),
            body: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 102.0,
                        child: Carousel(
                          indicatorBgPadding: 4.0,
                          boxFit: BoxFit.contain,
                          dotSize: 4.0,
                          dotIncreaseSize: 2.0,
                          autoplayDuration: Duration(seconds: 10),
                          images: _carousel.map((String url) {
                            return NetworkImage(url);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LobbyWidget(
                    sportType: _sportType,
                    showLoader: _showLoader,
                    onLeagues: (value) {
                      _leagues = value;
                    },
                    onSportChange: _onSportSelectionChaged,
                  ),
                ),
              ],
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
