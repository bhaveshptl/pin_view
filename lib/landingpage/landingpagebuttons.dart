import 'package:flutter/material.dart';

class LandingPageButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Container(
      padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 100.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new SizedBox(
            width: 150.0,
            child: new OutlineButton(
              textColor: Colors.white,
              child: new Text("SIGN UP"),
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(20.0)),
              highlightedBorderColor: Colors.transparent,
              splashColor: Theme.of(context).primaryColorDark,
              highlightColor: Theme.of(context).primaryColorDark,
              onPressed: () {
                Navigator.of(context).pushNamed("/signup");
              },
            ),
          ),
          new SizedBox(
            width: 150.0,
            child: new RaisedButton(
              child: new Text("SIGN IN"),
              textColor: Colors.black87,
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(20.0)),
              splashColor: Theme.of(context).primaryColorDark,
              highlightColor: Theme.of(context).primaryColorDark,
              onPressed: () {
                Navigator.of(context).pushNamed("/signin");
              },
            ),
          ),
        ],
      ),
    );
  }
}
