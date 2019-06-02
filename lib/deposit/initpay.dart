import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:io';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class InitPay extends StatefulWidget {
  final String url;
  final Function onTransactionComplete;
  InitPay({this.url, this.onTransactionComplete});

  @override
  InitPayState createState() => InitPayState();
}

class InitPayState extends State<InitPay> {
  String cookie = "";
  bool isWebviewLoaded = false;
  Map<String, String> depositResponse;
  final flutterWebviewPlugin = FlutterWebviewPlugin();
  bool isIos = false;

  @override
  void initState() {
    super.initState();
    setWebview();
    if (Platform.isIOS) {
      isIos = true;
    }
  }

  setWebview() async {
    flutterWebviewPlugin.onStateChanged.listen(
      (WebViewStateChanged state) {
        Uri uri = Uri.dataFromString(state.url);
        if (uri.path.indexOf(BaseUrl().apiUrl + ApiUtil.PAYMENT_SUCCESS) !=
                -1 &&
            uri.hasQuery) {
          if (depositResponse == null) {
            depositResponse = uri.queryParameters;
            flutterWebviewPlugin.close();
            Navigator.of(context).pop(json.encode(depositResponse));
          }
        }
      },
    );

    cookie = HttpManager.cookie;
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    if (isIos) {
      await flutterWebviewPlugin
          .evalJavascript("document.cookie='" + cookie + "'");
      Map<String, String> cookiesMap = await flutterWebviewPlugin.getCookies();
      if (cookiesMap["pids"].length > 0) {
        setState(() {
          isWebviewLoaded = true;
        });
      }
    } else {
      flutterWebviewPlugin.evalJavascript("document.cookie='" + cookie + "'");
      setState(() {
        isWebviewLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    flutterWebviewPlugin.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isWebviewLoaded
        ? WebviewScaffold(
            url: isIos ? Uri.encodeFull(widget.url) : widget.url,
            withJavascript: true,
            enableAppScheme: true,
            withLocalStorage: true,
          )
        : Scaffold(
            body: Center(
              child: Text("Loading..."),
            ),
          );
  }
}
