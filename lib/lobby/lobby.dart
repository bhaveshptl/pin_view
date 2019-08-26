import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/createteam/sports.dart';
import 'package:playfantasy/modal/user.dart';
import 'package:playfantasy/modal/league.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/appdrawer.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/lobby/lobbywidget.dart';
import 'package:playfantasy/profilepages/update.dart';
import 'package:playfantasy/mymatches/my_matches.dart';
import 'package:playfantasy/lobby/bottomnavigation.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/utils/analytics.dart';

class Lobby extends StatefulWidget {
  final String appUrl;
  final List<dynamic> logs;
  final bool isForceUpdate;
  final bool updateAvailable;
  final bool activateDeepLinkingNavigation;
  final Map<String, dynamic> deepLinkingNavigationData;
  
  Lobby({
    this.logs,
    this.appUrl,
    this.isForceUpdate,
    this.updateAvailable,
    this.activateDeepLinkingNavigation,
    this.deepLinkingNavigationData
  });

  @override
  State<StatefulWidget> createState() => LobbyState();
}

class LobbyState extends State<Lobby>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  User _user;
  int _sportType = 1;
  int _activeIndex = 0;
  int _curPageIndex = 0;
  List<League> _leagues;
  double userBalance = 0.0;
  TabController _controller;
  List<dynamic> _carousel = [];
  Map<String, int> _mapSportTypes;
  bool bUpdateAppConfirmationShown = false;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool isIos = false;
  static const utils_platform = const MethodChannel('com.algorin.pf.utils');
  Map<String, dynamic> referDetail;
  final formatCurrency = NumberFormat.currency(
    locale: "hi_IN",
    symbol: strings.rupee,
    decimalDigits: 2,
  );

  @override
  initState() {
    super.initState();
    if (Platform.isIOS) {
      isIos = true;
    }
    _mapSportTypes = sports.mapSports;
    _controller = TabController(vsync: this, length: _mapSportTypes.length);
    _getBanners();
    // _getSportsType();
    _sportType = _mapSportTypes[_mapSportTypes.keys.toList()[0]];
    _controller.addListener(() {
      if (!_controller.indexIsChanging) {
        setState(() {
          _sportType =
              _mapSportTypes[_mapSportTypes.keys.toList()[_controller.index]];
        });
        SharedPrefHelper().saveSportsType(_sportType.toString());
      }
    });
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
        setWebEngageKeys(user);
        
        SharedPrefHelper.internal().saveToSharedPref(
            ApiUtil.SHARED_PREFERENCE_USER_KEY, json.encode(user));
        return User.fromJson(user);
      } else {
        return null;
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  setWebEngageKeys(Map<dynamic, dynamic> data) async {
    Map<dynamic, dynamic> userInfo = new Map();

    
    userInfo["first_name"] =
        data["first_name"] != null ? data["first_name"] : "";
    userInfo["lastName"] = data["lastName"] != null ? data["lastName"] : "";
    userInfo["login_name"] =
        data["login_name"] != null ? data["login_name"] : "";
    userInfo["channelId"] = data["channelId"] != null ? data["channelId"] : "";
    userInfo["withdrawable"] =
        data["withdrawable"] != null ? data["withdrawable"] : "";
    userInfo["depositBucket"] =
        data["depositBucket"] != null ? data["depositBucket"] : "";
    userInfo["nonWithdrawable"] =
        data["nonWithdrawable"] != null ? data["nonWithdrawable"] : "";
    userInfo["nonPlayableBucket"] =
        data["nonPlayableBucket"] != null ? data["nonPlayableBucket"] : "";
    userInfo["accountStatus"] = "";
    userInfo["user_balance_webengage"] =
        data["depositBucket"] + data["withdrawable"];
    Map<dynamic, dynamic> verificationStatus = data["verificationStatus"];
    userInfo["pan_verification"] = verificationStatus["pan_verification"];
    userInfo["mobile_verification"] = verificationStatus["mobile_verification"];
    userInfo["address_verification"] =
        verificationStatus["address_verification"];
    userInfo["email_verification"] = verificationStatus["email_verification"];
    Map<String, dynamic> profileData = await _getProfileData();

    if(profileData["email"] != null ){
      userInfo["email"] = await AnalyticsManager.dosha256Encoding(profileData["email"]); 
    }
    if(profileData["mobile"] != null ){
      String mobile = await AnalyticsManager.dosha256Encoding("+91" + profileData["mobile"].toString());
      userInfo["mobile"] =mobile;
    }    
    if (profileData["fname"] != null) {
      userInfo["first_name"] = profileData["fname"];
    }
    if (profileData["lname"] != null) {
      userInfo["lastName"] = profileData["lname"];
    }
    if (profileData["status"] == "ACTIVE") {
      userInfo["accountStatus"] = "1";
    } else if (profileData["status"] == "CLOSED") {
      userInfo["accountStatus"] = "2";
    } else if (profileData["status"] == "BLOCKED") {
      userInfo["accountStatus"] = "3";
    }
    userInfo["pincode"] =
        profileData["pincode"] != null ? profileData["pincode"] : "";
    userInfo["dob"] = profileData["dob"] != null ? profileData["dob"] : "";
    userInfo["state"] =
        profileData["state"] != null ? profileData["state"] : "";
    try {
      final value =
          await utils_platform.invokeMethod('onUserInfoRefreshed', userInfo);
    } catch (e) {}
  }

  _getProfileData() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.GET_USER_PROFILE,
      ),
    );
    return HttpManager(http.Client()).sendRequest(req).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          return response;
        } else if (res.statusCode == 401) {
          return {};
        }
      },
    ).whenComplete(() {});
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
    }).whenComplete(() {
      showLoader(false);
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

  _onSportSelectionChaged(int _sportIndex) {
    int sportId = sports.mapSports[sports.mapSports.keys.toList()[_sportIndex]];
    if (_sportType != sportId) {
      _sportType = sportId;
      _controller.index = _sportIndex;
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
        if (_activeIndex != 0) {
          setState(() {
            _activeIndex = 0;
          });
        }
        break;
      case 1:
        if (_activeIndex != 1) {
          setState(() {
            _activeIndex = 1;
          });
          showLoader(true);
        }
        break;
      case 2:
        _launchAddCash(source: "bottom");
        break;
      case 3:
        showLoader(true);
        routeLauncher.launchEarnCash(scaffoldKey, onComplete: () {
          showLoader(false);
        });
        break;
      case 4:
        Scaffold.of(context).openEndDrawer();
        // Navigator.of(context).push(
        //   FantasyPageRoute(
        //     pageBuilder: (context) => AppDrawer(),
        //   ),
        // );
        break;
    }
  }

  _launchAddCash({String source}) async {
    showLoader(true);
    routeLauncher.launchAddCash(
      context,
      source: source,
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
    // Navigator.of(context).push(
    //   FantasyPageRoute(
    //     pageBuilder: (context) => WebviewScaffold(
    //           url: "https://www.playfantasy.com/assets/help.html?cache=" +
    //               DateTime.now().millisecondsSinceEpoch.toString(),
    //           appBar: AppBar(
    //             title: Text(
    //               "HELP".toUpperCase(),
    //             ),
    //           ),
    //         ),
    //     fullscreenDialog: true,
    //   ),
    // );
  }

  Widget getActivePage() {
    switch (_activeIndex) {
      case 0:
        return NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: _carousel.length > 0
                            ? CarouselSlider(
                                enlargeCenterPage: false,
                                aspectRatio: 16 / 3.5,
                                viewportFraction: 1.0,
                                onPageChanged: (int index) {
                                  setState(() {
                                    _curPageIndex = index;
                                  });
                                },
                                enableInfiniteScroll: true,
                                autoPlayInterval: Duration(seconds: 10),
                                items: _carousel.map<Widget>((dynamic banner) {
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
                                    child: Image.network(
                                      banner["banner"],
                                      fit: BoxFit.fitWidth,
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  );
                                }).toList(),
                                autoPlay: _carousel.length <= 2 ? false : true,
                                reverse: false,
                              )
                            : Container(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _carousel
                              .asMap()
                              .map((index, f) => MapEntry(
                                  index,
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Container(
                                      width: 8.0,
                                      height: 8.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index == _curPageIndex
                                            ? Theme.of(context).primaryColor
                                            : Colors.black45,
                                      ),
                                    ),
                                  )))
                              .values
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _controller,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.black,
                  labelStyle: Theme.of(context).primaryTextTheme.title.copyWith(
                        fontWeight: FontWeight.w700,
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
                padding: EdgeInsets.only(top: 8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        child: Text(
                          "Upcoming Matches",
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
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
          ),
        );
        break;
      case 1:
        return MyMatches(
          sportsId: _sportType,
          mapSportTypes: _mapSportTypes,
          onSportChange: _onSportSelectionChaged,
          changeBottomNavigationIndex: (index) {
            _onNavigationSelectionChange(context, index);
          },
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

    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: strings.rupee,
      decimalDigits: 2,
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ScaffoldPage(
        scaffoldKey: scaffoldKey,
        endDrawer: AppDrawer(),
        appBar: AppBar(
          elevation: 0.0,
          actions: <Widget>[
            Container(),
          ],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SvgPicture.asset(
                    "images/logo_white.svg",
                    color: Colors.white,
                    width: 32.0,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      "images/logo_name_white.png",
                      height: 20.0,
                    ),
                  ),
                ],
              ),
              ColorButton(
                padding: EdgeInsets.only(
                    left: 8.0, right: 6.0, top: 6.0, bottom: 6.0),
                color: Color.fromRGBO(125, 13, 13, 1),
                elevation: 6.0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Color.fromRGBO(70, 165, 12, 1),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      "images/add-cash-header.png",
                      height: 24.0,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        formatCurrency.format(userBalance),
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    Image.asset(
                      "images/header_add.png",
                      height: 30.0,
                    ),
                  ],
                ),
                onPressed: () {
                  _launchAddCash(source: "topright");
                },
              ),
              // InkWell(
              //   onTap: () {
              //     Navigator.of(context).push(
              //       FantasyPageRoute(
              //         pageBuilder: (context) => AppDrawer(),
              //       ),
              //     );
              //   },
              //   child: ClipRRect(
              //     borderRadius: BorderRadius.circular(5.0),
              //     child: Container(
              //       color: Color.fromRGBO(242, 242, 242, 1),
              //       child: Image.asset(
              //         "images/person-icon.png",
              //         height: 40.0,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: getActivePage(),
        bottomNavigationBar: LobbyBottomNavigation(
          isIos,
          _onNavigationSelectionChange,
          activeIndex: _activeIndex,
        ),
      ),
    );
  }
}
