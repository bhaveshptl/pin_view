import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SignupState();
}

class SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SIGN UP"),
      ),
      body: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new Image(
            fit: BoxFit.fill,
            color: Colors.black45,
            colorBlendMode: BlendMode.darken,
            image: new AssetImage("images/landingPageBG.jpg"),
          )
        ],
      ),
    );
  }
}
