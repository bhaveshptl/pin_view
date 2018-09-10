import 'package:flutter/material.dart';
import 'package:playfantasy/lobby/appdrawer.dart';

class Lobby extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("LOBBY"),
      ),
      drawer: AppDrawer(),
      body: Container(
        child: new Center(
          child: Text("Lobby"),
        ),
      ),
    );
  }
}
