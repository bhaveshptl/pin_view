import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AuthCheck {
  AuthCheck();
  Future<bool> checkStatus(String apiUrl) async {
    http.Request req = http.Request(
      "GET",
      Uri.parse(
        apiUrl + ApiUtil.AUTH_CHECK_URL,
      ),
    );
    return HttpManager(http.Client())
        .sendRequest(req)
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        SharedPrefHelper.internal().saveToSharedPref(
            ApiUtil.SHARED_PREFERENCE_USER_KEY,
            json.encode(json.decode(res.body)["user"]));
        return true;
      } else {
        return false;
      }
    });
  }
}
