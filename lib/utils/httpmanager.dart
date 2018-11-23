import 'package:http/http.dart' as http;
import 'package:playfantasy/utils/sharedprefhelper.dart';

class HttpManager extends http.BaseClient {
  String cookie;
  final http.Client _inner;
  static String channelId;

  HttpManager(this._inner);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers["cookie"] = cookie;
    request.headers['channelId'] = channelId;
    request.headers['Content-type'] = 'application/json';

    return _inner.send(request);
  }

  Future<http.Response> sendRequest(http.BaseRequest request) async {
    if (cookie == null || cookie == "") {
      Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
      await futureCookie.then((value) {
        cookie = value;
      });
    }

    return await send(request).then((onValue) {
      return http.Response.fromStream(onValue);
    });
  }
}
