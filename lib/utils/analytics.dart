import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';
import 'package:playfantasy/modal/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:flutter/services.dart';


class AnalyticsManager {
  String source;
  String journey;
  static String _url;
  static Timer _timer;
  static Visit _visit;
  static int _duration;
  static bool isEnabled;
  static DateTime _lastBatchUploadTime;
  static List<Event> analyticsEvents = [];
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');

  AnalyticsManager._internal();
  factory AnalyticsManager() => AnalyticsManager._internal();

  init({String url, int duration = 5, String channelId}) async {
    _url = url;
    _duration = duration;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    String firebasedeviceid;
    await SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN)
        .then((onValue) {
      firebasedeviceid = onValue;
    });

    _visit = Visit(
      appVersion: double.parse(packageInfo.version),
      channelId: int.parse(HttpManager.channelId),
      clientTimestamp: 0,
      creativeId: 0,
      deviceId: firebasedeviceid,
      domain: Uri.parse(BaseUrl().apiUrl).host,
      googleAddId: "string",
      id: 0,
      manufacturer: androidInfo.manufacturer,
      model: androidInfo.model,
      networkOp: "",
      networkType: "string",
      osName: androidInfo.host,
      osVersion: androidInfo.version.release,
      partnerId: 0,
      productId: 1,
      providerId: "string",
      refCode: "string",
      refURL: "string",
      serial: androidInfo.androidId,
      sessionId: "",
      uid: 0,
      userId: 0,
      utmCampaign: "string",
      utmContent: "string",
      utmMedium: "string",
      utmSource: "string",
      utmTerm: "string",
    );
  }

  statAnalytics() {
    if (isEnabled) {
      _timer = Timer(Duration(seconds: _duration), () async {
        if (_lastBatchUploadTime == null ||
            _lastBatchUploadTime.difference(DateTime.now()) >
                Duration(minutes: 30)) {
          final result = await uploadEventBatch();
        } else {
          uploadEventBatch();
        }
        AnalyticsManager().statAnalytics();
      });
    }
  }

  Future<bool> uploadEventBatch() async {
    String cookie;
    await SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.ANALYTICS_COOKIE)
        .then((onValue) {
      cookie = onValue;
    });

    if (analyticsEvents.length > 0) {
      _visit.clientTimestamp = DateTime.now().millisecondsSinceEpoch;
      Map<String, dynamic> payload = {
        "events": analyticsEvents,
        "visit": _visit
      };
      analyticsEvents = [];
      return http.Client()
          .post(
        _url,
        headers: {
          'cookie': cookie,
          'Content-type': 'application/json',
        },
        body: json.encode(payload),
      )
          .then((http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          SharedPrefHelper().saveToSharedPref(
              ApiUtil.ANALYTICS_COOKIE, res.headers["set-cookie"]);
          _lastBatchUploadTime = DateTime.now();
          return true;
        }
        return false;
      });
    } else {
      return Future.value(false);
    }
  }

  addEvent(Event event) {
    event.source = source;
    event.journey = journey;
    event.userId = _visit.userId;
    event.appVersion = _visit.appVersion;
    event.clientTimestamp = DateTime.now().millisecondsSinceEpoch;
    analyticsEvents.add(event);
    if (_timer == null) {
      statAnalytics();
    }
  }

  setJourney(String journey) {
    journey = journey;
  }

  setSource(String source) {
    source = source;
  }

  static Future<String> webengageTrackEvent(Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result =
          await webengage_platform.invokeMethod('webengageTrackEvent', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  static Future<String> trackEventsWithAttributes(Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result =
          await webengage_platform.invokeMethod('trackEventsWithAttributes', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  static Future<String> webengageTrackUser(Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result =
          await webengage_platform.invokeMethod('webengageTrackUser', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  static Future<String> webengageCustomAttributeTrackUser(Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result =
          await webengage_platform.invokeMethod('webengageCustomAttributeTrackUser', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  static Future<String> webengageAddScreenData(Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result =
          await webengage_platform.invokeMethod('webengageAddScreenData', data);
    } catch (e) {
      print(e);
    }
    return "";
  }


}
