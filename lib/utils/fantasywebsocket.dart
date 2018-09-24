import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:web_socket_channel/io.dart';

FantasyWebSocket sockets = new FantasyWebSocket();

class FantasyWebSocket {
  static IOWebSocketChannel _channel;
  static ObserverList<Function> _listeners = new ObserverList<Function>();

  FantasyWebSocket._internal();
  factory FantasyWebSocket() => FantasyWebSocket._internal();

  connect() async {
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getWSCookie();

    await futureCookie.then((value) {
      if (value != null) {
        _channel = IOWebSocketChannel.connect(ApiUtil.WEBSOCKET_URL + value);
        _listenWSMsg();
      }
    });
  }

  _listenWSMsg() {
    if (_channel != null && _channel.stream != null) {
      _channel.stream.listen(
        (onData) {
          onMsg(onData);
        },
        onError: (error, StackTrace stackTrace) {},
        onDone: () {
          print("object");
        },
      );
    }
  }

  static onMsg(onData) {
    if (_listeners != null) {
      for (Function callback in _listeners) {
        callback(onData);
      }
    }
  }

  register(Function onWsMsg) {
    _listeners.add(onWsMsg);
  }

  sendMessage(Map<String, dynamic> msg) async {
    if (_channel != null) {
      _channel.sink.add(json.encode(msg));
    }
  }

  unRegister(onWsMsg) {
    _listeners.remove(onWsMsg);
  }
}
