import 'package:flutter/material.dart';

///
/// Bootstraping APP.
///
void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Hello PlayFantasy!!"),
        ),
      ),
    );
  }
}
