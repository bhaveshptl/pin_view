import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/color_button.dart';
import 'package:playfantasy/utils/stringtable.dart';

class InsufficientFundDialog extends StatelessWidget {
  final int contestFee;
  final int userBalance;

  InsufficientFundDialog({this.contestFee, this.userBalance});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(0.0),
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
                  style: Theme.of(context).primaryTextTheme.display1.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.4,
                      ),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
              child: FittedBox(
                child: Text(
                  "Please deposit to join this contest.",
                  style: Theme.of(context).primaryTextTheme.title.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 56.0, right: 56.0, top: 24.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Text(
                    "Contest Fee",
                    style: Theme.of(context).primaryTextTheme.title.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                  ),
                ),
              ),
              Text(
                ":",
                style: Theme.of(context).primaryTextTheme.title.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                width: 60.0,
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
          padding: EdgeInsets.only(left: 56.0, right: 56.0, top: 8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "Available balance",
                  style: Theme.of(context).primaryTextTheme.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                ),
              ),
              Text(
                ":",
                style: Theme.of(context).primaryTextTheme.title.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                width: 60.0,
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
          padding: EdgeInsets.only(left: 56.0, right: 56.0, top: 8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "Sortage of balance",
                  style: Theme.of(context).primaryTextTheme.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                ),
              ),
              Text(
                ":",
                style: Theme.of(context).primaryTextTheme.title.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                width: 60.0,
                alignment: Alignment.centerRight,
                child: Text(
                  strings.rupee + (contestFee - userBalance).toString(),
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
          padding:
              EdgeInsets.only(top: 32.0, left: 32.0, right: 32.0, bottom: 24.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ColorButton(
                  padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: Text(
                    "DEPOSIT ${strings.rupee + (contestFee - userBalance).toString()} & JOIN",
                    style: Theme.of(context).primaryTextTheme.headline.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop({"launchJoinConfirmation": true});
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
