import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AuthCheck {
  AuthCheck();
  Future<bool> checkStatus() async {
    String cookie;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    return new http.Client().get(
      ApiUtil.AUTH_CHECK_URL,
      headers: {'Content-type': 'application/json', "cookie": cookie},
    ).then((http.Response res) {
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
