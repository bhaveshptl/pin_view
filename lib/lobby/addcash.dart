import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/commonwidgets/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';

bool bShowAppBar = true;
Map<String, String> depositResponse;

class AddCash extends StatefulWidget {
  final String cookie;
  AddCash({this.cookie});

  @override
  State<StatefulWidget> createState() => AddCashState();
}

class AddCashState extends State<AddCash> {
  final _webView = FlutterWebviewPlugin();

  @override
  void initState() {
    setWebviewCookie();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cookie == null || widget.cookie.length == 0) {
      return Container();
    } else {
      return getWebviewWidget(context);
    }
  }

  setWebviewCookie() {
    _webView.evalJavascript("document.cookie='" + widget.cookie + "'");
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
            _webView.show();
            setAppBarVisibility(true);
            _webView.launch(ApiUtil.DEPOSIT_URL);
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

  getWebviewWidget(BuildContext context) {
    _webView.onStateChanged.listen(
      (WebViewStateChanged state) {
        Uri uri = Uri.dataFromString(state.url);
        if (uri.path.indexOf(ApiUtil.PAYMENT_BASE_URL + "/lobby") != -1 &&
            uri.hasQuery) {
          if (depositResponse == null) {
            depositResponse = uri.queryParameters;
            _webView.close();
            _showTransactionResult(depositResponse);
          }
        }
        if (uri.path.indexOf(ApiUtil.PAYMENT_BASE_URL) != -1) {
          setAppBarVisibility(true);
        } else {
          setAppBarVisibility(false);
        }
      },
    );

    return bShowAppBar
        ? WebviewScaffold(
            appBar: AppBar(
              title: Text("Add Cash"),
            ),
            url: ApiUtil.DEPOSIT_URL,
            withJavascript: true,
            withLocalStorage: true,
            enableAppScheme: true,
          )
        : WebviewScaffold(
            url: ApiUtil.DEPOSIT_URL,
            withJavascript: true,
            withLocalStorage: true,
            enableAppScheme: true,
          );
  }
}
