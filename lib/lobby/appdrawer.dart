import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/modal/user.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/lobby/earncash.dart';
import 'package:playfantasy/lobby/withdraw.dart';
import 'package:playfantasy/utils/fantasywebsocket.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/profilepages/partner.dart';
import 'package:playfantasy/profilepages/contactus.dart';
import 'package:playfantasy/commonwidgets/update.dart';
import 'package:playfantasy/profilepages/myaccount.dart';
import 'package:playfantasy/profilepages/myprofile.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/profilepages/verification.dart';

class AppDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  User _user;
  String cookie;
  bool bIsUserVerified = false;

  @override
  void initState() {
    super.initState();

    getUserInfo();
    getTempUserObject();
  }

  getUserInfo() async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        BaseUrl.apiUrl + ApiUtil.AUTH_CHECK_URL,
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
    sockets.reset();
    http.Client().get(
      BaseUrl.apiUrl + ApiUtil.LOGOUT_URL,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {});
  }

  _onVerify() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Verification(),
      ),
    );
  }

  _onMyProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyProfile(),
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
        url =
            AppConfig.of(context).staticPageUrls["SCORING"] + "#ScoringSystem";
        break;
      case "HELP":
        title = "HELP";
        url = AppConfig.of(context).staticPageUrls["HOW_TO_PLAY"];
        break;
      case "FORUM":
        title = "FORUM";
        url = AppConfig.of(context).staticPageUrls["FORUM"];
        break;
      case "BLOG":
        title = "BLOG";
        url = AppConfig.of(context).staticPageUrls["BLOG"];
        break;
      case "T&C":
        title = "TERMS AND CONDITIONS";
        url = AppConfig.of(context).staticPageUrls["TERMS"];
        break;
      case "PRIVACY":
        title = "PRIVACY POLICY";
        url = AppConfig.of(context).staticPageUrls["PRIVACY"];
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => WebviewScaffold(
                url: url,
                clearCache: true,
                appBar: AppBar(
                  title: Text(title),
                ),
              ),
          fullscreenDialog: true),
    );
  }

  _showEarnCash() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EarnCash(),
        fullscreenDialog: true,
      ),
    );
    getUserInfo();
  }

  _showMyAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyAccount(),
      ),
    );
  }

  _showWithdraw() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Withdraw(),
      ),
    );
  }

  _showPartnerPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Partner(),
      ),
    );
  }

  _showContactUsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactUs(),
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

  _showUpdatingAppDialog(String url, bool bIsForceUpdate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadAPK(
          url: url,
          isForceUpdate: bIsForceUpdate,
        );
      },
      barrierDismissible: !bIsForceUpdate,
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
        "POST", Uri.parse(BaseUrl.apiUrl + ApiUtil.CHECK_APP_UPDATE));
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
    });
  }

  _launchAddCash() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCash(),
      ),
    );
    if (result != null) {
      await _showTransactionResult(json.decode(result));
      getUserInfo();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: <Widget>[
          !bIsUserVerified
              ? Container(
                  padding: EdgeInsets.all(12.0),
                  child: RaisedButton(
                    onPressed: () {
                      _onVerify();
                    },
                    padding: EdgeInsets.all(0.0),
                    color: Colors.white70,
                    child: Text(
                      "VERIFY",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
      body: Container(
        child: ListView(
          padding: EdgeInsets.all(8.0),
          children: <Widget>[
            Card(
              elevation: 3.0,
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
                            maxRadius: 32.0,
                            backgroundColor:
                                Theme.of(context).primaryColor.withAlpha(100),
                            child: Icon(
                              Icons.person,
                              size: 48.0,
                            ),
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
                                            .copyWith(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        "Tap to view details",
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .subhead
                                            .copyWith(
                                              color: Colors.black26,
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
            Card(
              elevation: 3.0,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(8.0),
                    color: Colors.black12.withAlpha(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Total balance",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .copyWith(
                                    color: Colors.black87,
                                  ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Only winnings balance is withdrawable",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .copyWith(
                                      color: Colors.blue,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          strings.rupee +
                              (_user == null
                                  ? "0.0"
                                  : (_user.withdrawable +
                                          _user.nonWithdrawable +
                                          _user.depositBucket)
                                      .toStringAsFixed(2)),
                          style: Theme.of(context)
                              .primaryTextTheme
                              .headline
                              .copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  "Deposits",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(color: Colors.black54),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    strings.rupee +
                                        (_user == null
                                            ? "0.0"
                                            : _user.depositBucket
                                                .toStringAsFixed(2)),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .subhead
                                        .copyWith(color: Colors.black87),
                                  ),
                                ),
                                RaisedButton(
                                  onPressed: () {
                                    _launchAddCash();
                                  },
                                  color: Colors.teal,
                                  child: Text(
                                    strings.get("ADD_CASH").toUpperCase(),
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text(
                                "Withdrawable",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .copyWith(color: Colors.black54),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  strings.rupee +
                                      (_user == null
                                          ? "0.0"
                                          : _user.withdrawable
                                              .toStringAsFixed(2)),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(color: Colors.black87),
                                ),
                              ),
                              RaisedButton(
                                onPressed: () {
                                  _showWithdraw();
                                },
                                color: Colors.red,
                                child: Text(
                                  "WITHDRAW".toUpperCase(),
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text(
                                "Bonus",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .copyWith(color: Colors.black54),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  strings.rupee +
                                      (_user == null
                                          ? "0.0"
                                          : _user.nonWithdrawable
                                              .toStringAsFixed(2)),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(color: Colors.black87),
                                ),
                              ),
                              RaisedButton(
                                onPressed: () {
                                  _showEarnCash();
                                },
                                color: Colors.orange,
                                child: Text(
                                  strings.get("EARN_CASH").toUpperCase(),
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.black12.withAlpha(10),
                    height: 32.0,
                    child: FlatButton(
                      padding: EdgeInsets.all(0.0),
                      onPressed: () {
                        _showMyAccount();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("View transactions".toUpperCase())
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Card(
              elevation: 3.0,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(8.0),
                    color: Colors.black12.withAlpha(10),
                    child: Row(
                      children: <Widget>[
                        Text(
                          "Help",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                  ListTile(
                    title: Text('How To Play'),
                    onTap: () {
                      Navigator.pop(context);
                      _launchStaticPage("HELP");
                    },
                  ),
                  Divider(height: 2.0),
                  ListTile(
                    title: Text('Scoring System'),
                    onTap: () {
                      Navigator.pop(context);
                      _launchStaticPage("SCORING");
                    },
                  ),
                  Divider(height: 2.0),
                  ListTile(
                    title: Text('Contact Us'),
                    onTap: () {
                      Navigator.pop(context);
                      _showContactUsPage();
                    },
                  ),
                ],
              ),
            ),
            Card(
              elevation: 3.0,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(8.0),
                    color: Colors.black12.withAlpha(10),
                    child: Row(
                      children: <Widget>[
                        Text(
                          "Others",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                  AppConfig.of(context).channelId == '9'
                      ? Container()
                      : ListTile(
                          title: Text('Become A Partner'),
                          onTap: () {
                            Navigator.pop(context);
                            _showPartnerPage();
                          },
                        ),
                  Divider(height: 2.0),
                  ListTile(
                    title: Text('Check For Update'),
                    onTap: () {
                      _performUpdateCheck();
                    },
                  ),
                  Divider(height: 2.0),
                  AppConfig.of(context).staticPageUrls["BLOG"] != null
                      ? Column(
                          children: <Widget>[
                            ListTile(
                              title: Text('Blog'),
                              onTap: () {
                                Navigator.pop(context);
                                _launchStaticPage("BLOG");
                              },
                            ),
                            Divider(height: 2.0),
                          ],
                        )
                      : Container(),
                  AppConfig.of(context).staticPageUrls["FORUM"] != null
                      ? Column(
                          children: <Widget>[
                            ListTile(
                              title: Text('Forum'),
                              onTap: () {
                                Navigator.pop(context);
                                _launchStaticPage("FORUM");
                              },
                            ),
                            Divider(height: 2.0),
                          ],
                        )
                      : Container(),
                  ListTile(
                    title: Text('Terms And Conditions'),
                    onTap: () {
                      Navigator.pop(context);
                      _launchStaticPage("T&C");
                    },
                  ),
                  Divider(height: 2.0),
                  ListTile(
                    title: Text('Privacy Policy'),
                    onTap: () {
                      Navigator.pop(context);
                      _launchStaticPage("PRIVACY");
                    },
                  ),
                  Divider(height: 2.0),
                  ListTile(
                    title: Text('Log Out'),
                    onTap: () async {
                      _doLogout();
                      SharedPrefHelper.internal().removeCookie();
                      Navigator.pop(context);
                      Navigator.of(context)
                          .pushReplacementNamed("/landingpage");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
