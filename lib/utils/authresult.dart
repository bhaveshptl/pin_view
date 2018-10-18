import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AuthResult {
  Response response;
  GlobalKey<ScaffoldState> scaffoldKey;
  AuthResult(this.response, this.scaffoldKey);

  setWSCookie() async {
    String cookie;
    Future<dynamic> futureCookie = SharedPrefHelper.internal().getCookie();
    await futureCookie.then((value) {
      cookie = value;
    });

    return new http.Client()
        .post(ApiUtil.GET_COOKIE_URL,
            headers: {'Content-type': 'application/json', "cookie": cookie},
            body: json.encoder.convert({}))
        .then((http.Response res) {
      if (res.statusCode >= 200 && res.statusCode <= 299) {
        SharedPrefHelper()
            .saveWSCookieToStorage(json.decode(res.body)["cookie"]);
      }
    });
  }

  processResult(Function done) async {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      SharedPrefHelper.internal()
          .saveCookieToStorage(response.headers["set-cookie"]);
      SharedPrefHelper.internal().saveToSharedPref(
          ApiUtil.SHARED_PREFERENCE_USER_KEY, json.encode(response.body));
      await setWSCookie();
      Navigator.of(scaffoldKey.currentContext).pushReplacementNamed("/lobby");
      done();
    }
  }
}
