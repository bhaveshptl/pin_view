import 'package:flutter/material.dart';
import 'package:playfantasy/landingpage/landingpage.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/routes.dart';
import 'package:playfantasy/utils/authcheck.dart';

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

  runApp(
    new MaterialApp(home: _homePage, routes: new FantasyRoutes().getRoutes()),
  );
}
