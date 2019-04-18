import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class WithdrawSuccess extends StatelessWidget {
  final Map<String, dynamic> withdrawResponse;

  WithdrawSuccess({this.withdrawResponse});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "WITHDRAWAL",
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.black,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "Your withdrawal has been received with withdrawal ID ",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .copyWith(
                                    color: Colors.black,
                                  ),
                            ),
                            TextSpan(
                              text: withdrawResponse["id"].toString() + ".",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .body1
                                  .copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
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
                padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "It will be processed after successful verification.",
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.black,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 48.0,
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: ColorButton(
                        child: Text(
                          "OK",
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
