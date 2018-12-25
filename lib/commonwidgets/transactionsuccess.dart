import 'package:flutter/material.dart';
import 'package:playfantasy/utils/stringtable.dart';

class TransactionSuccess extends StatelessWidget {
  final Map<String, dynamic> transactionResult;
  final Function _actionConfirm;

  TransactionSuccess(this.transactionResult, this._actionConfirm);

  @override
  Widget build(BuildContext context) {
    double withdrawable =
        double.tryParse(transactionResult["withdrawable"].toString());
    double nonWithdrawable =
        double.tryParse(transactionResult["nonWithdrawable"].toString());
    double depositBucket =
        double.tryParse(transactionResult["depositBucket"].toString());

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
      title: new Text(
        strings.get("TRANSACTION_SUCCESS"),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  new TextSpan(
                    text: strings.get("AMOUNT_ADDED") + " ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text:
                        strings.rupee + transactionResult["amount"].toString(),
                    style: new TextStyle(color: Colors.black54),
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
                  new TextSpan(
                    text: strings.get("UPDATED_BALANCE") + " ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: strings.rupee +
                        ((withdrawable != null ? withdrawable : 0.0) +
                                (nonWithdrawable != null
                                    ? nonWithdrawable
                                    : 0.0) +
                                (depositBucket != null ? depositBucket : 0.0))
                            .toStringAsFixed(2),
                    style: new TextStyle(color: Colors.black54),
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
                  new TextSpan(
                    text: strings.get("ORDER_ID") + " ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: transactionResult["orderId"].toString(),
                    style: new TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          new Container(
            padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  new TextSpan(
                    text: strings.get("TRANSACTION_DATE") + " ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: dateinString,
                    style: new TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        new FlatButton(
          child: Text(
            strings.get("OK").toUpperCase(),
          ),
          onPressed: () {
            this._actionConfirm();
          },
        ),
      ],
    );
  }
}
