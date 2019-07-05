import 'package:flutter/material.dart';
import 'package:playfantasy/commonwidgets/scaffoldpage.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewScaffold extends StatelessWidget {
  final String url;
  final AppBar appBar;

  WebviewScaffold({this.url, this.appBar});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      appBar: appBar,
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        debuggingEnabled: false,
      ),
    );
  }
}
