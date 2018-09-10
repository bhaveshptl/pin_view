import 'package:flutter/material.dart';
import 'package:playfantasy/landingpage/landingpagebuttons.dart';

class LandingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new Image(
            fit: BoxFit.fill,
            image: new AssetImage("images/landingPageBG.jpg"),
          ),
          new LandingPageButtons(),
        ],
      ),
    );
  }
}
