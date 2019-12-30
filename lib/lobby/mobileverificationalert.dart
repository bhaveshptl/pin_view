import 'package:flutter/material.dart';
import 'package:playfantasy/action_utils/action_util.dart';
import 'package:playfantasy/commonwidgets/customdialog.dart';
import 'package:playfantasy/lobby/mobileverification.dart';

class MobileVerificationAlert extends StatefulWidget {
  @override
  _MobileVerificationAlertState createState() =>
      _MobileVerificationAlertState();
}

class _MobileVerificationAlertState extends State<MobileVerificationAlert> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: CustomDialog(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        dialog: Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 16.0, left: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Verification".toUpperCase(),
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ],
                ),
              ),
              MobileVerification(
                onVerificationSuccess: () {
                  Navigator.of(context).pop();
                  ActionUtil()
                      .showMsgOnTop("Mobile verified successfully!", context);
                },
                onVerificationError: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
