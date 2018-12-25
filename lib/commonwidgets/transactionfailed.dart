import 'package:flutter/material.dart';

import 'package:playfantasy/utils/stringtable.dart';

class TransactionFailed extends StatelessWidget {
  final Map<String, dynamic> transactionResult;
  final Function _actionConfirm;
  final Function _actionReject;

  TransactionFailed(
      this.transactionResult, this._actionConfirm, this._actionReject);

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        int.parse(transactionResult["date"].toString()));
    String dateinString = date.day.toString() +
        "-" +
        date.month.toString() +
        "-" +
        date.year.toString() +
        " " +
        date.hour.toString() +
        ":" +
        date.minute.toString() +
        ":" +
        date.second.toString();
    return AlertDialog(
      title: Text(strings
          .get("TRANSACTION_FAILED")
          .replaceAll("\$amount", transactionResult["amount"].toString())),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: strings.get("TRANSACTION_DATE"),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextSpan(
                    text: dateinString,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: strings.get("ORDER_ID") + " ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextSpan(
                    text: transactionResult["orderId"].toString(),
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Container(
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: strings.get("FUTURE_REFERENCE"),
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(
            strings.get("RETRY").toUpperCase(),
          ),
          onPressed: () {
            this._actionConfirm();
          },
        ),
        FlatButton(
          child: Text(
            strings.get("CANCEL").toUpperCase(),
          ),
          onPressed: () {
            this._actionReject();
          },
        ),
      ],
    );
  }
}
