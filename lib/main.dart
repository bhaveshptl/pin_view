import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/routes.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/landingpage/landingpage.dart';

AuthCheck authCheck = new AuthCheck();

///
/// Bootstraping APP.
///
void main() async {
  Widget _homePage = LandingPage();

  bool _result = await authCheck.checkStatus();
  if (_result) {
    _homePage = new Lobby();
  }

  FlutterWebviewPlugin()
      .launch("https://test.justkhel.com/lobby", hidden: true);

  runApp(
    new MaterialApp(home: _homePage, routes: new FantasyRoutes().getRoutes()),
  );
}
