import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

import 'package:playfantasy/utils/stringtable.dart';

class EarnCash extends StatefulWidget {
  @override
  EarnCashState createState() {
    return new EarnCashState();
  }
}

class EarnCashState extends State<EarnCash> {
  int refAmount = 0;
  String cookie = "";
  String refCode = "";
  String inviteUrl = "";
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getReferralCode();
  }

  getReferralCode() async {
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    await http.Client().get(
      ApiUtil.GET_REFERRAL_CODE,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then(
      (http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          Map<String, dynamic> response = json.decode(res.body);
          setState(() {
            refCode = response["refCode"];
            inviteUrl =
                (response["inviteUrl"] as String).replaceAll("%3d", "=");
            refAmount = response["refAmount"];
          });
        }
      },
    );
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
        "I'm having super fun playing Fantasy sports daily. Join me at PLAY FANTASY and win cash prizes in every match. Take this bonus of " +
            refAmount.toString() +
            "and join me at PLAY FANTASY. " +
            "Click " +
            inviteUrl +
            " to download PLAY FANTASY app and use my code " +
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
                    strings.get("EARN_RS") + refAmount.toString(),
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
                    "- " + strings.get("VERIFY_EMAIL_MOBILE"),
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
                    "- " + strings.get("FRIEND_MOBILE_VERIFIED"),
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
                    "- " +
                        strings.get("USER_GETS_BONUS_TEXT_1") +
                        refAmount.toString() +
                        " " +
                        strings.get("USER_GETS_BONUS_TEXT_2"),
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
                    "- " +
                        strings.get("FRIEND_SIGNUP_TEXT") +
                        refAmount.toString(),
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
