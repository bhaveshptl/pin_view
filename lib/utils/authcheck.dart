import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/utils/analytics.dart';

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
            Map<String,dynamic> refreshdata=json.decode(res.body)["user"];

            print("###########Refresh UserData#############");
            print(json.decode(res.body)["user"]);

        return true;
      } else {
        return false;
      }
    });
  }

  setWebEngageKeys(Map<String,dynamic> data){
    if(data["email_id"] != null){
      Map<dynamic, dynamic> setEmailBody = new Map();
      setEmailBody["trackType"] = "setEmail";
      setEmailBody["value"] = AnalyticsManager.dosha256Encoding(data["email_id"]);
      AnalyticsManager.webengageTrackEvent(setEmailBody);
    }

    if(data["mobile"] != null){
      Map<dynamic, dynamic> setEmailBody = new Map();
      setEmailBody["trackType"] = "setPhoneNumber";
      setEmailBody["value"] = AnalyticsManager.dosha256Encoding("+91"+data["mobile"]);
      AnalyticsManager.webengageTrackEvent(setEmailBody);
    }

    if(data["first_name"] != null){
      Map<dynamic, dynamic> setEmailBody = new Map();
      setEmailBody["trackType"] = "setFirstName";
      setEmailBody["value"] = AnalyticsManager.dosha256Encoding(data["first_name"]);
      AnalyticsManager.webengageTrackEvent(setEmailBody);
    }

    if(data["setLastName"] != null){
      Map<dynamic, dynamic> setEmailBody = new Map();
      setEmailBody["trackType"] = "setLastName";
      setEmailBody["value"] = AnalyticsManager.dosha256Encoding(data["last_name"]);
      AnalyticsManager.webengageTrackEvent(setEmailBody);
    }


  }
}
