import 'package:share/share.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/utils/stringtable.dart';

class EarnCash extends StatefulWidget {
  final Map<String, dynamic> data;

  EarnCash({this.data});

  @override
  EarnCashState createState() {
    return new EarnCashState();
  }
}

class EarnCashState extends State<EarnCash> {
  int refAAmount = 0;
  int refBAmount = 0;
  String cookie = "";
  String refCode = "";
  String inviteUrl = "";
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    setReferralDetails();
  }

  setReferralDetails() async {
    refCode = widget.data["refCode"];
    refAAmount = widget.data["amountUserA"];
    refBAmount = widget.data["amountUserB"];
    inviteUrl = (widget.data["refLink"] as String).replaceAll("%3d", "=");
  }

  _copyCode() {
    Clipboard.setData(
      ClipboardData(text: refCode),
    );
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          strings.get("COPIED"),
        ),
      ),
    );
  }

  _shareNow() {
    String inviteMsg =
        "I'm having super fun playing Fantasy sports daily. Join me at " +
            AppConfig.of(context).appName +
            " and win cash prizes in every match. Take this bonus of " +
            strings.rupee +
            refBAmount.toString() +
            " and join me at " +
            AppConfig.of(context).appName +
            ". " +
            "Click " +
            inviteUrl +
            " to download " +
            AppConfig.of(context).appName +
            " app and use my code " +
            refCode +
            " to register.";
    Share.share(inviteMsg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(strings.get("EARN_CASH_TITLE")),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    strings.get("EARN_RS") + refAAmount.toString(),
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).primaryTextTheme.display1.fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    "- As a first thing you need to verify your Mobile.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .subhead
                            .fontSize),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(
                    "- Share you invite code with your friends.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .subhead
                            .fontSize),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(
                    "- Make sure your friend also verifies his Mobile.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .subhead
                            .fontSize),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(
                    "- You gets " +
                        strings.rupee +
                        refAAmount.toString() +
                        " and your friend gets " +
                        strings.rupee +
                        refBAmount.toString() +
                        " as soon as your friend verifies his/her mobile number.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: Theme.of(context)
                            .primaryTextTheme
                            .subhead
                            .fontSize),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          strings.get("REFERRAL_CODE"),
                          style: TextStyle(
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .fontSize,
                            color: Colors.green,
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          refCode,
                          style: TextStyle(
                            fontSize: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    _copyCode();
                  },
                  color: Colors.orange,
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.content_copy,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        strings.get("COPY_CODE").toUpperCase(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: () {
                    _shareNow();
                  },
                  color: Colors.green,
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.share, color: Colors.white70),
                      ),
                      Text(
                        strings.get("SHARE_NOW").toUpperCase(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
