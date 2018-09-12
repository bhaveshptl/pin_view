import 'package:flutter/material.dart';

import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/signin/signin.dart';
import 'package:playfantasy/signup/signup.dart';
import 'package:playfantasy/lobby/addcash.dart';
import 'package:playfantasy/landingpage/landingpage.dart';

class FantasyRoutes {
  getRoutes() {
    return {
      // Set routes for using the Navigator.
      '/landingpage': (BuildContext context) => new LandingPage(),
      '/signin': (BuildContext context) => new Signin(),
      '/signup': (BuildContext context) => new Signup(),
      '/lobby': (BuildContext context) => new Lobby(),
      '/deposit': (BuildContext context) => new AddCash(),
    };
  }
}
