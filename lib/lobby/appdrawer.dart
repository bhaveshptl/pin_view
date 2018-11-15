import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/lobby/earncash.dart';

import 'package:playfantasy/modal/user.dart';
import 'package:playfantasy/profilepages/myaccount.dart';
import 'package:playfantasy/profilepages/myprofile.dart';
import 'package:playfantasy/profilepages/partner.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
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
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    http.Client().get(
      ApiUtil.AUTH_CHECK_URL,
      headers: {
        'Content-type': 'application/json',
        "cookie": cookie,
      },
    ).then((http.Response res) {
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

  @override
  Widget build(BuildContext context) {
    _doLogout() {
      new http.Client().get(
        ApiUtil.LOGOUT_URL,
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

    _onMyProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MyProfile(),
        ),
      );
    }

    _launchStaticPage(String name) {
      String url = "";
      String title = "";
      switch (name) {
        case "BECOME_PARTNER":
          url = "";
          title = "";
          break;
        case "SCORING":
          title = "SCORING SYSTEM";
          url = "https://www.playfantasy.com/assets/help.html?cache=" +
              DateTime.now().millisecondsSinceEpoch.toString() +
              "#ScoringSystem";
          break;
        case "HELP":
          title = "HELP";
          url = "https://www.playfantasy.com/assets/help.html?cache=" +
              DateTime.now().millisecondsSinceEpoch.toString();
          break;
        case "FORUM":
          title = "FORUM";
          url = "http://forum.playfantasy.com/?cache=" +
              DateTime.now().millisecondsSinceEpoch.toString();
          break;
        case "BLOG":
          title = "BLOG";
          url = "http://blog.playfantasy.com/?cache=" +
              DateTime.now().millisecondsSinceEpoch.toString();
          break;
        case "ABOUT_US":
          title = "ABOUT US";
          url = "https://www.playfantasy.com/assets/aboutus.html?cache=" +
              DateTime.now().millisecondsSinceEpoch.toString();
          break;
        case "T&C":
          title = "TERMS AND CONDITIONS";
          url = "https://www.playfantasy.com/assets/terms.html?cache=" +
              DateTime.now().millisecondsSinceEpoch.toString();
          break;
        case "PRIVACY":
          title = "PRIVACY POLICY";
          url =
              "https://www.playfantasy.com/assets/privacy_policy.html?cache=" +
                  DateTime.now().millisecondsSinceEpoch.toString();
          break;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => WebviewScaffold(
                  url: url,
                  appBar: AppBar(
                    title: Text(title),
                  ),
                ),
            fullscreenDialog: true),
      );
    }

    _showEarnCash() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EarnCash(),
          fullscreenDialog: true,
        ),
      );
    }

    _showMyAccount() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MyAccount(),
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

    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CircleAvatar(
                      maxRadius: 32.0,
                      backgroundColor: Colors.black12,
                      child: Icon(
                        Icons.person,
                        size: 48.0,
                      ),
                    ),
                    bIsUserVerified
                        ? Container()
                        : RaisedButton(
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              Navigator.pop(context);
                              _onVerify();
                            },
                            child: Text(
                              strings.get("VERIFY").toUpperCase(),
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        _user == null ? "" : _user.loginName,
                        style: TextStyle(
                            color: Theme.of(context).primaryColorLight),
                      ),
                      Text(
                        strings.rupee +
                            (_user == null
                                ? "0.0"
                                : (_user.withdrawable +
                                        _user.nonWithdrawable +
                                        _user.depositBucket)
                                    .toStringAsFixed(2)),
                        style: TextStyle(
                            color: Theme.of(context).primaryColorLight),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: <Widget>[
                      Text(
                        _user == null ? "" : _user.emailId,
                        style: TextStyle(
                            color: Theme.of(context).primaryColorLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          ListTile(
            title: Text('MY PROFILE'),
            onTap: () {
              Navigator.pop(context);
              _onMyProfile();
            },
          ),
          ListTile(
            title: Text('MY ACCOUNT'),
            onTap: () {
              Navigator.pop(context);
              _showMyAccount();
            },
          ),
          ListTile(
            title: Text('WITHDRAW CASH'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('ADD CASH'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('EARN CASH'),
            onTap: () {
              Navigator.pop(context);
              _showEarnCash();
            },
          ),
          ListTile(
            title: Text('BECOME A PARTNER'),
            onTap: () {
              Navigator.pop(context);
              _showPartnerPage();
            },
          ),
          ListTile(
            title: Text('SCORING SYSTEM'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("SCORING");
            },
          ),
          ListTile(
            title: Text('HELP'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("HELP");
            },
          ),
          ListTile(
            title: Text('SUPPORT'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('FORUM'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("FORUM");
            },
          ),
          ListTile(
            title: Text('BLOG'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("BLOG");
            },
          ),
          ListTile(
            title: Text('ABOUT US'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("ABOUT_US");
            },
          ),
          ListTile(
            title: Text('TERMS AND CONDITION'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("T&C");
            },
          ),
          ListTile(
            title: Text('PRIVACY POLICY'),
            onTap: () {
              Navigator.pop(context);
              _launchStaticPage("PRIVACY");
            },
          ),
          ListTile(
            title: Text('LOG OUT'),
            onTap: () async {
              _doLogout();
              Navigator.pop(context);
              SharedPrefHelper.internal().removeCookie();
              Navigator.of(context).pushReplacementNamed("/landingpage");
            },
          ),
        ],
      ),
    );
  }
}
