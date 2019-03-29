import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/appconfig.dart';
import 'package:package_info/package_info.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:playfantasy/lobby/mycontests/newmycontest.dart';

import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/update.dart';
import 'package:playfantasy/commonwidgets/loader.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class Lobby extends StatefulWidget {
  final String appUrl;
  final List<dynamic> logs;
  final bool isForceUpdate;
  final bool updateAvailable;

  Lobby({
    this.logs,
    this.appUrl,
    this.updateAvailable,
    this.isForceUpdate,
  });

  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby> with SingleTickerProviderStateMixin {
  int _sportType = 0;
  List<League> _leagues;
  bool bShowLoader = false;
  TabController _controller;
  List<dynamic> _carousel = [];
  Map<String, int> _mapSportTypes;
  bool bUpdateAppConfirmationShown = false;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 3);
    getBanners();
    _getSportsType();
    _controller.addListener(() {
      if (!_controller.indexIsChanging) {
        setState(() {
          _sportType = _controller.index + 1;
        });
        SharedPrefHelper().saveSportsType(_sportType.toString());
      }
    });
    _mapSportTypes = {
      "CRICKET": 1,
      "FOOTBALL": 2,
    };
  }

  _showUpdatingAppDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          logs: widget.logs,
          isForceUpdate: widget.isForceUpdate,
        );
      },
      barrierDismissible: !widget.isForceUpdate,
    );
  }

  // _getInitData() async {
  //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   http.Request req =
  //       http.Request("POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.INIT_DATA));
  //   req.body = json.encode({
  //     "version": double.parse(packageInfo.version),
  //     "channelId": HttpManager.channelId,
  //   });
  //   await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
  //     if (res.statusCode >= 200 && res.statusCode <= 299) {
  //       final initData = json.decode(res.body);
  //       setState(() {
  //         _carousel = (initData["carousel"] as List).map((dynamic value) {
  //           return value.toString();
  //         }).toList();
  //       });
  //     }
  //   });
  // }
  getBanners() async {
    http.Request req = http.Request(
        "GET",
        Uri.parse(
          BaseUrl().apiUrl + ApiUtil.GET_BANNERS + "/4",
        ));
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        final banners = json.decode(res.body)["banners"];
        setState(() {
          _carousel = (banners as List).map((dynamic value) {
            return value;
          }).toList();
        });
      }
    });
  }

  _getSportsType() async {
    Future<dynamic> futureSportType =
        SharedPrefHelper.internal().getSportsType();
    await futureSportType.then((value) {
      if (value != null) {
        int _sport = int.parse(value == null || value == "0" ? "1" : value);
        Timer(Duration(seconds: 1), () {
          _onSportSelectionChaged(_sport);
        });
      } else {
        SharedPrefHelper().saveSportsType("1");
      }
    });
  }

  _onSportSelectionChaged(int _sport) {
    if (_sportType != _sport) {
      _sportType = _sport;
      _controller.index = _sport - 1;
      SharedPrefHelper().saveSportsType(_sportType.toString());
    } else if (_sportType <= 0) {
      setState(() {
        _sportType = 1;
        _controller.index = _sportType - 1;
        SharedPrefHelper().saveSportsType(_sportType.toString());
      });
    }
  }

  _onNavigationSelectionChange(BuildContext context, int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.of(context).push(
            FantasyPageRoute(
              pageBuilder: (context) => NewMyContests(
                    leagues: _leagues,
                    mapSportTypes: _mapSportTypes,
                    onSportChange: _onSportSelectionChaged,
                  ),
            ),
          );
          break;
        case 1:
          _launchAddCash();
          break;
        case 2:
          showLoader(true);
          routeLauncher.launchEarnCash(scaffoldKey, onComplete: () {
            showLoader(false);
          });
          break;
        case 3:
          Navigator.of(context).push(
            FantasyPageRoute(
              pageBuilder: (context) => AppDrawer(),
            ),
          );
          break;
      }
    });
  }

  _launchAddCash() async {
    showLoader(true);
    routeLauncher.launchAddCash(
      context,
      onSuccess: (result) {},
      onComplete: () {
        showLoader(false);
      },
    );
  }

  showLoader(bool bShow) {
    setState(() {
      bShowLoader = bShow;
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
      FantasyPageRoute(
        pageBuilder: (context) => WebviewScaffold(
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
      FantasyWebSocket().connect(BaseUrl().websocketUrl);
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
            key: scaffoldKey,
            appBar: AppBar(
              elevation: 3.0,
              title: Container(
                height: kToolbarHeight,
                padding: EdgeInsets.only(top: 6.0, bottom: 6.0),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5.0),
                      child: Image.asset(
                        "images/logo.png",
                        width: 48.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppConfig.of(context).appName.toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(122.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                              bottom: 4.0,
                              top: 4.0,
                            ),
                            height: 84.0,
                            child: _carousel.length > 0
                                ? CarouselSlider(
                                    enlargeCenterPage: false,
                                    aspectRatio: 16 / 3,
                                    autoPlayInterval: Duration(seconds: 10),
                                    items:
                                        _carousel.map<Widget>((dynamic banner) {
                                      return FlatButton(
                                        padding: EdgeInsets.all(0.0),
                                        onPressed: () {
                                          if (banner["CTA"] != "" &&
                                              banner["CTA"] != "NA") {
                                            showLoader(true);
                                          }
                                          routeLauncher.launchBannerRoute(
                                              banner: banner,
                                              context: context,
                                              scaffoldKey: scaffoldKey,
                                              onComplete: () {
                                                showLoader(false);
                                              });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              banner["banner"],
                                              fit: BoxFit.cover,
                                              width: 1000.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    autoPlay:
                                        _carousel.length <= 2 ? false : true,
                                    reverse: false,
                                  )
                                : Container(),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 48.0,
                      child: _sportType >= 0
                          ? TabBar(
                              controller: _controller,
                              isScrollable: true,
                              indicator: UnderlineTabIndicator(),
                              tabs: _mapSportTypes.keys.map<Tab>((page) {
                                return Tab(
                                  text: page,
                                  // child: Row(
                                  //   children: <Widget>[
                                  //     SvgPicture.asset(
                                  //       _sportType == _mapSportTypes[page]
                                  //           ? "images/" +
                                  //               page.toLowerCase() +
                                  //               ".svg"
                                  //           : "images/" +
                                  //               page.toLowerCase() +
                                  //               "light" +
                                  //               ".svg",
                                  //       width: 18.0,
                                  //     ),
                                  //     Padding(
                                  //       padding: EdgeInsets.only(left: 6.0),
                                  //       child: Text(page),
                                  //     ),
                                  //   ],
                                  // ),
                                );
                              }).toList(),
                            )
                          : Container(),
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
            body: Stack(
              children: <Widget>[
                Container(
                  decoration: AppConfig.of(context).showBackground
                      ? BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("images/background.png"),
                              repeat: ImageRepeat.repeat),
                        )
                      : null,
                  child: _sportType >= 0
                      ? TabBarView(
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
                                    mapSportTypes: _mapSportTypes,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                      : Container(),
                ),
              ],
            ),
            bottomNavigationBar:
                LobbyBottomNavigation(_onNavigationSelectionChange, 0),
          ),
          bShowLoader ? Loader() : Container(),
        ],
      ),
    );
  }
}
