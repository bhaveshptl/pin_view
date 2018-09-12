import 'package:flutter/material.dart';

class TransactionFailed extends StatelessWidget {
  final Map<String, String> transactionResult;
  final Function _actionConfirm;
  final Function _actionReject;

  TransactionFailed(
      this.transactionResult, this._actionConfirm, this._actionReject);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: new Text("Your transaction of ₹" +
          transactionResult["amount"] +
          " has been failed !"),
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
          Container(            
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  new TextSpan(
                    text:
                        "(For future reference in case amount has been debited from account)",
                    style: new TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      actions: <Widget>[
        new FlatButton(
          child: Text("RETRY"),
          onPressed: () {
            this._actionConfirm();
          },
        ),
        new FlatButton(
          child: Text("CANCEL"),
          onPressed: () {
            this._actionReject();
          },
        ),
      ],
    );
  }
}
