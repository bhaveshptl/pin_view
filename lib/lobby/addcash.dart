import 'package:flutter/material.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/commonwidgets/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';

bool bShowAppBar = true;
Map<String, String> depositResponse;

class AddCash extends StatefulWidget {  
  AddCash();

  @override
  State<StatefulWidget> createState() => AddCashState();
}

class AddCashState extends State<AddCash> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  setAppBarVisibility(bool bShow) {
    setState(() {
      bShowAppBar = bShow;
    });
  }

  _showTransactionResult(Map<String, String> transactionResult) {
    if (transactionResult["authStatus"] == "Authorised") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionSuccess(transactionResult, () {
            depositResponse = null;
            Navigator.of(context).pop();
            Navigator.of(context).pop(true);
          });
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionFailed(transactionResult, () {
            Navigator.of(context).pop();
            // _webView.show();
            setAppBarVisibility(true);
            // _webView.launch(ApiUtil.DEPOSIT_URL);
            depositResponse = null;
          }, () {
            depositResponse = null;
            Navigator.of(context).pop();
            Navigator.of(context).pop(false);
          });
        },
      );
    }
  }
}
