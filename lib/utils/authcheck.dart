import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/providers/user.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:provider/provider.dart';

class AuthCheck {
  AuthCheck();
  Future<bool> checkStatus(BuildContext context, String apiUrl) async {
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
        Map<String, dynamic> userData = json.decode(res.body)["user"];
        SharedPrefHelper.internal().saveToSharedPref(
            ApiUtil.SHARED_PREFERENCE_USER_KEY, json.encode(userData));
        var userProvider = Provider.of<User>(context, listen: false);
        userProvider.setUserFromJson(userData);
        Map<String, dynamic> refreshdata = userData;

        AnalyticsManager().setUser(userData);
        setWebEngageKeys(userData);
        print("###########Refresh UserData#############");
        print(userData);

        return true;
      } else {
        return false;
      }
    });
  }

  setWebEngageKeys(Map<String, dynamic> data) {
    if (data["user_id"] != null) {
      Map<dynamic, dynamic> setEmailBody = new Map();
      setEmailBody["trackingType"] = "login";
      setEmailBody["value"] = data["user_id"].toString();
      AnalyticsManager.webengageTrackUser(setEmailBody);
    }
  }
}
