import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';

import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';

class AuthResult {
  Response response;
  BuildContext context;
  Function setState;
  AuthResult(this.response, this.context, this.setState);

  processResult() {
    if (response.statusCode == 200) {
      SharedPrefHelper.internal()
          .saveCookieToStorage(response.headers["set-cookie"]);
      SharedPrefHelper.internal().saveToSharedPref(
          ApiUtil.SHARED_REFERENCE_USER_KEY, json.encode(response.body));

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
