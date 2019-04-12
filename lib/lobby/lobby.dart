import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/modal/user.dart';
import 'package:playfantasy/mymatches/my_matches.dart';
import 'package:playfantasy/profilepages/update.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/mycontests/mycontest.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';

class Lobby extends StatefulWidget {
  final String appUrl;
  final List<dynamic> logs;
  final bool isForceUpdate;
  final bool updateAvailable;

  Lobby({
    this.logs,
    this.appUrl,
    this.isForceUpdate,
    this.updateAvailable,
  });

  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  User _user;
  int _sportType = 1;
  int _activeIndex = 0;
  List<League> _leagues;
  double userBalance = 0.0;
  TabController _controller;
  List<dynamic> _carousel = [];
  Map<String, int> _mapSportTypes;
  bool bUpdateAppConfirmationShown = false;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> referDetail;
  final formatCurrency = NumberFormat.currency(
    locale: "hi_IN",
    symbol: strings.rupee,
    decimalDigits: 2,
  );

  @override
  initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 3);
    _getBanners();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateUserInfo();
    }
  }

  @override
  void didChangeDependencies() {
    bool ticker = !TickerMode.of(context);
    if (!ticker) {
      updateUserInfo();
    }
    super.didChangeDependencies();
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
      barrierDismissible: false,
    );
  }

  updateUserInfo() async {
    _user = await getUserInfo();
    if (_user != null) {
      setState(() {
        userBalance =
            (_user.nonWithdrawable == null ? 0.0 : _user.nonWithdrawable) +
                (_user.withdrawable == null ? 0.0 : _user.withdrawable) +
                (_user.depositBucket == null ? 0.0 : _user.depositBucket);
      });
    }
  }

  getUserInfo() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.AUTH_CHECK_URL,
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> user = json.decode(res.body)["user"];
        SharedPrefHelper.internal().saveToSharedPref(
            ApiUtil.SHARED_PREFERENCE_USER_KEY, json.encode(user));
        return User.fromJson(user);
      } else {
        return null;
      }
    });
  }

  _getBanners() async {
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
        setState(() {
          _sportType = _sport;
        });
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

  _onNavigationSelectionChange(BuildContext context, int index) async {
    switch (index) {
      case 0:
        setState(() {
          _activeIndex = 0;
        });
        break;
      case 1:
        setState(() {
          _activeIndex = 1;
        });
        showLoader(true);
        break;
      case 2:
        _launchAddCash();
        break;
      case 3:
        showLoader(true);
        routeLauncher.launchEarnCash(scaffoldKey, onComplete: () {
          showLoader(false);
        });
        break;
    }
  }

  _launchAddCash() async {
    showLoader(true);
    routeLauncher.launchAddCash(
      context,
      onComplete: () {
        showLoader(false);
      },
    );
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
            title: Text(strings.get("APP_CLOSE_TITLE")),
            content: Container(
              width: MediaQuery.of(context).size.width,
              child: Text(strings.get("DO_U_W_EXIT")),
            ),
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

  Widget getActivePage() {
    switch (_activeIndex) {
      case 0:
        return Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _controller,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.black,
                labelStyle: Theme.of(context).primaryTextTheme.body2.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 4.0,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                tabs: _mapSportTypes.keys.map<Tab>((page) {
                  return Tab(
                    text: page,
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: _carousel.length > 0
                  ? CarouselSlider(
                      enlargeCenterPage: false,
                      aspectRatio: 16 / 3,
                      autoPlayInterval: Duration(seconds: 10),
                      items: _carousel.map<Widget>((dynamic banner) {
                        return FlatButton(
                          padding: EdgeInsets.all(0.0),
                          onPressed: () {
                            if (banner["CTA"] != "" && banner["CTA"] != "NA") {
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
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.network(
                                banner["banner"],
                                fit: BoxFit.cover,
                                width: 1000.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      autoPlay: _carousel.length <= 2 ? false : true,
                      reverse: false,
                    )
                  : Container(),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    child: Text(
                      "Upcoming Matches",
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: _mapSportTypes.keys.map<Widget>((page) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
            ),
          ],
        );
        break;
      case 1:
        return MyMatches(
          sportsId: _sportType,
          mapSportTypes: _mapSportTypes,
          onSportChange: _onSportSelectionChaged,
        );
      default:
        return Container();
    }
  }

  @override
  void dispose() {
    FantasyWebSocket().stopPingPong();
    super.dispose();
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
      child: ScaffoldPage(
        scaffoldKey: scaffoldKey,
        appBar: AppBar(
          elevation: 0.0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                height: 32.0,
                width: 32.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: Image.asset(
                    "images/logo.png",
                    width: 48.0,
                  ),
                ),
              ),
              Container(
                // width: MediaQuery.of(context).size.width / 2,
                height: 48.0,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Row(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44.0,
                          child: FlatButton(
                            padding: EdgeInsets.all(0.0),
                            onPressed: () {
                              Navigator.of(context).push(
                                FantasyPageRoute(
                                  pageBuilder: (context) => AppDrawer(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 4.0),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32.0,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text(
                            formatCurrency.format(
                              userBalance,
                            ),
                            style: Theme.of(context)
                                .primaryTextTheme
                                .subhead
                                .copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8.0,
                        right: 8.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: ColorButton(
                        child: Text(
                          "ADD CASH",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .button
                              .copyWith(
                                color: Colors.white,
                              ),
                        ),
                        onPressed: () {
                          _launchAddCash();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: getActivePage(),
        bottomNavigationBar: LobbyBottomNavigation(
          _onNavigationSelectionChange,
          activeIndex: _activeIndex,
        ),
      ),
    );
  }
}
