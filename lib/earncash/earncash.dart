import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share_me/flutter_share_me.dart';

import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

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
  String inviteMsg = "";
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  static const _kFontFam = 'MyFlutterApp';
  static const IconData gplus_squared =
      const IconData(0xf0d4, fontFamily: _kFontFam);
  static const IconData facebook_squared =
      const IconData(0xf308, fontFamily: _kFontFam);

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
    inviteMsg =
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
    FlutterShareMe().shareToSystem(msg: inviteMsg);
  }

  _shareNowWhatsApp() {
    inviteMsg =
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
    FlutterShareMe().shareToWhatsApp(msg: inviteMsg);
  }

  _shareNowFacebook() {
    inviteMsg =
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
    FlutterShareMe().shareToFacebook(msg: inviteMsg);
  }

  _shareNowGmail() {
    inviteMsg =
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
    FlutterShareMe().shareToSystem(msg: inviteMsg);
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration iconDecoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        width: 1.0,
        color: Colors.black26,
      ),
    );

    return ScaffoldPage(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Refer & Earn".toUpperCase(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Image.asset("images/referal.png"),
          Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    "Invite your friends and play Howzat",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.headline.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    ("For every friends that plays, you both will earn " +
                        strings.rupee +
                        refAAmount.toString()),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.caption.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Card(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  "Send your referral code",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .caption
                                      .copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                refCode,
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w800,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 32.0, right: 32.0, bottom: 16.0, top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                width: 56.0,
                                height: 56.0,
                                decoration: iconDecoration,
                                child: InkWell(
                                  onTap: () {
                                    _shareNowWhatsApp();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      "images/watsapp.png",
                                      height: 32.0,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 56.0,
                                height: 56.0,
                                decoration: iconDecoration,
                                child: InkWell(
                                  onTap: () {
                                    _shareNowFacebook();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      "images/facebook.png",
                                      height: 32.0,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 56.0,
                                height: 56.0,
                                decoration: iconDecoration,
                                child: InkWell(
                                  onTap: () {
                                    _shareNowGmail();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      "images/gmail.png",
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 56.0,
                                height: 56.0,
                                decoration: iconDecoration,
                                child: InkWell(
                                  onTap: () {
                                    _copyCode();
                                  },
                                  child: Icon(
                                    Icons.content_copy,
                                    size: 32.0,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 32.0, right: 32.0, bottom: 16.0, top: 16.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  height: 56.0,
                                  child: ColorButton(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            Icons.share,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Share".toUpperCase(),
                                          style: Theme.of(context)
                                              .primaryTextTheme
                                              .headline
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                    elevation: 0.0,
                                    onPressed: () {
                                      _shareNow();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "Terms and Conditions",
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "You need to verify your mobile Number.",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body2
                                    .copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Share your invite code with your friends.",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body2
                                    .copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Your friends should also verify their mobile number.",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .body2
                                    .copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
