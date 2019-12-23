import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:playfantasy/commonwidgets/webview_scaffold.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:playfantasy/commonwidgets/leadingbutton.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class JoinContestConfirmation extends StatefulWidget {
  final int prizeType;
  final int entryFees;
  final int bonusAllowed;
  final Map<String, dynamic> userBalance;
  JoinContestConfirmation(
      {this.prizeType, this.entryFees, this.bonusAllowed, this.userBalance});

  @override
  JoinContestConfirmationState createState() => JoinContestConfirmationState();
}

class JoinContestConfirmationState extends State<JoinContestConfirmation> {
  TapGestureRecognizer termsGesture = TapGestureRecognizer();

  @override
  void initState() {
    termsGesture.onTap = () {
      _launchStaticPage("T&C");
    };
    super.initState();
  }

  _launchStaticPage(String name) {
    String url = "";
    String title = "";
    switch (name.toUpperCase()) {
      case "T&C":
        title = "TERMS AND CONDITIONS";
        url = BaseUrl().staticPageUrls["TERMS"];
        break;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebviewScaffold(
              url: url,
              appBar: AppBar(
                leading: LeadingButton(),
                title: Text(
                  title.toUpperCase(),
                ),
                titleSpacing: 0.0,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bonusUsable = widget.entryFees == null || widget.bonusAllowed == null
        ? 0.0
        : (widget.entryFees * widget.bonusAllowed) / 100;
    double usableBonus = widget.userBalance["bonusBalance"] > bonusUsable
        ? (bonusUsable > widget.userBalance["playableBonus"]
            ? widget.userBalance["playableBonus"]
            : bonusUsable)
        : widget.userBalance["bonusBalance"];

    final formatCurrency = NumberFormat.currency(
      locale: "hi_IN",
      symbol: widget.prizeType == 1 ? "" : strings.rupee,
      decimalDigits: 2,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      elevation: 0.0,
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              strings.get("CONFIRMATION").toUpperCase(),
              style: Theme.of(context).primaryTextTheme.headline.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.all(0.0),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Current Balance:",
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(widget.userBalance == null
                            ? 0
                            : widget.userBalance["cashBalance"]),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, left: 24.0, right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Bonus Balance:",
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(widget.userBalance == null
                            ? 0
                            : widget.userBalance["bonusBalance"]),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: Colors.black26,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Joining Amount:",
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(widget.entryFees),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Usable Bonus:",
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(usableBonus),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: Colors.black26,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Entry to be Paid:",
                    style: Theme.of(context).primaryTextTheme.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      (widget.prizeType == 1)
                          ? Image.asset(
                              strings.chips,
                              width: 16.0,
                              height: 12.0,
                              fit: BoxFit.contain,
                            )
                          : Container(),
                      Text(
                        formatCurrency.format(widget.entryFees - usableBonus),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style:
                            Theme.of(context).primaryTextTheme.caption.copyWith(
                                  color: Colors.black38,
                                  fontSize: 10.0,
                                ),
                        children: [
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "By joining this contest, you accept Howzat's",
                              ),
                              TextSpan(
                                text: " T&C ",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                                recognizer: termsGesture,
                              ),
                              TextSpan(
                                text:
                                    "and confirm that you are not a resident of Assam, Odisha, Telangana, Nagaland or Sikkim.",
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ColorButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "confirm": true,
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 20.0),
                      child: Text(
                        "Join now".toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .title
                            .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
