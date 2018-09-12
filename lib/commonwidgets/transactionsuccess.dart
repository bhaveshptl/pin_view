import 'package:flutter/material.dart';

class TransactionSuccess extends StatelessWidget {
  final Map<String, String> transactionResult;
  final Function _actionConfirm;

  TransactionSuccess(this.transactionResult, this._actionConfirm);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: new Text("Transaction Success!!"),
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
                    text: "Amount added ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: "₹" + transactionResult["amount"],
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
                    text: "Updated balance ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: "₹" +
                        (double.tryParse(transactionResult["withdrawable"]) +
                                double.tryParse(
                                    transactionResult["nonWithdrawable"]) +
                                double.tryParse(
                                    transactionResult["depositBucket"]))
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
                    text: "Order id ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: transactionResult["orderId"],
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
                    text: "Transaction date ",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  new TextSpan(
                    text: transactionResult["date"],
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
          child: Text("OK"),
          onPressed: () {
            this._actionConfirm();
          },
        ),
      ],
    );
  }
}
