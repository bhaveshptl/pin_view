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
        body: Center(
          child: Text("COMING SOON"),
        ));
  }
}
