import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AuthResult {
  Response response;
  BuildContext context;
  Function setState;
  AuthResult(this.response, this.context, this.setState);

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
      if (res.statusCode == 200) {
        SharedPrefHelper()
            .saveWSCookieToStorage(json.decode(res.body)["cookie"]);
      }
    }).whenComplete(() {
      print("completed");
    });
  }

  processResult() async {
    if (response.statusCode == 200) {
      SharedPrefHelper.internal()
          .saveCookieToStorage(response.headers["set-cookie"]);
      SharedPrefHelper.internal().saveToSharedPref(
          ApiUtil.SHARED_REFERENCE_USER_KEY, json.encode(response.body));
      await setWSCookie();
      Navigator.of(context).pushReplacementNamed("/lobby");
    } else {
      final dynamic res = json.decode(response.body).cast<String, dynamic>();
      setState(() {
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text(res['error'])));
      });
    }
  }
}
