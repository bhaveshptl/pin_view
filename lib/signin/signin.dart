import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:playfantasy/signin/siginform.dart';

class Signin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SigninState();
}

class SigninState extends State<Signin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SIGN IN"),
      ),
      body: new Container(
        decoration: new BoxDecoration(
          image: new DecorationImage(
              image: new AssetImage("images/landingPageBG.jpg"),
              fit: BoxFit.cover),
        ),
        child: new Center(
          child: new ClipRect(
            child: new BackdropFilter(
              filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: new Container(
                child: SigninForm(),
                height: 340.0,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.circular(10.0),                    
                    color: Colors.grey.shade200.withOpacity(0.5)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
