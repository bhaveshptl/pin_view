import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InitPay extends StatefulWidget {
  final String url;
  final bool waitForCookieset;
  final Function onTransactionComplete;
  InitPay({this.url, this.onTransactionComplete, this.waitForCookieset});

  @override
  InitPayState createState() => InitPayState();
}

class InitPayState extends State<InitPay> {
  String cookie = "";
  Map<String, String> depositResponse;
  WebViewController controller;
  CookieManager cookieManager;
  bool isIos = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      isIos = true;
    }
    setWebview();
  }

  setWebview() async {
    cookieManager = CookieManager();
    final result =
        await cookieManager.setCookie(BaseUrl().apiUrl, HttpManager.cookie);
    print(result);
  }

  setUrlChangeListener(String url) {
    Uri uri = Uri.dataFromString(url);
    print(uri.toString());
    if (uri.path.indexOf(ApiUtil.PAYMENT_SUCCESS) != -1 && uri.hasQuery) {
      if (depositResponse == null) {
        depositResponse = uri.queryParameters;
        Navigator.of(context).pop(json.encode(depositResponse));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        debuggingEnabled: true,
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController c) {
          controller = c;
        },
        onPageFinished: (String url) {
          setUrlChangeListener(url);
        },
      ),
    );
  }
}
