import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/routes.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/landingpage/landingpage.dart';

AuthCheck authCheck = new AuthCheck();

setWSCookie() async {
  String cookie;
  Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
  await futureCookie.then((value) {
    cookie = value;
  });

  return new http.Client()
      .post(ApiUtil.GET_COOKIE_URL,
          headers: {'Content-type': 'application/json', "cookie": cookie},
          body: json.encoder.convert({}))
      .then((http.Response res) {
    if (res.statusCode == 200) {
      SharedPrefHelper().saveWSCookieToStorage(json.decode(res.body)["cookie"]);
    }
  }).whenComplete(() {
    print("completed");
  });
}

///
/// Bootstraping APP.
///
void main() async {
  Widget _homePage = LandingPage();

  bool _result = await authCheck.checkStatus();
  if (_result) {
    await setWSCookie();
    _homePage = new Lobby();
  }

  FlutterWebviewPlugin()
      .launch("https://test.justkhel.com/lobby", hidden: true);

  runApp(
    new MaterialApp(
      home: _homePage,
      routes: new FantasyRoutes().getRoutes(),
      // theme: new ThemeData(brightness: Brightness.dark),
    ),
  );
}
