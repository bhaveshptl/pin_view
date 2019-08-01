import 'dart:async';
import 'dart:convert';
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
  static const REQ_PING_PONG = 14;
  static const PREDICTION_DATA_UPDATE = 15;
  static const MY_SHEET_ADDED = 16;
}

class FantasyWebSocket {
  String _url;
  bool _isConnected = false;
  IOWebSocketChannel _channel;
  StreamController<dynamic> _streamController = StreamController.broadcast();

  FantasyWebSocket._internal();
  static final FantasyWebSocket socket = FantasyWebSocket._internal();
  factory FantasyWebSocket() => socket;

  int retryCount = 0;
  Timer _pingPongTimer;
  int reconnectSeconds = 1;
  bool bConnectionProcessInProgress = false;

  int iPingCount = 0;

  connect(String url) async {
    _url = url;
    bConnectionProcessInProgress = true;
    String futureCookie;

    if (SharedPrefHelper.wsCookie == null) {
      futureCookie = await SharedPrefHelper().getWSCookie();
    } else {
      futureCookie = SharedPrefHelper.wsCookie;
    }

    if (futureCookie != null) {
      _channel = null;
      iPingCount = 0;
      _channel = IOWebSocketChannel.connect(
        _url + futureCookie,
      );
      _isConnected = true;
      _startPingPong();
      _listenWSMsg();
    }
  }

  bool isConnected() {
    return _isConnected;
  }

  _listenWSMsg() async {
    if (_channel != null && _channel.stream != null) {
      _channel.changeStream((stream) {
        stream.listen(
          (onData) {
            var response = json.decode(onData);

            iPingCount = 0;
            if (response["iType"] != RequestType.REQ_PING_PONG) {
              _streamController.add(response);
            }
            bConnectionProcessInProgress = false;
          },
          onError: (error, StackTrace stackTrace) {
            Timer(Duration(seconds: 2), () {
              connect(this._url);
              bConnectionProcessInProgress = false;
            });
          },
          onDone: () {
            _isConnected = false;
            bConnectionProcessInProgress = false;
          },
        );
      });
    }
  }

  _startPingPong() {
    _pingPongTimer = Timer(Duration(seconds: 20), () {
      if (!bConnectionProcessInProgress) {
        iPingCount++;
        if (iPingCount > 3) {
          _isConnected = false;
          connect(_url);
        } else {
          this.sendMessage({"iType": RequestType.REQ_PING_PONG});
        }
      }
      _pingPongTimer.cancel();
      _startPingPong();
    });
  }

  stopPingPong() {
    _pingPongTimer.cancel();
    reset();
  }

  StreamController<dynamic> subscriber() {
    return _streamController;
  }

  sendMessage(Map<String, dynamic> msg) async {
    if (_channel != null && _isConnected) {
      _channel.sink.add(json.encode(msg));
    }
  }

  reset() {
    if (_channel != null && _channel.sink != null) {
      _channel.sink.close();
    }
  }
}
