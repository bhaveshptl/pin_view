import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:playfantasy/appconfig.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/mycontest.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/searchcontest.dart';
import 'package:playfantasy/commonwidgets/update.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';

class Lobby extends StatefulWidget {
  final String appUrl;
  final bool isForceUpdate;
  final bool updateAvailable;

  Lobby({
    this.appUrl,
    this.updateAvailable,
    this.isForceUpdate,
  });

  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby> with SingleTickerProviderStateMixin {
  int _sportType = 1;
  List<League> _leagues;
  TabController _controller;
  // bool _bShowLoader = false;
  List<String> _carousel = [];
  bool bUpdateAppConfirmationShown = false;
  Map<String, int> _mapSportTypes;
  List<String> _sports;

  // _showLoader(bool bShow) {
  //   setState(() {
  //     _bShowLoader = bShow;
  //   });
  // }

  @override
  initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 3);
    _getInitData();
    _getSportsType();
    _controller.addListener(() {
      setState(() {
        _sportType = _controller.index + 1;
      });
    });
    _mapSportTypes = {
      "CRICKET": 1,
      "FOOTBALL": 2,
      "KABADDI": 3,
    };
  }

  _showUpdatingAppDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          isForceUpdate: widget.isForceUpdate,
        );
      },
      barrierDismissible: !widget.isForceUpdate,
    );
  }

  _getInitData() async {
    Future<dynamic> futureInitData =
        SharedPrefHelper().getFromSharedPref(ApiUtil.KEY_INIT_DATA);
    await futureInitData.then((onValue) {
      final initData = json.decode(onValue);
      setState(() {
        _carousel = (initData["carousel"] as List).map((dynamic value) {
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SearchContest(
                    leagues: _leagues,
                  ),
            ),
          );
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AppDrawer(),
            ),
          );
          break;
      }
    });
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
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sockets.isConnected() == false) {
      sockets.connect(AppConfig.of(context).websocketUrl);
    }
    if (widget.updateAvailable != null &&
        widget.updateAvailable &&
        !bUpdateAppConfirmationShown) {
      bUpdateAppConfirmationShown = true;
      Timer(Duration(seconds: 1), () {
        _showUpdatingAppDialog(widget.appUrl);
      });
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: <Widget>[
          Scaffold(
            appBar: AppBar(
              elevation: 3.0,
              title: Container(
                height: kToolbarHeight,
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Image.asset(
                        "images/smart11.png",
                        width: 48.0,
                      ),
                    ),
                    Text("PLAY FANTASY"),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(122.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Container(
                              height: 76.0,
                              child: CarouselSlider(
                                items: _carousel.map<Widget>((String img) {
                                  return Container(
                                      height: 102.0,
                                      margin: EdgeInsets.only(
                                          right: 5.0, left: 5.0),
                                      child: Stack(
                                        children: <Widget>[
                                          ClipRRect(
                                              clipBehavior: Clip.hardEdge,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8.0),
                                              ),
                                              child: Image.network(
                                                img,
                                                fit: BoxFit.contain,
                                                width: 1000.0,
                                              )),
                                        ],
                                      ));
                                }).toList(),
                                autoPlay: true,
                                reverse: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 48.0,
                      child: TabBar(
                        controller: _controller,
                        isScrollable: true,
                        indicator: UnderlineTabIndicator(),
                        tabs: _mapSportTypes.keys.map<Tab>((page) {
                          return Tab(text: page);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.account_balance_wallet),
                  onPressed: () {
                    _launchAddCash();
                  },
                )
              ],
            ),
            body: TabBarView(
              controller: _controller,
              children: _mapSportTypes.keys.map<Widget>((page) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: LobbyWidget(
                        sportType: _mapSportTypes[page],
                        onLeagues: (value) {
                          _leagues = value;
                        },
                        onSportChange: _onSportSelectionChaged,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            bottomNavigationBar:
                LobbyBottomNavigation(_onNavigationSelectionChange, 0),
          ),
        ],
      ),
    );
  }
}
