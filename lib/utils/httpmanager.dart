import 'package:http/http.dart' as http;
import 'package:playfantasy/utils/sharedprefhelper.dart';

class HttpManager extends http.BaseClient {
  static String cookie;
  static String channelId;
  final http.Client _inner;
  static String  appVersion;
  static bool isIos;

  HttpManager(this._inner);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers["cookie"] = cookie;
    request.headers['channelId'] = channelId;
    request.headers['Content-type'] = 'application/json';
    request.headers['appVersion'] = appVersion;
    request.headers['isIos'] = isIos.toString();


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
      var newCookie = onValue.headers["set-cookie"];
      if (newCookie != null && newCookie != "") {
        cookie = newCookie;
        SharedPrefHelper.internal().saveCookieToStorage(cookie);
      }
      return http.Response.fromStream(onValue);
    });
  }
}
