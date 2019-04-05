import 'package:flutter/material.dart';

import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/signin/signin.dart';
import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/lobby/addcash.dart';

class FantasyRoutes {
  getRoutes() {
    return {
      // Set routes for using the Navigator.
      '/landingpage': (BuildContext context) => new SignInPage(),
      '/signup': (BuildContext context) => new Signup(),
      '/lobby': (BuildContext context) => new Lobby(),
      '/deposit': (BuildContext context) => new AddCash(),
    };
  }
}
