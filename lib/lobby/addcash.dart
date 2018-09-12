import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/commonwidgets/transactionfailed.dart';
import 'package:playfantasy/commonwidgets/transactionsuccess.dart';

String cookie = "";
bool bShowAppBar = true;
Map<String, String> depositResponse;

class AddCash extends StatefulWidget {
  AddCash();

  @override
  State<StatefulWidget> createState() => AddCashState();
}

class AddCashState extends State<AddCash> {
  final webView = FlutterWebviewPlugin();

  @override
  void initState() {
    setWebviewCookie();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (cookie == null || cookie.length == 0) {
      return Container();
    } else {
      return getWebviewWidget(context);
    }
  }

  setWebviewCookie() async {
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      setState(() {
        cookie = value;
      });
    });
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
            Navigator.of(context).pop();
          });
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionFailed(transactionResult, () {
            Navigator.of(context).pop();
            webView.show();
            setAppBarVisibility(true);
            webView.launch("https://test.justkhel.com/deposit");
            depositResponse = null;
          }, () {
            depositResponse = null;
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
        },
      );
    }
  }

  getWebviewWidget(BuildContext context) {
    webView.evalJavascript("document.cookie='" + cookie + "'");

    webView.onStateChanged.listen(
      (WebViewStateChanged state) {
        Uri uri = Uri.dataFromString(state.url);
        if (uri.path.indexOf("https://test.justkhel.com/lobby") != -1 &&
            uri.hasQuery) {
          if (depositResponse == null) {
            depositResponse = uri.queryParameters;
            webView.close();
            _showTransactionResult(depositResponse);
          }
        }
        if (uri.path.indexOf("https://test.justkhel.com") != -1) {
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
            url: "https://test.justkhel.com/deposit",
            withJavascript: true,
            withLocalStorage: true,
            enableAppScheme: true,
          )
        : WebviewScaffold(
            url: "https://test.justkhel.com/deposit",
            withJavascript: true,
            withLocalStorage: true,
            enableAppScheme: true,
          );
  }
}
