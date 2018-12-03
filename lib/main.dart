import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:playfantasy/routes.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/landingpage/landingpage.dart';

String apkUrl;
String cookie;
Widget _homePage;
String channelId = "9";
bool bIsForceUpdate = false;
bool bUpdateAvailable = false;
bool bAskToChooseLanguage = false;
String fcmSubscribeId = 'channelId_' + channelId + '_news'+'_stage';
//String fcmSubscribeId = 'channelId_' + channelId + '_news'+'_prod';

Map<String, dynamic> initData = {};
const apiBaseUrl = "https://stg.playfantasy.com";
const websocketUrl = "wss://lobby-stg.playfantasy.com/path?pid=";
String analyticsUrl = "https://stg-analytics.playfantasy.com/click/track";

setWSCookie() async {
  Request req = Request("POST", Uri.parse(apiBaseUrl + ApiUtil.GET_COOKIE_URL));
  req.body = json.encode({});
  return HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      SharedPrefHelper().saveWSCookieToStorage(json.decode(res.body)["cookie"]);
    }
  });
}

getInitData() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  Request req = Request("POST", Uri.parse(apiBaseUrl + ApiUtil.INIT_DATA));
  req.body = json.encode({
    "version": double.parse(packageInfo.version),
    "channelId": channelId,
  });
  await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      initData = json.decode(res.body);
      apkUrl = initData["updateUrl"];
      bUpdateAvailable = initData["update"];
      bIsForceUpdate = initData["isForceUpdate"];
      analyticsUrl = initData["analyticsURL"];
      SharedPrefHelper()
          .saveToSharedPref(ApiUtil.KEY_INIT_DATA, json.encode(initData));
    }
  });
}

updateStringTable() async {
  String table;
  await SharedPrefHelper().getLanguageTable().then((value) {
    table = value;
  });

  bAskToChooseLanguage = table == null ? true : false;
  Map<String, dynamic> stringTable = json.decode(table == null ? "{}" : table);

  Request req =
      Request("POST", Uri.parse(apiBaseUrl + ApiUtil.UPDATE_LANGUAGE_TABLE));
  req.body = json.encode({
    "version": stringTable["version"],
    "language": stringTable["language"] == null ? 1 : stringTable["language"],
  });
  await HttpManager(http.Client()).sendRequest(req).then((http.Response res) {
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      Map<String, dynamic> response = json.decode(res.body);
      if (response["update"]) {
        strings.set(
          language: response["language"],
          table: response["table"],
        );
        SharedPrefHelper().saveLanguageTable(
            version: response["version"],
            lang: response["language"],
            table: response["table"]);
      } else {
        strings.set(
          language: stringTable["language"],
          table: stringTable["table"],
        );
      }
    } else {
      strings.set(
        language: stringTable["language"],
        table: stringTable["table"],
      );
    }
  });
}

preloadData() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  bool _result = await AuthCheck().checkStatus(apiBaseUrl);
  if (_result) {
    await setWSCookie();
  }

  await getInitData();
  await updateStringTable();

  if (_result) {
    _homePage = Lobby(
      appUrl: apkUrl,
      isForceUpdate: bIsForceUpdate,
      updateAvailable: bUpdateAvailable,
    );
  } else {
    _homePage = LandingPage(
      appUrl: apkUrl,
      isForceUpdate: bIsForceUpdate,
      languages: initData["languages"],
      updateAvailable: bUpdateAvailable,
      chooseLanguage: false,
    );
  }

  BaseUrl().setApiUrl(apiBaseUrl);
  BaseUrl().setWebSocketUrl(websocketUrl);
}

initFirebaseConfiguration() async {
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  await _firebaseMessaging.getToken().then((token) {
    print("Token is .........................");
    print(token);
    SharedPrefHelper.internal()
        .saveToSharedPref(ApiUtil.SHARED_PREFERENCE_FIREBASE_TOKEN, token);
  });

  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) {
      print('on message $message');
    },
    onResume: (Map<String, dynamic> message) {
      print('on resume $message');
    },
    onLaunch: (Map<String, dynamic> message) {
      print('on launch $message');
    },
  );
  _firebaseMessaging.subscribeToTopic('news');
  _firebaseMessaging.subscribeToTopic(fcmSubscribeId);
}

///
/// Bootstraping APP.
///
void main() async {
  await preloadData();
  await initFirebaseConfiguration();

  AnalyticsManager()
      .init(url: analyticsUrl, duration: initData["analyticsSendInterval"]);

  HttpManager.channelId = channelId;
  var configuredApp = AppConfig(
    channelId: channelId,
    apiBaseUrl: apiBaseUrl,
    appName: 'Smart11',
    websocketUrl: websocketUrl,
    child: MaterialApp(
      home: _homePage,
      routes: FantasyRoutes().getRoutes(),
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 207, 34, 40),
        accentColor: Color.fromARGB(255, 197, 34, 40),
        primaryColorDark: Color.fromARGB(255, 227, 34, 40),
        primaryColorLight: Color.fromARGB(255, 197, 34, 40),
      ),
    ),
  );

  runApp(configuredApp);
}
