import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:playfantasy/routes.dart';
import 'package:playfantasy/appconfig.dart';
import 'package:playfantasy/lobby/lobby.dart';
import 'package:package_info/package_info.dart';
import 'package:playfantasy/utils/apiutil.dart';
import 'package:playfantasy/utils/analytics.dart';
import 'package:playfantasy/utils/authcheck.dart';
import 'package:playfantasy/utils/httpmanager.dart';
import 'package:playfantasy/utils/stringtable.dart';
import 'package:playfantasy/utils/sharedprefhelper.dart';
import 'package:playfantasy/landingpage/landingpage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/*
╔═══════════════════════════════════════════════════════════════════╗
║   ANY CHANGES IN "main.dart" WILL OVERRIDE WHILE BUILDING APK.    ║
║   MAKE SURE TO EDIT FOLLWING FILES.                               ║
║    - "resources/main_3.dart"                                      ║
║    - "resources/main_9.dart"                                      ║
║    - "resources/main_3_prod.dart"                                 ║
║    - "resources/main_9_prod.dart"                                 ║
╚═══════════════════════════════════════════════════════════════════╝
*/

String apkUrl;
String cookie;
Widget _homePage;
String channelId = "3";
List<dynamic> updateLogs;
bool bIsForceUpdate = false;
bool bUpdateAvailable = false;
bool bAskToChooseLanguage = false;
String fcmSubscribeId = 'channelId_' + channelId + '_news' + '_prod';

Map<String, dynamic> initData = {};
Map<String, dynamic> staticPageUrls;
const apiBaseUrl = "https://www.playfantasy.com";
const websocketUrl = "wss://lobby-www.playfantasy.com/path?pid=";
String analyticsUrl = "https://analytics.playfantasy.com/click/track";

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
      updateLogs = initData["updateLogs"];
      bUpdateAvailable = initData["update"];
      analyticsUrl = initData["analyticsURL"];
      bIsForceUpdate = initData["isForceUpdate"];
      staticPageUrls = initData["staticPageUrls"];
      AnalyticsManager.isEnabled = initData["analyticsEnabled"];
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
      logs: updateLogs,
      isForceUpdate: bIsForceUpdate,
      updateAvailable: bUpdateAvailable,
    );
  } else {
    _homePage = LandingPage(
      appUrl: apkUrl,
      logs: updateLogs,
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

ThemeData _buildLightTheme() {
  const Color primaryColor = Color(0xFF0E4F87);
  const Color secondaryColor = Color(0xFF244f83);
  final ColorScheme colorScheme = const ColorScheme.light().copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
  );
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    colorScheme: colorScheme,
    primaryColor: primaryColor,
    primaryColorDark: secondaryColor,
    buttonColor: primaryColor,
    indicatorColor: Colors.white,
    splashColor: Colors.white24,
    splashFactory: InkRipple.splashFactory,
    accentColor: secondaryColor,
    canvasColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    backgroundColor: Colors.white,
    errorColor: const Color(0xFFB00020),
  );
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
    appName: 'PlayFantasy',
    channelId: channelId,
    showBackground: false,
    apiBaseUrl: apiBaseUrl,
    websocketUrl: websocketUrl,
    staticPageUrls: staticPageUrls,
    contestShareUrl: initData["contestShareUrl"],
    child: MaterialApp(
      home: _homePage,
      routes: FantasyRoutes().getRoutes(),
      theme: _buildLightTheme(),
    ),
  );

  runApp(configuredApp);
}
