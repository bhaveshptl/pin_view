import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter/services.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/modal/user.dart';
import 'package:playfantasy/signin/signin.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/profilepages/update.dart';
import 'package:playfantasy/profilepages/partner.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/profilepages/contactus.dart';
import 'package:playfantasy/profilepages/myprofile.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/profilepages/verification.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/routelauncher.dart';
import 'package:playfantasy/redux/actions/loader_actions.dart';
import 'package:playfantasy/commonwidgets/fantasypageroute.dart';
import 'dart:io';

class AppDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  User _user;
  String cookie;
  bool bIsUserVerified = false;
  bool isIos = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MethodChannel browserLaunchChannel =
      const MethodChannel('com.algorin.pf.browser');
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');

  @override
  void initState() {
    super.initState();

    getUserInfo();
    getTempUserObject();
    if (Platform.isIOS) {
      isIos = true;
    }
  }

  getUserInfo() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl().apiUrl + ApiUtil.AUTH_CHECK_URL,
      ),
    );
    HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Map<String, dynamic> user = json.decode(res.body)["user"];
        SharedPrefHelper.internal().saveToSharedPref(
            ApiUtil.SHARED_PREFERENCE_USER_KEY, json.encode(user));
        setState(() {
          _user = User.fromJson(user);
        });
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  getTempUserObject() async {
    Future<dynamic> futureUserInfo = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_USER_KEY);
    futureUserInfo.then((value) {
      setState(() {
        _user = User.fromJson(json.decode(value));
        bIsUserVerified =
            _user.verificationStatus.addressVerification == "VERIFIED" &&
                _user.verificationStatus.panVerification == "VERIFIED" &&
                _user.verificationStatus.mobileVerification &&
                _user.verificationStatus.emailVerification;
      });
    });
  }

  _doLogout() {
    FantasyWebSocket().stopPingPong();
    http.Client().get(
      BaseUrl().apiUrl + ApiUtil.LOGOUT_URL,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
      print(res);
    });
    webEngageEventLogout();
  }

  Future<String> webEngageEventLogout() async {
    String result = "";
    Map<dynamic, dynamic> data = new Map();
    data["trackingType"] = "logout";
    data["value"] = "";
    try {
      result =
          await webengage_platform.invokeMethod('webengageTrackUser', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  _onVerify() {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => Verification(),
      ),
    );
  }

  _onMyProfile() async {
    await Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => MyProfile(),
      ),
    );
    getUserInfo();
  }

  _launchStaticPage(String name) {
    String url = "";
    String title = "";
    switch (name) {
      case "SCORING":
        title = "SCORING SYSTEM";
        if (!isIos) {
          url = BaseUrl().staticPageUrls["SCORING"] + "#ScoringSystem";
        } else {
          url = BaseUrl().staticPageUrls["SCORING"];
        }
        break;
      case "HELP":
        title = "HELP";
        url = BaseUrl().staticPageUrls["HOW_TO_PLAY"];
        break;
      case "FORUM":
        title = "FORUM";
        url = BaseUrl().staticPageUrls["FORUM"];
        break;
      case "BLOG":
        title = "BLOG";
        url = BaseUrl().staticPageUrls["BLOG"];
        break;
      case "T&C":
        title = "TERMS AND CONDITIONS";
        url = BaseUrl().staticPageUrls["TERMS"];
        break;
      case "PRIVACY":
        title = "PRIVACY POLICY";
        url = BaseUrl().staticPageUrls["PRIVACY"];
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebviewScaffold(
              url: isIos ? Uri.encodeFull(url) : url,
              clearCache: true,
              appBar: AppBar(
                title: Text(
                  title.toUpperCase(),
                ),
              ),
            ),
        fullscreenDialog: true,
      ),
    );
  }

  _showEarnCash() async {
    showLoader(true);
    routeLauncher.launchEarnCash(_scaffoldKey, onComplete: () {
      showLoader(false);
    });
  }

  _showMyAccount() {
    showLoader(true);
    routeLauncher.launchAccounts(_scaffoldKey, onComplete: () {
      showLoader(false);
    });
  }

  _launchWithdraw() async {
    showLoader(true);
    routeLauncher.launchWithdraw(_scaffoldKey, onComplete: () {
      showLoader(false);
    });
  }

  _showPartnerPage() {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => Partner(),
      ),
    );
  }

  _showContactUsPage() {
    Navigator.of(context).push(
      FantasyPageRoute(
        pageBuilder: (context) => ContactUs(),
        fullscreenDialog: true,
      ),
    );
  }

  _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircularProgressIndicator(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text("Checking for an update..."),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  _showUpdatingAppDialog(String url, bool bIsForceUpdate,
      {List<dynamic> logs}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          logs: logs,
          isForceUpdate: bIsForceUpdate,
        );
      },
      barrierDismissible: false,
    );
  }

  _showAppUptoDateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.update,
                    size: 48.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text("App is running on latest version"),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          actions: <Widget>[
            FlatButton(
              child: Text(strings.get("OK").toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _performUpdateCheck() async {
    _showUpdateDialog();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    http.Request req = http.Request(
        "POST", Uri.parse(BaseUrl().apiUrl + ApiUtil.CHECK_APP_UPDATE));
    req.body = json.encode({
      "version": double.parse(packageInfo.version),
      "channelId": AppConfig.of(context).channelId,
    });
    await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        Navigator.of(context).pop();
        Map<String, dynamic> response = json.decode(res.body);
        if (response["update"]) {
          _showUpdatingAppDialog(
              response["updateUrl"], response["isForceUpdate"]);
        } else {
          _showAppUptoDateDialog();
        }
      }
    }).whenComplete(() {
      showLoader(false);
    });
  }

  _launchAddCash() async {
    showLoader(true);
    routeLauncher.launchAddCash(context, onComplete: () {
      showLoader(false);
    });
  }

  showLoader(bool bShow) {
    AppConfig.of(context)
        .store
        .dispatch(bShow ? LoaderShowAction() : LoaderHideAction());
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: _scaffoldKey,
      child: ListView(
        children: <Widget>[
          PreferredSize(
            preferredSize: Size.fromHeight(0.0),
            child: Container(),
          ),
          Container(
            color: Colors.grey.shade300,
            child: FlatButton(
              padding: EdgeInsets.all(0.0),
              onPressed: () {
                _onMyProfile();
              },
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        CircleAvatar(
                          maxRadius: 28.0,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Image.asset("images/person-icon.png"),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(
                                      (_user == null ||
                                              (_user.emailId == null &&
                                                  _user.mobile == null &&
                                                  _user.loginName == null)
                                          ? ""
                                          : (_user.loginName != null
                                              ? _user.loginName
                                              : (_user.mobile == null
                                                  ? _user.emailId
                                                  : _user.mobile))),
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .title
                                          .copyWith(color: Colors.black),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      "Total Balance: " +
                                          (strings.rupee +
                                              (_user == null
                                                  ? "0.0"
                                                  : (_user.withdrawable +
                                                          _user
                                                              .nonWithdrawable +
                                                          _user.depositBucket)
                                                      .toStringAsFixed(2))),
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .subhead
                                          .copyWith(
                                            color: Colors.black,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              Icon(
                                Icons.chevron_right,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            onTap: () {
              _onVerify();
            },
            leading: Image.asset(
              "images/KYC.png",
              height: 24.0,
            ),
            title: Text("KYC"),
          ),
          Container(
            color: Color.fromRGBO(255, 246, 219, 1),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    ListTile(
                      leading: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Image.asset("images/junglee.png"),
                      ),
                      title: Text(
                        'Junglee Rummy',
                        style: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        "India's Most Trusted Rummy Site",
                        style:
                            Theme.of(context).primaryTextTheme.body1.copyWith(
                                  color: Colors.black,
                                ),
                      ),
                      onTap: () {
                        browserLaunchChannel.invokeMethod(
                            "launchInBrowser", "https://ei3k.app.link/howzat");
                      },
                    ),
                  ],
                ),
                Image.asset(
                  "images/new.png",
                  height: 64.0,
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () {
              _launchWithdraw();
            },
            leading: Icon(Icons.print),
            title: Text("WITHDRAWAL"),
          ),
          ListTile(
            onTap: () {
              _showMyAccount();
            },
            leading: Image.asset(
              "images/Bonus-gift.png",
              height: 24.0,
              color: Colors.grey.shade700,
            ),
            title: Text("BONUS SUMMARY"),
          ),
          Divider(
            color: Colors.grey.shade400,
            height: 1.0,
          ),
          ListTile(
            leading: Image.asset(
              "images/HowtoPlay.png",
              height: 24.0,
            ),
            title: Text('How To Play'.toUpperCase()),
            onTap: () {
              _launchStaticPage("HELP");
            },
          ),
          ListTile(
            leading: Image.asset(
              "images/Scoring.png",
              height: 24.0,
            ),
            title: Text('Scoring System'.toUpperCase()),
            onTap: () {
              _launchStaticPage("SCORING");
            },
          ),
          ListTile(
            leading: Image.asset(
              "images/Contact.png",
              height: 24.0,
            ),
            title: Text('Contact Us'.toUpperCase()),
            onTap: () {
              _showContactUsPage();
            },
          ),
          Divider(
            color: Colors.grey.shade400,
            height: 1.0,
          ),
          ListTile(
            leading: Image.asset(
              "images/TermsandCondition.png",
              height: 24.0,
            ),
            title: Text('Terms And Conditions'.toUpperCase()),
            onTap: () {
              _launchStaticPage("T&C");
            },
          ),
          ListTile(
            leading: Image.asset(
              "images/privacy.png",
              height: 24.0,
            ),
            title: Text('Privacy Policy'.toUpperCase()),
            onTap: () {
              _launchStaticPage("PRIVACY");
            },
          ),
          isIos
              ? Container()
              : ListTile(
                  leading: Image.asset(
                    "images/Update.png",
                    height: 24.0,
                  ),
                  title: Text('Check For Update'.toUpperCase()),
                  onTap: () {
                    _performUpdateCheck();
                  },
                ),
          ListTile(
            leading: Image.asset(
              "images/Logout.png",
              height: 24.0,
            ),
            title: Text('Log Out'.toUpperCase()),
            onTap: () async {
              _doLogout();
              HttpManager.cookie = null;
              SharedPrefHelper.internal().removeCookie();
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                FantasyPageRoute(
                  pageBuilder: (context) => SignInPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
