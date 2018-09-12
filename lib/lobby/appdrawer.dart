import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/modal/user.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AppDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  User user;
  @override
  Widget build(BuildContext context) {
    String userInfo;
    String cookie;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    futureCookie.then((value) {
      cookie = value;
    });

    Future<dynamic> futureUserInfo = SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_REFERENCE_USER_KEY);
    futureUserInfo.then((value) {
      userInfo = json.decode(value);
      setState(() {
        user = User.fromJson(json.decode(userInfo));
      });
    });

    doLogout() {
      new http.Client().get(
        ApiUtil.LOGOUT_URL,
        headers: {'Content-type': 'application/json', "cookie": cookie},
      ).then((http.Response res) {
        print(res.body);
      });
    }

    return Drawer(
      child: ListView(
        children: <Widget>[
          new DrawerHeader(
            child: new Center(
                child: Text(
              user == null ? "" : user.loginName,
              style: TextStyle(color: Theme.of(context).primaryColorLight),
            )),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          ListTile(
            title: Text('MY PROFILE'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('MY ACCOUNT'),
            onTap: () {
              Navigator.pop(context);
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
            },
          ),
          ListTile(
            title: Text('BECOME A PARTNER'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('SCORING SYSTEM'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('HELP'),
            onTap: () {
              Navigator.pop(context);
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
            },
          ),
          ListTile(
            title: Text('BLOG'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('ABOUT US'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('TERMS AND CONDITION'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('PRIVACY POLICY'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('LOG OUT'),
            onTap: () async {
              doLogout();
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
