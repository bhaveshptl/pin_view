import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/commonwidgets/customdialog.dart';
import 'package:playfantasy/utils/stringtable.dart';

class InsufficientFundDialog extends StatelessWidget {
  final int contestFee;
  final int userBalance;

  InsufficientFundDialog({this.contestFee, this.userBalance});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      dialog: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: Container()),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.orange,
                        size: 72.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.all(0.0),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: FittedBox(
                    child: Text(
                      "Insufficient Balance",
                      style:
                          Theme.of(context).primaryTextTheme.headline.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Please deposit to join this contest.",
                        style: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 42.0, right: 56.0, top: 24.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: 24.0,
                      ),
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        child: Text(
                          "Contest Fee",
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      ":",
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    width: 56.0,
                    alignment: Alignment.centerRight,
                    child: Text(
                      strings.rupee + contestFee.toString(),
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 42.0, right: 56.0, top: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      constraints: BoxConstraints(
                        maxHeight: 20.0,
                      ),
                      child: FittedBox(
                        child: Text(
                          "Available balance",
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade800,
                                  ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      ":",
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    width: 56.0,
                    alignment: Alignment.centerRight,
                    child: Text(
                      strings.rupee + userBalance.toString(),
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Container(
                        height: 0.5,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 42.0, right: 56.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      constraints: BoxConstraints(
                        maxHeight: 20.0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Shortage of balance",
                          style:
                              Theme.of(context).primaryTextTheme.title.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade800,
                                  ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      ":",
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    width: 56.0,
                    alignment: Alignment.centerRight,
                    child: Text(
                      strings.rupee + (contestFee - userBalance).toString(),
                      style: Theme.of(context).primaryTextTheme.title.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: 32.0, left: 40.0, right: 40.0, bottom: 24.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ColorButton(
                      padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                      child: Text(
                        "DEPOSIT ${strings.rupee + (contestFee - userBalance).toString()} & JOIN",
                        style: Theme.of(context)
                            .primaryTextTheme
                            .title
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onPressed: () {
                        Navigator.of(context)
                            .pop({"launchJoinConfirmation": true});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
