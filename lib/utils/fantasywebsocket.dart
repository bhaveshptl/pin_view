import 'dart:convert';

import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:web_socket_channel/io.dart';

class FantasyWebSocket {
  String url;
  static Function _onWSMsg;
  static IOWebSocketChannel _channel;

  FantasyWebSocket._internal();
  factory FantasyWebSocket() => FantasyWebSocket._internal();

  connect({url, onWSMsg}) async {
    url = url;
    _onWSMsg = onWSMsg;

    Future<dynamic> futureCookie = SharedPrefHelper.internal().getWSCookie();

    await futureCookie.then((value) {
      if (value != null) {
        _channel = IOWebSocketChannel.connect(url + value);
        _listenWSMsg();
      }
    });
  }

  _listenWSMsg() {
    if (_channel != null && _channel.stream != null) {
      _channel.stream.listen((onData) {
        onMsg(onData);
      });
    }
  }

  static onMsg(onData) {
    if (_onWSMsg != null) {
      _onWSMsg(onData);
    }
  }

  register(Function onWsMsg) {
    _onWSMsg = onWsMsg;
  }

  sendMessage(Map<String, dynamic> msg) {
    _channel.sink.add(json.encode(msg));
  }

  unRegister() {
    _onWSMsg = null;
  }
}
