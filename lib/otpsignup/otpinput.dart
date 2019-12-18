import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_view/pin_view.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';

class OtpInput extends StatefulWidget {
  final Function onResend;
  final Function onVerify;
  OtpInput({@required this.onResend, @required this.onVerify});

  @override
  _OtpInputState createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  Timer _timer;
  String _pin;
  int _currentTimeLapse = 30;

  @override
  void initState() {
    startTimer();
    super.initState();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_currentTimeLapse < 1) {
            timer.cancel();
          } else {
            _currentTimeLapse = _currentTimeLapse - 1;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      "Enter OTP",
                      style:
                          Theme.of(context).primaryTextTheme.subhead.copyWith(
                                color: Colors.grey.shade600,
                              ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PinView(
                      count: 6,
                      submit: (String pin) {
                        _pin = pin;
                        widget.onVerify(pin);
                      },
                      enabled: true,
                      autoFocusFirstField: true,
                      sms: SmsListener(
                        from: "AD-HOWZAT",
                        formatBody: (String body) {
                          widget.onVerify(body.substring(0, 6));
                          return body.substring(0, 6);
                        },
                      ),
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: ColorButton(
                      onPressed: () {
                        widget.onVerify(_pin);
                      },
                      child: Text(
                        "SUBMIT",
                        style:
                            Theme.of(context).primaryTextTheme.subhead.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
              _currentTimeLapse == 0
                  ? Container(
                      padding:
                          EdgeInsets.only(top: 24.0, left: 4.0, bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.0, vertical: 8.0),
                              child: Text(
                                "Resend",
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .title
                                    .copyWith(
                                      color: Colors.blue,
                                    ),
                              ),
                            ),
                            onTap: () {
                              _currentTimeLapse = 30;
                              widget.onResend();
                              startTimer();
                            },
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding:
                          EdgeInsets.only(top: 24.0, left: 4.0, bottom: 16.0),
                      child: Row(
                        children: <Widget>[
                          Text(
                            "Retry ",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          Text(
                            _currentTimeLapse.toString() + "S",
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(
                                  color: Colors.blue,
                                ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
