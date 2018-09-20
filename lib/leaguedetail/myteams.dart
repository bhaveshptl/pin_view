import 'package:flutter/material.dart';

class MyTeams extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyTeamsState();
}

class MyTeamsState extends State<MyTeams> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My teams"),
      ),
    );
  }
}
