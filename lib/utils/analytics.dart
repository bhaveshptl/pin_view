import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';
import 'package:playfantasy/modal/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:cipher2/cipher2.dart';

class AnalyticsManager {
  String source;
  String journey;
  static int userId;
  static String _url;
  static Timer _timer;
  static Visit _visit;
  static int _duration;
  static int _timeout;
  static bool isEnabled;
  String analyticsCookie;
  static DateTime _lastBatchUploadTime;
  static List<Event> analyticsEvents = [];
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static const webengage_platform =
      const MethodChannel('com.algorin.pf.webengage');
  static const utils_platform = const MethodChannel('com.algorin.pf.utils');

  AnalyticsManager._internal();
  static final AnalyticsManager _analyticsManager =
      AnalyticsManager._internal();
  factory AnalyticsManager() => _analyticsManager;

  init({
    String url,
    int timeout = 30,
    int duration = 5,
    String channelId,
  }) async {
    _url = url;
    _duration = duration;
    _timeout = timeout;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    AndroidDeviceInfo androidInfo;
    IosDeviceInfo iosDeviceInfo;
    if (!Platform.isIOS) {
      androidInfo = await deviceInfo.androidInfo;
    } else {
      iosDeviceInfo = await deviceInfo.iosInfo;
    }
    String firebasedeviceid;
    await SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN)
        .then((onValue) {
      firebasedeviceid = onValue;
    });

    String refCode = await SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_REFCODE_BRANCH);

    SharedPrefHelper.internal()
        .getFromSharedPref(ApiUtil.SHARED_PREFERENCE_INSTALLREFERRING_BRANCH);

    _visit = Visit(
      appVersion: double.parse(packageInfo.version.split(".")[0] +
          "." +
          packageInfo.version.split(".")[1]),
      channelId: int.parse(HttpManager.channelId),
      clientTimestamp: 0,
      creativeId: 0,
      deviceId: firebasedeviceid,
      domain: Uri.parse(BaseUrl().apiUrl).host,
      googleAddId: "",
      id: 0,
      manufacturer: Platform.isIOS ? "Apple" : androidInfo.manufacturer,
      model: Platform.isIOS ? iosDeviceInfo.model : androidInfo.model,
      networkOp: "",
      networkType: "",
      osName: Platform.isIOS ? iosDeviceInfo.systemName : androidInfo.host,
      osVersion: Platform.isIOS
          ? iosDeviceInfo.systemVersion
          : androidInfo.version.release,
      partnerId: 0,
      productId: 1,
      providerId: "",
      refCode: refCode,
      refURL: "",
      serial: Platform.isIOS
          ? iosDeviceInfo.identifierForVendor
          : androidInfo.androidId,
      sessionId: "",
      uid: 0,
      userId: userId,
      utmCampaign: "",
      utmContent: "",
      utmMedium: "",
      utmSource: "",
      utmTerm: "",
    );
  }

  statAnalytics() {
    if (isEnabled) {
      _timer = Timer(Duration(seconds: _duration), () async {
        if (_lastBatchUploadTime == null ||
            _lastBatchUploadTime.difference(DateTime.now()) >
                Duration(minutes: _timeout)) {
          final result = await uploadEventBatch();
        } else {
          uploadEventBatch();
        }
        AnalyticsManager().statAnalytics();
      });
    }
  }

  setUser(Map<String, dynamic> user) {
    userId = user["user_id"];
    if (_visit != null) {
      _visit.userId = user["user_id"];
    }
  }

  setContext(Map<String, dynamic> context) {
    _visit.utmCampaign = context["utm_Campaign"];
    _visit.utmContent = context["utm_Content"];
    _visit.utmMedium = context["utm_Medium"];
    _visit.utmSource = context["utm_Source"];
    _visit.utmTerm = context["utm_Term"];
  }

  Future<bool> uploadEventBatch() async {
    if (analyticsCookie == null || analyticsCookie == "") {
      await SharedPrefHelper.internal()
          .getFromSharedPref(ApiUtil.ANALYTICS_COOKIE)
          .then((onValue) {
        analyticsCookie = onValue;
      });
    }

    if (analyticsEvents.length > 0) {
      _visit.clientTimestamp = DateTime.now().millisecondsSinceEpoch;
      Map<String, dynamic> payload = {
        "events": analyticsEvents.getRange(0, analyticsEvents.length).toList(),
        "visit": _visit
      };
      analyticsEvents.removeRange(0, analyticsEvents.length);
      return http.Client()
          .post(
        _url,
        headers: {
          'cookie': analyticsCookie,
          'Content-type': 'application/json',
        },
        body: json.encode(payload),
      )
          .then((http.Response res) {
        if (res.statusCode >= 200 && res.statusCode <= 299) {
          analyticsCookie = res.headers["set-cookie"];
          SharedPrefHelper()
              .saveToSharedPref(ApiUtil.ANALYTICS_COOKIE, analyticsCookie);
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
    this.journey = journey;
  }

  setSource(String source) {
    this.source = source;
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

  static Future<String> trackEventsWithAttributes(
      Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result = await webengage_platform.invokeMethod(
          'trackEventsWithAttributes', data);
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

  static Future<String> webengageCustomAttributeTrackUser(
      Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result = await webengage_platform.invokeMethod(
          'webengageCustomAttributeTrackUser', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  static Future<String> webengageAddScreenData(
      Map<dynamic, dynamic> data) async {
    String result = "";
    try {
      result =
          await webengage_platform.invokeMethod('webengageAddScreenData', data);
    } catch (e) {
      print(e);
    }
    return "";
  }

  static  Future<String> dosha256Encoding(String dataString) async {
    String key = '9*x@xAg5aDFyVnl@';
    String iv = '8wruyqyi7@yrloc5';
    String encryptedString = await Cipher2.encryptAesCbc128Padding7(dataString, key, iv);
    return encryptedString;
  }

  static Future<String> deleteInternalStorageFile(String filename) async {
    String value;
    try {
      value = await utils_platform.invokeMethod(
          'deleteInternalStorageFile', filename);
    } catch (e) {}
    return value;
  }
}
