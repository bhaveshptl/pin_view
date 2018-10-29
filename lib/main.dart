import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/routes.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/landingpage/landingpage.dart';

String cookie;
AuthCheck authCheck = new AuthCheck();

setWSCookie() async {
  Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
  await futureCookie.then((value) {
    cookie = value;
  });

  return new http.Client()
      .post(ApiUtil.GET_COOKIE_URL,
          headers: {'Content-type': 'application/json', "cookie": cookie},
          body: json.encoder.convert({}))
      .then((http.Response res) {
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      SharedPrefHelper().saveWSCookieToStorage(json.decode(res.body)["cookie"]);
    }
  });
}

updateStringTable() async {
  String table;
  await SharedPrefHelper().getLanguageTable().then((value) {
    table = value;
  });

  Map<String, dynamic> stringTable = json.decode(table == null ? "{}" : table);

  await http.Client()
      .post(
    ApiUtil.UPDATE_LANGUAGE_TABLE,
    headers: {'Content-type': 'application/json', "cookie": cookie},
    body: json.encode({
      "version": stringTable["version"],
      "language": 1,
    }),
  )
      .then((http.Response res) {
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      Map<String, dynamic> response = json.decode(res.body);
      if (response["update"]) {
        strings.set(
          language: response["language"],
          table: response["table"],
        );
        SharedPrefHelper().saveLanguageTable(
            version: response["version"],
            lang: response["language"],
            table: response["table"]);
      } else {
        strings.set(
          language: stringTable["language"],
          table: stringTable["table"],
        );
      }
    }
  });
}

///
/// Bootstraping APP.
///
void main() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Widget _homePage = LandingPage();

  bool _result = await authCheck.checkStatus();
  if (_result) {
    await setWSCookie();
    _homePage = new Lobby();
  }
  await updateStringTable();

  // FlutterWebviewPlugin().launch(ApiUtil.BASE_URL, hidden: true);

  runApp(
    new MaterialApp(
      home: _homePage,
      routes: new FantasyRoutes().getRoutes(),
      // theme: new ThemeData(brightness: Brightness.dark),
    ),
  );
}
