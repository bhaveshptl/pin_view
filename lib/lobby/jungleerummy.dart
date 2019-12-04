import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class JungleeRummy extends StatefulWidget {
  @override
  _JungleeRummyState createState() => _JungleeRummyState();
}

class _JungleeRummyState extends State<JungleeRummy> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        WebviewScaffold(
          appBar: AppBar(
            elevation: 0.0,
          ),
          url: "https://m.jungleerummy.com/login",
          withJavascript: true,
          withLocalStorage: true,
          enableAppScheme: true,
          appCacheEnabled: true,
          userAgent:
              "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
        ),
      ],
    );
  }

  void dispose() {
    super.dispose();
  }
}
