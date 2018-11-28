import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

import 'package:playfantasy/utils/sharedprefhelper.dart';

FantasyWebSocket sockets = new FantasyWebSocket();

class RequestType {
  RequestType._internal();

  factory RequestType() => RequestType._internal();

  static const GET_ALL_SERIES = 1;
  static const LOBBY_REFRESH_DATA = 2;
  static const GET_L1_DATA = 3;
  static const L1_DATA_REFRESHED = 4;
  static const GET_ALL_L1 = 5;
  static const JOIN_COUNT_CHNAGE = 6;
  static const MY_TEAMS_ADDED = 7;
  static const MY_TEAM_MODIFIED = 8;
  static const REQ_REG_DEREG_MY_CONTEST = 9;
  static const REQ_L1_INNINGS_ALL_DATA = 10;
  static const REQ_L1_INNINGS_DATA = 11;
}

class FantasyWebSocket {
  String _url;
  static bool _isConnected = false;
  static IOWebSocketChannel _channel;
  static ObserverList<Function> _listeners = new ObserverList<Function>();

  FantasyWebSocket._internal();
  factory FantasyWebSocket() => FantasyWebSocket._internal();

  connect(String url) async {
    _url = url;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getWSCookie();

    await futureCookie.then((value) {
      if (value != null) {
        _channel = IOWebSocketChannel.connect(
          _url + value,
        );
        _isConnected = true;
        _listenWSMsg();
      }
    });
  }

  bool isConnected() {
    return _isConnected;
  }

  _listenWSMsg() {
    if (_channel != null && _channel.stream != null) {
      _channel.stream.listen(
        (onData) {
          onMsg(onData);
        },
        onError: (error, StackTrace stackTrace) {
          connect(this._url);
        },
        onDone: () {
          _isConnected = false;
          // _channel.sink.close();
          // connect(this._url);
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

  reset() {
    if (_channel != null && _channel.sink != null) {
      _channel.sink.close();
    }
    _listeners = ObserverList<Function>();
  }
}
